-- Milestone - Booking Based Ebooks (Class Booking Modul)

-- 1. Tambahkan kolom booking_id ke public.library_ebooks
alter table public.library_ebooks
  add column if not exists booking_id uuid references public.bookings(id) on delete cascade;

-- 2. Hapus policy select yang lama untuk library_ebooks
drop policy if exists "Ebooks are viewable by everyone" on public.library_ebooks;

-- 3. Buat policy select baru yang menyaring privat vs publik secara dinamis
create policy "Ebooks are viewable if public or linked to user's booking"
  on public.library_ebooks for select
  using (
    booking_id is null
    or exists (
      select 1 from public.bookings b 
      where b.id = booking_id 
        and (b.student_uid = auth.uid() or b.tutor_uid = auth.uid())
    )
  );
