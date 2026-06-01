-- Supabase Migration: Secondary Audit Hardening
-- Addressing Payment Bypass Prevention and Cron Expire Cleanup Compatibility

-- =========================================================================
-- TEMUAN 1: Pengerasan Logika Transisi Status 'paid' (Cegah Direct Update Klien)
-- =========================================================================

-- 1. Redefinisi fungsi handle_secure_webhook_payment untuk mengatur session parameter transaksi lokal
create or replace function public.handle_secure_webhook_payment(
  p_booking_id uuid,
  p_payment_method text,
  p_signature_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expected_signature text;
  booking_row public.bookings%rowtype;
  tx_row public.transactions%rowtype;
  now_utc timestamptz := now();
begin
  -- Secure validation: Verify signature using a mock server secret key (simulating Midtrans signature logic)
  v_expected_signature := md5(p_booking_id::text || 'EDUCONNECT_SECRET_SERVER_KEY');
  
  if p_signature_key <> v_expected_signature then
    return jsonb_build_object(
      'success', false,
      'message', 'Tanda tangan transaksi (Signature Key) tidak valid. Akses ditolak.'
    );
  end if;

  -- Locate the targeted booking
  select *
  into booking_row
  from public.bookings b
  where b.id = p_booking_id;

  if not found then
    return jsonb_build_object(
      'success', false,
      'message', 'Booking tidak ditemukan.'
    );
  end if;

  -- Ensure booking is in a state ready to accept payment
  if booking_row.status <> 'awaiting_payment' then
    return jsonb_build_object(
      'success', false,
      'message', 'Booking tidak sedang menunggu pembayaran.'
    );
  end if;

  -- Find the active pending billing transaction
  select *
  into tx_row
  from public.transactions t
  where t.booking_id = p_booking_id
    and t.payment_status = 'pending'
  order by t.cycle_number asc
  limit 1;

  if not found then
    return jsonb_build_object(
      'success', false,
      'message', 'Tidak ada tagihan aktif yang perlu dibayar.'
    );
  end if;

  -- Set transaction-local session parameter to allow the transition to 'paid'
  perform set_config('app.payment_webhook_active', 'true', true);

  -- Update booking state to paid
  update public.bookings
  set status = 'paid',
      paid_at = now_utc,
      total_amount = coalesce(tx_row.amount, 0),
      updated_at = now_utc
  where id = p_booking_id;

  -- Update transaction state to paid with a proper gateway transaction reference prefix
  update public.transactions
  set payment_method = p_payment_method,
      payment_status = 'paid',
      payment_ref = 'PAY-' || upper(p_payment_method) || '-' || extract(epoch from clock_timestamp())::bigint,
      paid_at = now_utc,
      updated_at = now_utc
  where id = tx_row.id;

  -- Return successful state with all details required to generate learning sessions (analogous to the old RPC payload)
  return jsonb_build_object(
    'success', true,
    'message', 'Pembayaran berhasil diverifikasi secara aman via Webhook Server-to-Server.',
    'student_uid', booking_row.student_uid,
    'tutor_uid', booking_row.tutor_uid,
    'duration_minutes', booking_row.duration_minutes,
    'package_start_date', booking_row.package_start_date,
    'package_end_date', booking_row.package_end_date,
    'weekly_schedule', booking_row.weekly_schedule
  );
end;
$$;

grant execute on function public.handle_secure_webhook_payment(uuid, text, text) to authenticated;


-- 2. Redefinisi trigger check status booking untuk melarang transisi langsung ke status 'paid'
create or replace function public.enforce_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  -- Server/admin contexts can still perform maintenance updates.
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah booking ini.';
  end if;

  -- Prevent identity fields from being modified by end users.
  if new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.subject <> old.subject
    or new.session_start <> old.session_start
    or new.session_end <> old.session_end
    or new.package_months <> old.package_months
    or new.sessions_per_week <> old.sessions_per_week
    or new.weekly_schedule <> old.weekly_schedule
    or new.package_start_date <> old.package_start_date
    or new.package_end_date <> old.package_end_date then
    raise exception 'Field inti booking tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status = 'pending' and new.status in ('awaiting_payment', 'rejected') then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa memproses permintaan booking.';
    end if;
    return new;
  end if;

  if old.status = 'awaiting_payment' and new.status = 'paid' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa membayar booking.';
    end if;
    if new.paid_at is null then
      raise exception 'paid_at wajib diisi saat status paid.';
    end if;

    -- HARDENING: Pastikan pembaruan dilakukan melalui sistem pembayaran resmi (parameter transaksi lokal diset)
    if current_setting('app.payment_webhook_active', true) is distinct from 'true' then
      raise exception 'Pembayaran langsung dilarang. Silakan bayar melalui portal resmi.';
    end if;

    return new;
  end if;

  if old.status = 'paid' and new.status = 'completed' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menyelesaikan booking.';
    end if;
    return new;
  end if;

  if old.status in ('pending', 'awaiting_payment', 'paid') and new.status = 'cancelled' then
    return new;
  end if;

  raise exception 'Transisi status booking tidak diizinkan: % -> %', old.status, new.status;
end;
$$;


-- =========================================================================
-- TEMUAN 2: Perbaikan expire_stale_bookings untuk Mendukung System Role / Cron
-- =========================================================================

create or replace function public.expire_stale_bookings(
  p_booking_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  affected_count integer := 0;
  expired_booking_ids uuid[] := '{}';
begin
  -- Hapus pemeriksaan awal "if actor_uid is null then return 0; end if;" agar pg_cron/system dapat memproses pembersihan.

  with expired_rows as (
    update public.bookings
    set status = 'cancelled',
        updated_at = now(),
        expires_at = null
    where status in ('pending', 'awaiting_payment')
      and expires_at is not null
      and expires_at <= now()
      -- Perbolehkan eksekusi jika dikerjakan oleh system (actor_uid is null) ATAU pemilik booking bersangkutan
      and (actor_uid is null or student_uid = actor_uid or tutor_uid = actor_uid)
      and (p_booking_id is null or id = p_booking_id)
    returning id
  )
  select coalesce(array_agg(id), '{}'), count(*)
  into expired_booking_ids, affected_count
  from expired_rows;

  if cardinality(expired_booking_ids) > 0 then
    update public.transactions
    set payment_status = 'failed',
        updated_at = now()
    where booking_id = any(expired_booking_ids)
      and payment_status = 'pending';
  end if;

  return affected_count;
end;
$$;

revoke all on function public.expire_stale_bookings(uuid) from public;
grant execute on function public.expire_stale_bookings(uuid) to authenticated;
