-- Milestone 15 - Booking hold/expiry and session activation after payment

alter table public.bookings
  add column if not exists expires_at timestamptz;

create index if not exists idx_bookings_status_expires_at
  on public.bookings (status, expires_at asc);

update public.bookings
set expires_at = case
  when status = 'pending' then now() + interval '6 hours'
  when status = 'awaiting_payment' then now() + interval '12 hours'
  else null
end
where expires_at is null
  and status in ('pending', 'awaiting_payment');

update public.bookings
set expires_at = null
where status not in ('pending', 'awaiting_payment')
  and expires_at is not null;

create or replace function public.sync_booking_expiry()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'pending' then
    if tg_op = 'INSERT' then
      new.expires_at := now() + interval '6 hours';
    elsif old.status <> 'pending' or new.expires_at is null then
      new.expires_at := now() + interval '6 hours';
    end if;
  elsif new.status = 'awaiting_payment' then
    if tg_op = 'INSERT' then
      new.expires_at := now() + interval '12 hours';
    elsif old.status <> 'awaiting_payment' or new.expires_at is null then
      new.expires_at := now() + interval '12 hours';
    end if;
  else
    new.expires_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bookings_sync_expiry on public.bookings;
create trigger trg_bookings_sync_expiry
before insert or update on public.bookings
for each row
execute function public.sync_booking_expiry();

create or replace function public.validate_package_booking()
returns trigger
language plpgsql
as $$
declare
  slot jsonb;
  slot_count integer := 0;
  slot_weekday integer;
  slot_start time;
  slot_end time;
  existing_slot jsonb;
  active_students integer;
begin
  if new.package_months not in (1, 2, 3, 6) then
    raise exception 'Paket hanya boleh 1, 2, 3, atau 6 bulan.';
  end if;

  if new.sessions_per_week != 2 then
    raise exception 'Frekuensi kelas wajib 2x per minggu.';
  end if;

  if jsonb_typeof(new.weekly_schedule) <> 'array' then
    raise exception 'weekly_schedule wajib array.';
  end if;

  slot_count := jsonb_array_length(new.weekly_schedule);
  if slot_count <> 2 then
    raise exception 'weekly_schedule wajib berisi tepat 2 slot.';
  end if;

  if new.package_end_date < new.package_start_date then
    raise exception 'Tanggal akhir paket tidak valid.';
  end if;

  for slot in
    select value from jsonb_array_elements(new.weekly_schedule)
  loop
    slot_weekday := (slot->>'weekday')::integer;
    slot_start := (slot->>'start_time')::time;
    slot_end := (slot->>'end_time')::time;

    if slot_weekday < 1 or slot_weekday > 7 then
      raise exception 'Weekday slot harus antara 1 dan 7.';
    end if;

    if slot_end <= slot_start then
      raise exception 'Jam selesai slot harus lebih besar dari jam mulai.';
    end if;

    if not exists (
      select 1
      from public.tutor_availability ta
      where ta.tutor_uid = new.tutor_uid
        and ta.is_active = true
        and ta.weekday = slot_weekday
        and ta.start_time <= slot_start
        and ta.end_time >= slot_end
    ) then
      raise exception 'Slot tidak termasuk jadwal ketersediaan tutor.';
    end if;
  end loop;

  for slot in
    select value from jsonb_array_elements(new.weekly_schedule)
  loop
    slot_weekday := (slot->>'weekday')::integer;
    slot_start := (slot->>'start_time')::time;
    slot_end := (slot->>'end_time')::time;

    for existing_slot in
      select value
      from public.bookings b,
      lateral jsonb_array_elements(b.weekly_schedule) value
      where b.tutor_uid = new.tutor_uid
        and b.id <> new.id
        and (
          b.status in ('awaiting_payment', 'paid')
          or (
            b.status = 'pending'
            and b.expires_at is not null
            and b.expires_at > now()
          )
        )
        and daterange(b.package_start_date, b.package_end_date, '[]')
            && daterange(new.package_start_date, new.package_end_date, '[]')
    loop
      if slot_weekday = (existing_slot->>'weekday')::integer and public.overlap_time(
        slot_start,
        slot_end,
        (existing_slot->>'start_time')::time,
        (existing_slot->>'end_time')::time
      ) then
        raise exception 'Slot bentrok dengan jadwal murid aktif lain.';
      end if;
    end loop;
  end loop;

  if new.status in ('pending', 'awaiting_payment', 'paid') then
    select count(distinct b.student_uid)
    into active_students
    from public.bookings b
    where b.tutor_uid = new.tutor_uid
      and b.id <> new.id
      and (
        b.status in ('awaiting_payment', 'paid')
        or (
          b.status = 'pending'
          and b.expires_at is not null
          and b.expires_at > now()
        )
      )
      and daterange(b.package_start_date, b.package_end_date, '[]')
          && daterange(new.package_start_date, new.package_end_date, '[]');

    if active_students >= 2 then
      raise exception 'Tutor sudah mencapai kapasitas maksimal 2 murid aktif.';
    end if;
  end if;

  return new;
