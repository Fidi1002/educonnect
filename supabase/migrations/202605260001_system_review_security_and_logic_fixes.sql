-- Supabase Migration: System Review Security & Logic Fixes
-- Addressing Celah 1, Celah 2, Celah 3, Celah 4, and Celah 5

-- =========================================================================
-- CELAH 5: Tampilkan nama asli student & tutor di table bookings (Realtime Streams)
-- =========================================================================

-- 1. Tambahkan kolom student_name dan tutor_name ke tabel bookings
alter table public.bookings
  add column if not exists student_name text,
  add column if not exists tutor_name text;

-- 2. Buat fungsi trigger untuk mengisi nama secara otomatis dari users & tutors
create or replace function public.populate_booking_names()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_name text;
  v_tutor_name text;
begin
  -- Cari nama student di public.users
  select display_name into v_student_name
  from public.users
  where uid = new.student_uid;

  -- Cari nama tutor di public.users atau tutors
  select display_name into v_tutor_name
  from public.users
  where uid = new.tutor_uid;

  new.student_name := coalesce(v_student_name, 'Murid');
  new.tutor_name := coalesce(v_tutor_name, 'Tutor');

  return new;
end;
$$;

-- 3. Pasang trigger BEFORE INSERT pada bookings
drop trigger if exists trg_bookings_populate_names on public.bookings;
create trigger trg_bookings_populate_names
  before insert on public.bookings
  for each row
  execute function public.populate_booking_names();

-- 4. Sinkronisasi nama untuk data bookings yang sudah ada (existing data)
alter table public.bookings disable trigger user;

update public.bookings b
set student_name = coalesce((select display_name from public.users u where u.uid = b.student_uid), 'Murid'),
    tutor_name = coalesce((select display_name from public.users u where u.uid = b.tutor_uid), 'Tutor')
where student_name is null or tutor_name is null;

alter table public.bookings enable trigger user;


-- =========================================================================
-- CELAH 1: Secure Server-side payment simulation RPC
-- =========================================================================

create or replace function public.simulate_secure_payment(
  p_booking_id uuid,
  p_payment_method text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_signature text;
begin
  -- Hitung signature secara aman di server, menggunakan kunci rahasia yang sama
  v_signature := md5(p_booking_id::text || 'EDUCONNECT_SECRET_SERVER_KEY');
  
  -- Panggil fungsi webhook utama secara aman dengan signature yang valid
  return public.handle_secure_webhook_payment(
    p_booking_id,
    p_payment_method,
    v_signature
  );
end;
$$;

grant execute on function public.simulate_secure_payment(uuid, text) to authenticated;


-- =========================================================================
-- CELAH 3 & 4: Pengerasan RLS payout_requests & Pemrosesan Otomatis Saldo Dompet
-- =========================================================================

-- 1. Cabut kebijakan UPDATE bebas yang lama
drop policy if exists payout_requests_update_own on public.payout_requests;

-- 2. Terapkan kebijakan baru: Hanya izinkan update jika status 'pending' dan tidak mengubah kolom 'status'
create policy payout_requests_update_own
on public.payout_requests
for update
using (
  auth.uid() = tutor_uid 
  and status = 'pending'
)
with check (
  auth.uid() = tutor_uid 
  and status = 'pending' -- Mencegah bypass status langsung ke approved/completed
);

-- 3. Buat trigger otomatis untuk pemrosesan saldo wallet berdasarkan status payout
create or replace function public.handle_payout_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Pastikan perubahan status valid dan tidak redundant
  if old.status = new.status then
    return new;
  end if;

  -- A. Payout Berhasil Diselesaikan (Completed)
  if new.status = 'completed' then
    update public.tutor_wallets
    set pending_balance = pending_balance - old.amount
    where tutor_uid = old.tutor_uid;

    -- Catat riwayat transaksi debit sukses
    insert into public.wallet_transactions (tutor_uid, amount, type, description, reference_type, reference_id)
    values (old.tutor_uid, old.amount, 'debit', 'Pencairan dana selesai ditransfer ke rekening', 'payout', old.id::text);
    
    new.processed_at := now();

  -- B. Payout Ditolak (Rejected)
  elsif new.status = 'rejected' then
    update public.tutor_wallets
    set pending_balance = pending_balance - old.amount,
        available_balance = available_balance + old.amount -- Kembalikan ke saldo aktif tutor
    where tutor_uid = old.tutor_uid;

    -- Catat riwayat transaksi pengembalian dana
    insert into public.wallet_transactions (tutor_uid, amount, type, description, reference_type, reference_id)
    values (old.tutor_uid, old.amount, 'credit', 'Pengembalian dana (Payout ditolak: ' || coalesce(new.rejection_reason, '-') || ')', 'payout', old.id::text);
    
    new.processed_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists trg_payout_status_change on public.payout_requests;
create trigger trg_payout_status_change
after update of status
on public.payout_requests
for each row
execute function public.handle_payout_status_change();


-- =========================================================================
-- CELAH 2: Pengerasan RLS Storage Bucket ebooks (Folder Isolation + Private)
-- =========================================================================

-- 1. Ubah status bucket ebooks menjadi Private
update storage.buckets 
set public = false 
where id = 'ebooks';

-- 2. Hapus kebijakan RLS storage ebooks yang lama
drop policy if exists "Ebook files are publicly accessible" on storage.objects;
drop policy if exists "Tutors can upload ebook files" on storage.objects;
drop policy if exists "Tutors can update their ebook files" on storage.objects;
drop policy if exists "Tutors can delete their ebook files" on storage.objects;

-- 3. Kebijakan Select: Pengguna harus terautentikasi (Validasi download dilakukan via signed URL)
create policy "Ebooks read authorization"
  on storage.objects for select
  using (
    bucket_id = 'ebooks'
    and auth.uid() is not null
  );

-- 4. Kebijakan Insert: Hanya tutor yang bisa mengunggah ke foldernya sendiri (foldername = auth.uid())
create policy "Tutors can upload to their own folder"
  on storage.objects for insert
  with check (
    bucket_id = 'ebooks'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
    and exists (
      select 1 from public.users u
      where u.uid = auth.uid() and u.role = 'tutor'
    )
  );

-- 5. Kebijakan Update: Hanya pemilik folder yang bisa memodifikasi
create policy "Tutors can update their own folder objects"
  on storage.objects for update
  using (
    bucket_id = 'ebooks'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 6. Kebijakan Delete: Hanya pemilik folder yang bisa menghapus
create policy "Tutors can delete their own folder objects"
  on storage.objects for delete
  using (
    bucket_id = 'ebooks'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );
