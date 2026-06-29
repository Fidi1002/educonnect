-- Supabase Migration: Security & Logic Patches
-- Fixes for Pricing Bypass, Unilateral Dispute Resolution, and Notification Spamming

-- =========================================================================
-- 1. FIX PRICING BYPASS
-- =========================================================================

-- Helper function to count sessions in range based on weekly schedule
create or replace function public.count_sessions_in_range(
  p_start_date date,
  p_end_date date,
  p_weekly_schedule jsonb
)
returns integer
language plpgsql
stable
as $$
declare
  v_curr date := p_start_date;
  v_count integer := 0;
  v_slot jsonb;
  v_wday integer;
begin
  while v_curr <= p_end_date loop
    -- Extract ISO weekday (1 = Monday, 7 = Sunday)
    v_wday := extract(isodow from v_curr)::integer;
    for v_slot in select * from jsonb_array_elements(p_weekly_schedule) loop
      if (v_slot->>'weekday')::integer = v_wday then
        v_count := v_count + 1;
      end if;
    end loop;
    v_curr := v_curr + 1;
  end loop;
  return v_count;
end;
$$;

-- Redefine create_booking_with_cycles_and_sessions to validate total amount and transaction amounts
create or replace function public.create_booking_with_cycles_and_sessions(
  p_student_uid uuid,
  p_tutor_uid uuid,
  p_subject text,
  p_session_start timestamptz,
  p_duration_minutes integer,
  p_session_end timestamptz,
  p_message text,
  p_total_amount numeric,
  p_package_months integer,
  p_sessions_per_week integer,
  p_weekly_schedule jsonb,
  p_package_start_date date,
  p_package_end_date date,
  p_transactions jsonb,
  p_sessions jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  booking_id uuid;
  tx jsonb;
  v_price_per_hour numeric;
  v_session_price numeric;
  v_expected_total_first_month numeric;
  v_expected_tx_amount numeric;
  v_cycle_start date;
  v_cycle_end date;
  v_sessions_count integer;
  v_cycle_number integer;
  v_tx_amount numeric;
begin
  if actor_uid is null then
    raise exception 'User belum login.';
  end if;

  if actor_uid <> p_student_uid then
    raise exception 'Hanya murid pemilik booking yang boleh membuat booking.';
  end if;

  if p_tutor_uid is null or not exists (
    select 1 from public.tutors t where t.uid = p_tutor_uid
  ) then
    raise exception 'Tutor tidak ditemukan.';
  end if;

  if coalesce(jsonb_typeof(p_transactions), '') <> 'array'
     or coalesce(jsonb_array_length(p_transactions), 0) = 0 then
    raise exception 'Payload transaksi tidak valid.';
  end if;

  -- Retrieve tutor price
  select price_per_hour into v_price_per_hour
  from public.tutors
  where uid = p_tutor_uid;

  if v_price_per_hour is null or v_price_per_hour <= 0 then
    raise exception 'Tarif tutor tidak valid atau belum diatur.';
  end if;

  v_session_price := (v_price_per_hour * p_duration_minutes) / 60.0;

  -- Validate Month 1 / First Cycle expected price
  v_cycle_start := p_package_start_date;
  v_cycle_end := (p_package_start_date + interval '1 month')::date - 1;
  v_sessions_count := public.count_sessions_in_range(v_cycle_start, v_cycle_end, p_weekly_schedule);
  v_expected_total_first_month := round(v_session_price * v_sessions_count);

  if abs(p_total_amount - v_expected_total_first_month) > 1 then
    raise exception 'Jumlah total pembayaran tidak valid. Terdeteksi: %, Seharusnya: %', p_total_amount, v_expected_total_first_month;
  end if;

  -- Validate transaction elements array
  for tx in
    select value from jsonb_array_elements(p_transactions)
  loop
    v_cycle_number := coalesce((tx->>'cycle_number')::integer, 1);
    v_tx_amount := coalesce((tx->>'amount')::numeric, 0);

    v_cycle_start := p_package_start_date + ((v_cycle_number - 1) || ' month')::interval;
    v_cycle_end := (p_package_start_date + (v_cycle_number || ' month')::interval)::date - 1;
    v_sessions_count := public.count_sessions_in_range(v_cycle_start, v_cycle_end, p_weekly_schedule);
    v_expected_tx_amount := round(v_session_price * v_sessions_count);

    if abs(v_tx_amount - v_expected_tx_amount) > 1 then
      raise exception 'Jumlah cicilan transaksi untuk siklus % tidak valid. Terdeteksi: %, Seharusnya: %', v_cycle_number, v_tx_amount, v_expected_tx_amount;
    end if;
  end loop;

  insert into public.bookings (
    student_uid,
    tutor_uid,
    subject,
    session_start,
    duration_minutes,
    session_end,
    status,
    message,
    total_amount,
    package_months,
    sessions_per_week,
    weekly_schedule,
    package_start_date,
    package_end_date
  )
  values (
    p_student_uid,
    p_tutor_uid,
    trim(coalesce(p_subject, '')),
    p_session_start,
    p_duration_minutes,
    p_session_end,
    'pending',
    trim(coalesce(p_message, '')),
    coalesce(p_total_amount, 0),
    p_package_months,
    p_sessions_per_week,
    coalesce(p_weekly_schedule, '[]'::jsonb),
    p_package_start_date,
    p_package_end_date
  )
  returning id into booking_id;

  for tx in
    select value from jsonb_array_elements(p_transactions)
  loop
    insert into public.transactions (
      booking_id,
      student_uid,
      tutor_uid,
      amount,
      payment_method,
      payment_status,
      cycle_number,
      due_at
    )
    values (
      booking_id,
      p_student_uid,
      p_tutor_uid,
      coalesce((tx->>'amount')::numeric, 0),
      coalesce(tx->>'payment_method', 'dummy'),
      coalesce(tx->>'payment_status', 'pending'),
      coalesce((tx->>'cycle_number')::integer, 1),
      (tx->>'due_at')::timestamptz
    );
  end loop;

  return booking_id;
end;
$$;

-- =========================================================================
-- 2. FIX UNILATERAL DISPUTE RESOLUTION
-- =========================================================================

-- Redefine enforce_booking_session_status_transition to check that only student or admin can resolve dispute
create or replace function public.enforce_booking_session_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah sesi ini.';
  end if;

  if new.booking_id <> old.booking_id
    or new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.session_start <> old.session_start
    or new.session_end <> old.session_end then
    raise exception 'Field inti sesi tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'in_progress' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa memulai sesi.';
    end if;
    return new;
  end if;

  if old.status in ('scheduled', 'in_progress') and new.status = 'done_pending_confirmation' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai sesi selesai.';
    end if;
    if new.tutor_marked_done_at is null then
      raise exception 'tutor_marked_done_at wajib diisi.';
    end if;
    return new;
  end if;

  if old.status = 'done_pending_confirmation' and new.status = 'confirmed' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa konfirmasi sesi.';
    end if;
    return new;
  end if;

  if old.status = 'done_pending_confirmation' and new.status = 'disputed_pending' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa dispute sesi.';
    end if;
    return new;
  end if;

  -- HARDENING: Only student or admin can transition disputed_pending to disputed_resolved
  if old.status = 'disputed_pending' and new.status = 'disputed_resolved' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid atau admin yang dapat menutup status dispute sesi.';
    end if;
    return new;
  end if;

  if old.status in ('scheduled', 'in_progress') and new.status in ('cancelled_early', 'cancelled_late') then
    if new.cancelled_by_role not in ('student', 'tutor') then
      raise exception 'cancelled_by_role wajib valid.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'rescheduled' then
    if new.rescheduled_to_session_id is null then
      raise exception 'rescheduled_to_session_id wajib diisi.';
    end if;
    return new;
  end if;
  
  if old.status in ('scheduled', 'in_progress') and new.status = 'student_no_show' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai murid tidak hadir.';
    end if;
    return new;
  end if;
  
  if old.status in ('scheduled', 'in_progress') and new.status = 'tutor_no_show' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa menandai tutor tidak hadir.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status sesi tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

-- =========================================================================
-- 3. FIX NOTIFICATION SPAMMING
-- =========================================================================

-- Redefine INSERT RLS policy on app_notifications to prevent arbitrary spamming
drop policy if exists app_notifications_insert_actor on public.app_notifications;

create policy app_notifications_insert_actor
on public.app_notifications
for insert
with check (
  auth.uid() = actor_uid
  and (
    -- Self notification
    actor_uid = user_uid
    -- Or there is an active booking between the actor and the target user
    or exists (
      select 1 from public.bookings b
      where (b.student_uid = actor_uid and b.tutor_uid = user_uid)
         or (b.tutor_uid = actor_uid and b.student_uid = user_uid)
    )
  )
);