end;
$$;

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
  if actor_uid is null then
    return 0;
  end if;

  with expired_rows as (
    update public.bookings
    set status = 'cancelled',
        updated_at = now(),
        expires_at = null
    where status in ('pending', 'awaiting_payment')
      and expires_at is not null
      and expires_at <= now()
      and (student_uid = actor_uid or tutor_uid = actor_uid)
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

revoke all on function public.create_booking_with_cycles_and_sessions(
  uuid, uuid, text, timestamptz, integer, timestamptz, text, numeric,
  integer, integer, jsonb, date, date, jsonb, jsonb
) from public;

grant execute on function public.create_booking_with_cycles_and_sessions(
  uuid, uuid, text, timestamptz, integer, timestamptz, text, numeric,
  integer, integer, jsonb, date, date, jsonb, jsonb
) to authenticated;

create or replace function public.complete_dummy_booking_payment(
  p_booking_id uuid
)
returns table(
  student_uid uuid,
  tutor_uid uuid,
  duration_minutes integer,
  package_start_date date,
  package_end_date date,
  weekly_schedule jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  booking_row public.bookings%rowtype;
  tx_row public.transactions%rowtype;
  now_utc timestamptz := now();
begin
  if actor_uid is null then
    raise exception 'User belum login.';
  end if;

  perform public.expire_stale_bookings(p_booking_id);

  select *
  into booking_row
  from public.bookings
  where id = p_booking_id;

  if not found then
    raise exception 'Booking tidak ditemukan.';
  end if;

  if booking_row.student_uid <> actor_uid then
    raise exception 'Booking ini bukan milik kamu.';
  end if;

  if booking_row.status <> 'awaiting_payment' then
    raise exception 'Booking belum siap dibayar atau sudah diproses.';
  end if;

  select *
  into tx_row
  from public.transactions t
  where t.booking_id = p_booking_id
    and t.student_uid = actor_uid
    and t.payment_status = 'pending'
  order by t.cycle_number asc
  limit 1;

  if not found then
    raise exception 'Tidak ada tagihan aktif yang perlu dibayar.';
  end if;

  update public.bookings
  set status = 'paid',
      paid_at = now_utc,
      total_amount = coalesce(tx_row.amount, 0),
      updated_at = now_utc
  where id = p_booking_id;

  update public.transactions
  set payment_method = 'dummy',
      payment_status = 'paid',
      payment_ref = 'DUMMY-' || extract(epoch from clock_timestamp())::bigint,
      paid_at = now_utc,
      updated_at = now_utc
  where id = tx_row.id;

  return query
  select
    booking_row.student_uid,
    booking_row.tutor_uid,
    booking_row.duration_minutes,
    booking_row.package_start_date,
    booking_row.package_end_date,
    booking_row.weekly_schedule;
end;
$$;

revoke all on function public.complete_dummy_booking_payment(uuid) from public;
grant execute on function public.complete_dummy_booking_payment(uuid) to authenticated;

create unique index if not exists idx_booking_sessions_unique_booking_start
  on public.booking_sessions (booking_id, session_start);
