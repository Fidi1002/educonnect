-- Milestone week 12.1 - Atomic booking creation (booking + cycles + sessions)
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
  session_row jsonb;
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

  if coalesce(jsonb_typeof(p_sessions), '') <> 'array'
     or coalesce(jsonb_array_length(p_sessions), 0) = 0 then
    raise exception 'Payload sesi tidak valid.';
  end if;

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

  for session_row in
    select value from jsonb_array_elements(p_sessions)
  loop
    insert into public.booking_sessions (
      booking_id,
      student_uid,
      tutor_uid,
      session_start,
      session_end,
      status
    )
    values (
      booking_id,
      p_student_uid,
      p_tutor_uid,
      (session_row->>'session_start')::timestamptz,
      (session_row->>'session_end')::timestamptz,
      coalesce(session_row->>'status', 'scheduled')
    );
  end loop;

  return booking_id;
end;
$$;

revoke all on function public.create_booking_with_cycles_and_sessions(
  uuid, uuid, text, timestamptz, integer, timestamptz, text, numeric,
  integer, integer, jsonb, date, date, jsonb, jsonb
) from public;

grant execute on function public.create_booking_with_cycles_and_sessions(
  uuid, uuid, text, timestamptz, integer, timestamptz, text, numeric,
  integer, integer, jsonb, date, date, jsonb, jsonb
) to authenticated;
