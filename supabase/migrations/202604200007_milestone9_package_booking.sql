-- Milestone week 9 - Package booking (1/2/3/6 months, 2x/week)
alter table public.bookings
  add column if not exists package_months integer not null default 1,
  add column if not exists sessions_per_week integer not null default 2,
  add column if not exists weekly_schedule jsonb not null default '[]'::jsonb,
  add column if not exists package_start_date date,
  add column if not exists package_end_date date;

update public.bookings
set package_start_date = coalesce(package_start_date, session_start::date),
    package_end_date = coalesce(package_end_date, (session_start::date + interval '1 month')::date),
    sessions_per_week = 2
where package_start_date is null
   or package_end_date is null
   or sessions_per_week is null;

alter table public.bookings
  alter column package_start_date set not null,
  alter column package_end_date set not null;

alter table public.bookings
  drop constraint if exists bookings_package_months_check;
alter table public.bookings
  add constraint bookings_package_months_check check (package_months in (1, 2, 3, 6));

alter table public.bookings
  drop constraint if exists bookings_sessions_per_week_check;
alter table public.bookings
  add constraint bookings_sessions_per_week_check check (sessions_per_week = 2);

create index if not exists idx_bookings_tutor_package_range
  on public.bookings (tutor_uid, package_start_date, package_end_date);

create or replace function public.overlap_time(
  a_start time,
  a_end time,
  b_start time,
  b_end time
)
returns boolean
language sql
immutable
as $$
  select a_start < b_end and a_end > b_start;
$$;

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
        and b.status in ('awaiting_payment', 'paid')
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

  if new.status in ('awaiting_payment', 'paid') then
    select count(distinct b.student_uid)
    into active_students
    from public.bookings b
    where b.tutor_uid = new.tutor_uid
      and b.id <> new.id
      and b.status in ('awaiting_payment', 'paid')
      and daterange(b.package_start_date, b.package_end_date, '[]')
          && daterange(new.package_start_date, new.package_end_date, '[]');

    if active_students >= 2 then
      raise exception 'Tutor sudah mencapai kapasitas maksimal 2 murid aktif.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_bookings_validate_package on public.bookings;
create trigger trg_bookings_validate_package
before insert or update on public.bookings
for each row
execute function public.validate_package_booking();
