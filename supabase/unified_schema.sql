create extension if not exists postgis;
create extension if not exists pgcrypto;

create table if not exists public.users (
  uid uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  photo_url text not null default '',
  role text not null default 'unknown' check (role in ('unknown', 'student', 'tutor')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tutors (
  uid uuid primary key references public.users(uid) on delete cascade,
  display_name text not null default '',
  photo_url text not null default '',
  bio text not null default '',
  subjects text[] not null default '{}',
  price_per_hour numeric not null default 0,
  experience_years integer not null default 0,
  experience_description text not null default '',
  location_label text not null default '',
  latitude double precision,
  longitude double precision,
  geohash text not null default '',
  rating double precision not null default 0,
  total_reviews integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  bank_name text,
  bank_account_number text,
  languages text[] not null default '{Bahasa Indonesia}',
  introduction_video_url text,
  location geography(point, 4326) generated always as (
    case
      when latitude is null or longitude is null then null
      else st_setsrid(st_makepoint(longitude, latitude), 4326)::geography
    end
  ) stored
);

create index if not exists idx_tutors_active_rating on public.tutors (is_active, rating desc);
create index if not exists idx_tutors_active_price on public.tutors (is_active, price_per_hour asc);
create index if not exists idx_tutors_location on public.tutors using gist (location);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_touch_updated_at on public.users;
create trigger trg_users_touch_updated_at
before update on public.users
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_tutors_touch_updated_at on public.tutors;
create trigger trg_tutors_touch_updated_at
before update on public.tutors
for each row
execute function public.touch_updated_at();

create or replace function public.get_nearby_tutors(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 250
)
returns table (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  distance_km double precision
)
language sql
stable
as $$
  select
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000 as distance_km
  from public.tutors t
  where t.is_active = true
    and t.location is not null
    and st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  order by distance_km asc
  limit greatest(coalesce(p_limit, 250), 1);
$$;

alter table public.users enable row level security;
alter table public.tutors enable row level security;

drop policy if exists users_select_own on public.users;
create policy users_select_own
on public.users
for select
using (auth.uid() = uid);

drop policy if exists users_insert_own on public.users;
create policy users_insert_own
on public.users
for insert
with check (auth.uid() = uid);

drop policy if exists users_update_own on public.users;
create policy users_update_own
on public.users
for update
using (auth.uid() = uid)
with check (auth.uid() = uid);

drop policy if exists tutors_select_authenticated on public.tutors;
create policy tutors_select_authenticated
on public.tutors
for select
using (auth.role() = 'authenticated' and (is_active = true or auth.uid() = uid));

drop policy if exists tutors_insert_own on public.tutors;
create policy tutors_insert_own
on public.tutors
for insert
with check (auth.uid() = uid);

drop policy if exists tutors_update_own on public.tutors;
create policy tutors_update_own
on public.tutors
for update
using (auth.uid() = uid)
with check (auth.uid() = uid);

insert into storage.buckets (id, name, public)
values ('tutor-photos', 'tutor-photos', true)
on conflict (id) do nothing;

drop policy if exists tutor_photos_public_read on storage.objects;
create policy tutor_photos_public_read
on storage.objects
for select
using (bucket_id = 'tutor-photos');

drop policy if exists tutor_photos_insert_own on storage.objects;
create policy tutor_photos_insert_own
on storage.objects
for insert
with check (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_photos_update_own on storage.objects;
create policy tutor_photos_update_own
on storage.objects
for update
using (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_photos_delete_own on storage.objects;
create policy tutor_photos_delete_own
on storage.objects
for delete
using (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);
-- Optional data migration for legacy tutor rows
-- 1) clear impossible coordinate values
update public.tutors
set latitude = null,
    longitude = null,
    geohash = '',
    is_active = false
where latitude is not null
  and longitude is not null
  and (
    latitude < -90
    or latitude > 90
    or longitude < -180
    or longitude > 180
  );

-- 2) deactivate tutor profiles that still have no valid coordinate
update public.tutors
set is_active = false
where latitude is null or longitude is null;
-- Milestone week 5 - Booking sessions
create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  student_uid uuid not null references public.users(uid) on delete cascade,
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  subject text not null,
  session_start timestamptz not null,
  duration_minutes integer not null check (duration_minutes between 30 and 240),
  session_end timestamptz not null,
  status text not null default 'pending' check (
    status in ('pending', 'accepted', 'rejected', 'completed', 'cancelled')
  ),
  message text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_time_valid check (session_end > session_start)
);

create index if not exists idx_bookings_student_time
  on public.bookings (student_uid, session_start desc);
create index if not exists idx_bookings_tutor_time
  on public.bookings (tutor_uid, session_start desc);
create index if not exists idx_bookings_tutor_status_time
  on public.bookings (tutor_uid, status, session_start asc);

-- Ensure trigger function exists from previous migrations.
drop trigger if exists trg_bookings_touch_updated_at on public.bookings;
create trigger trg_bookings_touch_updated_at
before update on public.bookings
for each row
execute function public.touch_updated_at();

alter table public.bookings enable row level security;

drop policy if exists bookings_select_owner on public.bookings;
create policy bookings_select_owner
on public.bookings
for select
using (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists bookings_insert_student on public.bookings;
create policy bookings_insert_student
on public.bookings
for insert
with check (
  auth.uid() = student_uid
  and exists (
    select 1 from public.users u
    where u.uid = auth.uid() and u.role = 'student'
  )
);

drop policy if exists bookings_update_owner on public.bookings;
create policy bookings_update_owner
on public.bookings
for update
using (auth.uid() = student_uid or auth.uid() = tutor_uid)
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);
-- Milestone week 6 - Payment schema and status flow
alter table public.bookings
  add column if not exists total_amount numeric not null default 0,
  add column if not exists paid_at timestamptz;

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check check (
    status in (
      'pending',
      'accepted',
      'awaiting_payment',
      'paid',
      'rejected',
      'completed',
      'cancelled'
    )
  );

update public.bookings
set status = 'awaiting_payment'
where status = 'accepted';

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check check (
    status in (
      'pending',
      'awaiting_payment',
      'paid',
      'rejected',
      'completed',
      'cancelled'
    )
  );

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  student_uid uuid not null references public.users(uid) on delete cascade,
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null default 0,
  payment_method text not null default 'dummy',
  payment_status text not null default 'pending' check (
    payment_status in ('pending', 'paid', 'failed', 'refunded')
  ),
  payment_ref text not null default '',
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_student_created
  on public.transactions (student_uid, created_at desc);
create index if not exists idx_transactions_tutor_created
  on public.transactions (tutor_uid, created_at desc);
create index if not exists idx_transactions_status
  on public.transactions (payment_status, created_at desc);

drop trigger if exists trg_transactions_touch_updated_at on public.transactions;
create trigger trg_transactions_touch_updated_at
before update on public.transactions
for each row
execute function public.touch_updated_at();

alter table public.transactions enable row level security;

drop policy if exists transactions_select_owner on public.transactions;
create policy transactions_select_owner
on public.transactions
for select
using (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists transactions_insert_student_or_tutor on public.transactions;
create policy transactions_insert_student_or_tutor
on public.transactions
for insert
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists transactions_update_student_or_tutor on public.transactions;
create policy transactions_update_student_or_tutor
on public.transactions
for update
using (auth.uid() = student_uid or auth.uid() = tutor_uid)
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);
-- Milestone week 7 - Chat and realtime notifications
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_uid uuid not null references public.users(uid) on delete cascade,
  receiver_uid uuid not null references public.users(uid) on delete cascade,
  body text not null check (char_length(trim(body)) > 0),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists idx_messages_booking_created
  on public.messages (booking_id, created_at asc);
create index if not exists idx_messages_receiver_unread
  on public.messages (receiver_uid, read_at, created_at desc);

alter table public.messages enable row level security;

drop policy if exists messages_select_participants on public.messages;
create policy messages_select_participants
on public.messages
for select
using (auth.uid() = sender_uid or auth.uid() = receiver_uid);

drop policy if exists messages_insert_sender on public.messages;
create policy messages_insert_sender
on public.messages
for insert
with check (
  auth.uid() = sender_uid
  and auth.uid() <> receiver_uid
  and exists (
    select 1
    from public.bookings b
    where b.id = booking_id
      and (auth.uid() = b.student_uid or auth.uid() = b.tutor_uid)
      and (receiver_uid = b.student_uid or receiver_uid = b.tutor_uid)
  )
);

drop policy if exists messages_update_receiver_read on public.messages;
create policy messages_update_receiver_read
on public.messages
for update
using (auth.uid() = receiver_uid)
with check (auth.uid() = receiver_uid);
-- Milestone week 8 - Tutor availability and smart scheduling
create table if not exists public.tutor_availability (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tutor_availability_time_valid check (end_time > start_time)
);

create index if not exists idx_tutor_availability_tutor_weekday
  on public.tutor_availability (tutor_uid, weekday, is_active);

drop trigger if exists trg_tutor_availability_touch_updated_at on public.tutor_availability;
create trigger trg_tutor_availability_touch_updated_at
before update on public.tutor_availability
for each row
execute function public.touch_updated_at();

alter table public.tutor_availability enable row level security;

drop policy if exists tutor_availability_select_all_auth on public.tutor_availability;
create policy tutor_availability_select_all_auth
on public.tutor_availability
for select
using (auth.role() = 'authenticated');

drop policy if exists tutor_availability_insert_own on public.tutor_availability;
create policy tutor_availability_insert_own
on public.tutor_availability
for insert
with check (auth.uid() = tutor_uid);

drop policy if exists tutor_availability_update_own on public.tutor_availability;
create policy tutor_availability_update_own
on public.tutor_availability
for update
using (auth.uid() = tutor_uid)
with check (auth.uid() = tutor_uid);

drop policy if exists tutor_availability_delete_own on public.tutor_availability;
create policy tutor_availability_delete_own
on public.tutor_availability
for delete
using (auth.uid() = tutor_uid);
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
-- Milestone week 9 - Monthly payment cycles
alter table public.transactions
  add column if not exists cycle_number integer not null default 1,
  add column if not exists due_at timestamptz;

alter table public.transactions
  drop constraint if exists transactions_booking_id_key;

create unique index if not exists idx_transactions_booking_cycle_unique
  on public.transactions (booking_id, cycle_number);

create index if not exists idx_transactions_booking_due
  on public.transactions (booking_id, due_at asc);
-- Milestone week 10 - Session confirmation and rating basis
create table if not exists public.booking_sessions (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  student_uid uuid not null references public.users(uid) on delete cascade,
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  session_start timestamptz not null,
  session_end timestamptz not null,
  status text not null default 'scheduled' check (
    status in (
      'scheduled',
      'done_pending_confirmation',
      'confirmed',
      'disputed',
      'cancelled_by_student',
      'cancelled_by_tutor',
      'student_no_show',
      'tutor_no_show'
    )
  ),
  tutor_marked_done_at timestamptz,
  student_confirmed_at timestamptz,
  student_rating integer check (student_rating between 1 and 5),
  student_review text not null default '',
  topic_notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint booking_session_time_valid check (session_end > session_start)
);

create index if not exists idx_booking_sessions_booking_time
  on public.booking_sessions (booking_id, session_start asc);
create index if not exists idx_booking_sessions_tutor_status
  on public.booking_sessions (tutor_uid, status, session_start asc);
create index if not exists idx_booking_sessions_student_status
  on public.booking_sessions (student_uid, status, session_start asc);

drop trigger if exists trg_booking_sessions_touch_updated_at on public.booking_sessions;
create trigger trg_booking_sessions_touch_updated_at
before update on public.booking_sessions
for each row
execute function public.touch_updated_at();

alter table public.booking_sessions enable row level security;

drop policy if exists booking_sessions_select_owner on public.booking_sessions;
create policy booking_sessions_select_owner
on public.booking_sessions
for select
using (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists booking_sessions_insert_owner on public.booking_sessions;
create policy booking_sessions_insert_owner
on public.booking_sessions
for insert
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists booking_sessions_update_owner on public.booking_sessions;
create policy booking_sessions_update_owner
on public.booking_sessions
for update
using (auth.uid() = student_uid or auth.uid() = tutor_uid)
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);
-- Milestone week 10 - Tutor consistency score columns
alter table public.tutors
  add column if not exists consistency_score numeric not null default 0,
  add column if not exists attendance_rate numeric not null default 0,
  add column if not exists on_time_rate numeric not null default 0,
  add column if not exists cancellation_rate numeric not null default 0;
-- Milestone week 11 - Session reschedule/cancel workflow
alter table public.booking_sessions
  drop constraint if exists booking_sessions_status_check;

alter table public.booking_sessions
  add constraint booking_sessions_status_check check (
    status in (
      'scheduled',
      'done_pending_confirmation',
      'confirmed',
      'disputed',
      'cancelled_by_student',
      'cancelled_by_tutor',
      'cancelled_early',
      'cancelled_late',
      'rescheduled',
      'student_no_show',
      'tutor_no_show'
    )
  );

alter table public.booking_sessions
  add column if not exists cancelled_by_role text check (cancelled_by_role in ('student', 'tutor')),
  add column if not exists rescheduled_from_session_id uuid references public.booking_sessions(id) on delete set null,
  add column if not exists rescheduled_to_session_id uuid references public.booking_sessions(id) on delete set null;

create table if not exists public.session_change_requests (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.booking_sessions(id) on delete cascade,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  requester_uid uuid not null references public.users(uid) on delete cascade,
  requester_role text not null check (requester_role in ('student', 'tutor')),
  target_uid uuid not null references public.users(uid) on delete cascade,
  request_type text not null check (request_type in ('reschedule', 'cancel')),
  reason text not null default '',
  proposed_start timestamptz,
  proposed_end timestamptz,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  reviewed_by_uid uuid references public.users(uid) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_session_change_requests_booking
  on public.session_change_requests (booking_id, created_at desc);
create index if not exists idx_session_change_requests_session
  on public.session_change_requests (session_id, status, created_at desc);
create index if not exists idx_session_change_requests_target
  on public.session_change_requests (target_uid, status, created_at desc);

drop trigger if exists trg_session_change_requests_touch_updated_at on public.session_change_requests;
create trigger trg_session_change_requests_touch_updated_at
before update on public.session_change_requests
for each row
execute function public.touch_updated_at();

alter table public.session_change_requests enable row level security;

drop policy if exists session_change_requests_select_owner on public.session_change_requests;
create policy session_change_requests_select_owner
on public.session_change_requests
for select
using (auth.uid() = requester_uid or auth.uid() = target_uid);

drop policy if exists session_change_requests_insert_owner on public.session_change_requests;
create policy session_change_requests_insert_owner
on public.session_change_requests
for insert
with check (auth.uid() = requester_uid);

drop policy if exists session_change_requests_update_participants on public.session_change_requests;
create policy session_change_requests_update_participants
on public.session_change_requests
for update
using (auth.uid() = requester_uid or auth.uid() = target_uid)
with check (auth.uid() = requester_uid or auth.uid() = target_uid);
-- Milestone week 11 - In-app notifications
create table if not exists public.app_notifications (
  id uuid primary key default gen_random_uuid(),
  user_uid uuid not null references public.users(uid) on delete cascade,
  actor_uid uuid not null references public.users(uid) on delete cascade,
  category text not null default 'general',
  title text not null,
  body text not null default '',
  target_type text not null default 'session_change',
  target_id text not null default '',
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_app_notifications_user_created
  on public.app_notifications (user_uid, created_at desc);
create index if not exists idx_app_notifications_user_unread
  on public.app_notifications (user_uid, is_read, created_at desc);

drop trigger if exists trg_app_notifications_touch_updated_at on public.app_notifications;
create trigger trg_app_notifications_touch_updated_at
before update on public.app_notifications
for each row
execute function public.touch_updated_at();

alter table public.app_notifications enable row level security;

drop policy if exists app_notifications_select_owner on public.app_notifications;
create policy app_notifications_select_owner
on public.app_notifications
for select
using (auth.uid() = user_uid);

drop policy if exists app_notifications_insert_actor on public.app_notifications;
create policy app_notifications_insert_actor
on public.app_notifications
for insert
with check (auth.uid() = actor_uid);

drop policy if exists app_notifications_update_owner on public.app_notifications;
create policy app_notifications_update_owner
on public.app_notifications
for update
using (auth.uid() = user_uid)
with check (auth.uid() = user_uid);
-- Milestone week 12 - Harden booking/payment/session state transitions

-- 1) Guard booking status transitions at database layer.
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

drop trigger if exists trg_bookings_enforce_status_transition on public.bookings;
create trigger trg_bookings_enforce_status_transition
before update on public.bookings
for each row
execute function public.enforce_booking_status_transition();

-- 2) Guard transaction/payment transitions.
create or replace function public.enforce_transaction_status_transition()
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
    raise exception 'Tidak berhak mengubah transaksi ini.';
  end if;

  if new.booking_id <> old.booking_id
    or new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.amount <> old.amount
    or new.cycle_number <> old.cycle_number
    or coalesce(new.due_at, 'epoch'::timestamptz) <> coalesce(old.due_at, 'epoch'::timestamptz) then
    raise exception 'Field inti transaksi tidak boleh diubah.';
  end if;

  if new.payment_status = old.payment_status then
    return new;
  end if;

  if old.payment_status = 'pending' and new.payment_status in ('paid', 'failed') then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa memproses pembayaran.';
    end if;
    if new.payment_status = 'paid' and (new.paid_at is null or coalesce(new.payment_ref, '') = '') then
      raise exception 'paid_at dan payment_ref wajib saat transaksi paid.';
    end if;
    return new;
  end if;

  if old.payment_status = 'paid' and new.payment_status = 'refunded' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai refund.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status transaksi tidak diizinkan: % -> %', old.payment_status, new.payment_status;
end;
$$;

drop trigger if exists trg_transactions_enforce_status_transition on public.transactions;
create trigger trg_transactions_enforce_status_transition
before update on public.transactions
for each row
execute function public.enforce_transaction_status_transition();

-- 3) Guard booking session transitions.
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

  if old.status = 'scheduled' and new.status = 'done_pending_confirmation' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai sesi selesai.';
    end if;
    if new.tutor_marked_done_at is null then
      raise exception 'tutor_marked_done_at wajib diisi.';
    end if;
    return new;
  end if;

  if old.status = 'done_pending_confirmation' and new.status in ('confirmed', 'disputed') then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa konfirmasi/dispute sesi.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status in ('cancelled_early', 'cancelled_late') then
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

  raise exception 'Transisi status sesi tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

drop trigger if exists trg_booking_sessions_enforce_status_transition on public.booking_sessions;
create trigger trg_booking_sessions_enforce_status_transition
before update on public.booking_sessions
for each row
execute function public.enforce_booking_session_status_transition();

-- 4) Validate session change request creation and transitions.
create or replace function public.validate_session_change_request_insert()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  session_row record;
begin
  if actor_uid is not null and actor_uid <> new.requester_uid then
    raise exception 'Requester tidak sesuai auth user.';
  end if;

  select bs.booking_id, bs.student_uid, bs.tutor_uid, bs.status
  into session_row
  from public.booking_sessions bs
  where bs.id = new.session_id;

  if not found then
    raise exception 'Sesi tidak ditemukan.';
  end if;

  if session_row.booking_id <> new.booking_id then
    raise exception 'booking_id request tidak sesuai sesi.';
  end if;

  if session_row.status <> 'scheduled' then
    raise exception 'Request hanya boleh untuk sesi scheduled.';
  end if;

  if new.requester_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.target_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.requester_uid = new.target_uid then
    raise exception 'Requester/target tidak valid untuk sesi ini.';
  end if;

  if new.requester_role = 'student' and new.requester_uid <> session_row.student_uid then
    raise exception 'requester_role student tidak cocok.';
  end if;

  if new.requester_role = 'tutor' and new.requester_uid <> session_row.tutor_uid then
    raise exception 'requester_role tutor tidak cocok.';
  end if;

  if new.request_type = 'reschedule' then
    if new.proposed_start is null or new.proposed_end is null or new.proposed_end <= new.proposed_start then
      raise exception 'Waktu reschedule tidak valid.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_session_change_requests_validate_insert on public.session_change_requests;
create trigger trg_session_change_requests_validate_insert
before insert on public.session_change_requests
for each row
execute function public.validate_session_change_request_insert();

create or replace function public.enforce_session_change_request_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.requester_uid and actor_uid <> old.target_uid then
    raise exception 'Tidak berhak mengubah request ini.';
  end if;

  if new.session_id <> old.session_id
    or new.booking_id <> old.booking_id
    or new.requester_uid <> old.requester_uid
    or new.target_uid <> old.target_uid
    or new.request_type <> old.request_type
    or coalesce(new.proposed_start, 'epoch'::timestamptz) <> coalesce(old.proposed_start, 'epoch'::timestamptz)
    or coalesce(new.proposed_end, 'epoch'::timestamptz) <> coalesce(old.proposed_end, 'epoch'::timestamptz) then
    raise exception 'Field inti request tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status <> 'pending' then
    raise exception 'Hanya request pending yang dapat diubah.';
  end if;

  if new.status in ('approved', 'rejected') then
    if actor_uid <> old.target_uid then
      raise exception 'Hanya target request yang bisa approve/reject.';
    end if;
    if new.reviewed_by_uid is distinct from actor_uid or new.reviewed_at is null then
      raise exception 'reviewed_by_uid/reviewed_at tidak valid.';
    end if;
    return new;
  end if;

  if new.status = 'cancelled' then
    if actor_uid <> old.requester_uid then
      raise exception 'Hanya requester yang bisa cancel request.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status request tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

drop trigger if exists trg_session_change_requests_enforce_transition on public.session_change_requests;
create trigger trg_session_change_requests_enforce_transition
before update on public.session_change_requests
for each row
execute function public.enforce_session_change_request_transition();

-- 5) Prevent more than one pending change request per session.
create unique index if not exists idx_session_change_requests_one_pending_per_session
  on public.session_change_requests (session_id)
  where status = 'pending';
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
-- Milestone week 12.2 - Session change request expiry (24h SLA)
alter table public.session_change_requests
  add column if not exists expires_at timestamptz;

update public.session_change_requests
set expires_at = created_at + interval '24 hours'
where expires_at is null;

alter table public.session_change_requests
  alter column expires_at set default (now() + interval '24 hours');

alter table public.session_change_requests
  alter column expires_at set not null;

alter table public.session_change_requests
  drop constraint if exists session_change_requests_status_check;

alter table public.session_change_requests
  add constraint session_change_requests_status_check check (
    status in ('pending', 'approved', 'rejected', 'cancelled', 'expired')
  );

create index if not exists idx_session_change_requests_status_expiry
  on public.session_change_requests (status, expires_at asc);

create or replace function public.validate_session_change_request_insert()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  session_row record;
begin
  if actor_uid is not null and actor_uid <> new.requester_uid then
    raise exception 'Requester tidak sesuai auth user.';
  end if;

  select bs.booking_id, bs.student_uid, bs.tutor_uid, bs.status
  into session_row
  from public.booking_sessions bs
  where bs.id = new.session_id;

  if not found then
    raise exception 'Sesi tidak ditemukan.';
  end if;

  if session_row.booking_id <> new.booking_id then
    raise exception 'booking_id request tidak sesuai sesi.';
  end if;

  if session_row.status <> 'scheduled' then
    raise exception 'Request hanya boleh untuk sesi scheduled.';
  end if;

  if new.requester_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.target_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.requester_uid = new.target_uid then
    raise exception 'Requester/target tidak valid untuk sesi ini.';
  end if;

  if new.requester_role = 'student' and new.requester_uid <> session_row.student_uid then
    raise exception 'requester_role student tidak cocok.';
  end if;

  if new.requester_role = 'tutor' and new.requester_uid <> session_row.tutor_uid then
    raise exception 'requester_role tutor tidak cocok.';
  end if;

  if new.request_type = 'reschedule' then
    if new.proposed_start is null or new.proposed_end is null or new.proposed_end <= new.proposed_start then
      raise exception 'Waktu reschedule tidak valid.';
    end if;
  end if;

  if new.expires_at is null then
    new.expires_at := now() + interval '24 hours';
  end if;

  return new;
end;
$$;

create or replace function public.enforce_session_change_request_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.requester_uid and actor_uid <> old.target_uid then
    raise exception 'Tidak berhak mengubah request ini.';
  end if;

  if new.session_id <> old.session_id
    or new.booking_id <> old.booking_id
    or new.requester_uid <> old.requester_uid
    or new.target_uid <> old.target_uid
    or new.request_type <> old.request_type
    or coalesce(new.proposed_start, 'epoch'::timestamptz) <> coalesce(old.proposed_start, 'epoch'::timestamptz)
    or coalesce(new.proposed_end, 'epoch'::timestamptz) <> coalesce(old.proposed_end, 'epoch'::timestamptz)
    or new.expires_at <> old.expires_at then
    raise exception 'Field inti request tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status <> 'pending' then
    raise exception 'Hanya request pending yang dapat diubah.';
  end if;

  if old.expires_at <= now() and new.status <> 'expired' then
    raise exception 'Request sudah kedaluwarsa.';
  end if;

  if new.status in ('approved', 'rejected') then
    if actor_uid <> old.target_uid then
      raise exception 'Hanya target request yang bisa approve/reject.';
    end if;
    if new.reviewed_by_uid is distinct from actor_uid or new.reviewed_at is null then
      raise exception 'reviewed_by_uid/reviewed_at tidak valid.';
    end if;
    return new;
  end if;

  if new.status = 'cancelled' then
    if actor_uid <> old.requester_uid then
      raise exception 'Hanya requester yang bisa cancel request.';
    end if;
    return new;
  end if;

  if new.status = 'expired' then
    if old.expires_at > now() then
      raise exception 'Request belum melewati masa kedaluwarsa.';
    end if;
    if new.reviewed_by_uid is not null then
      raise exception 'Request expired tidak memiliki reviewer.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status request tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

create or replace function public.expire_stale_session_change_requests(
  p_booking_id uuid default null,
  p_session_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  affected_count integer := 0;
begin
  update public.session_change_requests scr
  set status = 'expired',
      reviewed_at = now(),
      updated_at = now()
  where scr.status = 'pending'
    and scr.expires_at <= now()
    and (p_booking_id is null or scr.booking_id = p_booking_id)
    and (p_session_id is null or scr.session_id = p_session_id)
    and (
      actor_uid is null
      or actor_uid = scr.requester_uid
      or actor_uid = scr.target_uid
    );

  get diagnostics affected_count = row_count;
  return affected_count;
end;
$$;

revoke all on function public.expire_stale_session_change_requests(uuid, uuid) from public;
grant execute on function public.expire_stale_session_change_requests(uuid, uuid) to authenticated;
-- Milestone week 12.3 - Dispute lifecycle refinement and fair consistency scoring
update public.booking_sessions
set status = 'disputed_pending'
where status = 'disputed';

alter table public.booking_sessions
  drop constraint if exists booking_sessions_status_check;

alter table public.booking_sessions
  add constraint booking_sessions_status_check check (
    status in (
      'scheduled',
      'done_pending_confirmation',
      'confirmed',
      'disputed_pending',
      'disputed_resolved',
      'cancelled_by_student',
      'cancelled_by_tutor',
      'cancelled_early',
      'cancelled_late',
      'rescheduled',
      'student_no_show',
      'tutor_no_show'
    )
  );

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

  if old.status = 'scheduled' and new.status = 'done_pending_confirmation' then
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

  if old.status = 'disputed_pending' and new.status = 'disputed_resolved' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menutup status dispute.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status in ('cancelled_early', 'cancelled_late') then
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

  raise exception 'Transisi status sesi tidak diizinkan: % -> %', old.status, new.status;
end;
$$;
-- Milestone week 12.4 - Auto in-app notifications for expired session-change requests
create or replace function public.expire_stale_session_change_requests(
  p_booking_id uuid default null,
  p_session_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  affected_count integer := 0;
  expired_row record;
begin
  for expired_row in
    update public.session_change_requests scr
    set status = 'expired',
        reviewed_at = now(),
        updated_at = now()
    where scr.status = 'pending'
      and scr.expires_at <= now()
      and (p_booking_id is null or scr.booking_id = p_booking_id)
      and (p_session_id is null or scr.session_id = p_session_id)
      and (
        actor_uid is null
        or actor_uid = scr.requester_uid
        or actor_uid = scr.target_uid
      )
    returning scr.id, scr.requester_uid, scr.target_uid, scr.session_id
  loop
    affected_count := affected_count + 1;

    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    )
    values (
      expired_row.requester_uid,
      expired_row.target_uid,
      'session_change',
      'Request Kedaluwarsa',
      'Permintaan perubahan sesi kedaluwarsa karena tidak direspons dalam 24 jam.',
      'booking_session',
      expired_row.session_id::text,
      false
    );

    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    )
    values (
      expired_row.target_uid,
      expired_row.requester_uid,
      'session_change',
      'Request Kedaluwarsa',
      'Permintaan perubahan sesi otomatis ditutup karena melewati batas respons.',
      'booking_session',
      expired_row.session_id::text,
      false
    );
  end loop;

  return affected_count;
end;
$$;
-- Milestone week 13 - Learning progress + material/homework history per session
create table if not exists public.session_learning_records (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  session_id uuid not null unique references public.booking_sessions(id) on delete cascade,
  student_uid uuid not null references public.users(uid) on delete cascade,
  tutor_uid uuid not null references public.users(uid) on delete cascade,
  material_summary text not null default '',
  material_notes text not null default '',
  homework_title text not null default '',
  homework_description text not null default '',
  homework_status text not null default 'none' check (
    homework_status in ('none', 'assigned', 'submitted', 'reviewed')
  ),
  student_submission text not null default '',
  homework_assigned_at timestamptz,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_session_learning_records_booking
  on public.session_learning_records (booking_id, created_at desc);
create index if not exists idx_session_learning_records_student
  on public.session_learning_records (student_uid, homework_status, updated_at desc);
create index if not exists idx_session_learning_records_tutor
  on public.session_learning_records (tutor_uid, homework_status, updated_at desc);

drop trigger if exists trg_session_learning_records_touch_updated_at on public.session_learning_records;
create trigger trg_session_learning_records_touch_updated_at
before update on public.session_learning_records
for each row
execute function public.touch_updated_at();

create or replace function public.enforce_session_learning_record_transition()
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
    raise exception 'Tidak berhak mengubah learning record ini.';
  end if;

  if new.booking_id <> old.booking_id
    or new.session_id <> old.session_id
    or new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid then
    raise exception 'Field inti learning record tidak boleh diubah.';
  end if;

  if actor_uid = old.student_uid then
    if new.material_summary <> old.material_summary
      or new.material_notes <> old.material_notes
      or new.homework_title <> old.homework_title
      or new.homework_description <> old.homework_description
      or new.homework_assigned_at is distinct from old.homework_assigned_at
      or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'Murid tidak bisa mengubah materi/assignment tutor.';
    end if;

    if not (old.homework_status = 'assigned' and new.homework_status = 'submitted') then
      raise exception 'Murid hanya bisa submit PR dari status assigned ke submitted.';
    end if;

    if coalesce(trim(new.student_submission), '') = '' then
      raise exception 'Isi jawaban PR terlebih dahulu.';
    end if;

    if new.submitted_at is null then
      new.submitted_at := now();
    end if;

    return new;
  end if;

  -- Tutor branch.
  if new.homework_status = old.homework_status and new.student_submission <> old.student_submission then
    raise exception 'Tutor tidak bisa mengubah jawaban PR murid.';
  end if;

  if new.homework_status = 'assigned' and old.homework_status in ('none', 'reviewed', 'submitted') then
    if coalesce(trim(new.homework_title), '') = '' then
      raise exception 'Judul PR wajib diisi saat assign homework.';
    end if;
    if new.homework_assigned_at is null then
      new.homework_assigned_at := now();
    end if;
    if old.homework_status <> 'submitted' then
      new.student_submission := '';
      new.submitted_at := null;
    end if;
    new.reviewed_at := null;
    return new;
  end if;

  if new.homework_status = 'reviewed' and old.homework_status = 'submitted' then
    if new.reviewed_at is null then
      new.reviewed_at := now();
    end if;
    return new;
  end if;

  if new.homework_status = 'none' then
    new.homework_title := '';
    new.homework_description := '';
    new.student_submission := '';
    new.homework_assigned_at := null;
    new.submitted_at := null;
    new.reviewed_at := null;
    return new;
  end if;

  if old.homework_status = new.homework_status then
    return new;
  end if;

  raise exception 'Transisi PR tidak diizinkan: % -> %', old.homework_status, new.homework_status;
end;
$$;

drop trigger if exists trg_session_learning_records_enforce_transition on public.session_learning_records;
create trigger trg_session_learning_records_enforce_transition
before update on public.session_learning_records
for each row
execute function public.enforce_session_learning_record_transition();

alter table public.session_learning_records enable row level security;

drop policy if exists session_learning_records_select_participants on public.session_learning_records;
create policy session_learning_records_select_participants
on public.session_learning_records
for select
using (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists session_learning_records_insert_tutor on public.session_learning_records;
create policy session_learning_records_insert_tutor
on public.session_learning_records
for insert
with check (auth.uid() = tutor_uid);

drop policy if exists session_learning_records_update_participants on public.session_learning_records;
create policy session_learning_records_update_participants
on public.session_learning_records
for update
using (auth.uid() = student_uid or auth.uid() = tutor_uid)
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);
-- Milestone week 13.1 - Smart reminders H-24 and H-2 + student attendance confirmation
alter table public.booking_sessions
  add column if not exists student_presence_confirmed_at timestamptz,
  add column if not exists reminder_h24_sent_at timestamptz,
  add column if not exists reminder_h2_sent_at timestamptz;

create index if not exists idx_booking_sessions_student_upcoming
  on public.booking_sessions (student_uid, session_start asc, status);

create or replace function public.process_student_session_reminders(
  p_student_uid uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  sent_count integer := 0;
  item record;
begin
  if actor_uid is not null and actor_uid <> p_student_uid then
    raise exception 'Tidak berhak memproses reminder user lain.';
  end if;

  for item in
    select bs.id, bs.tutor_uid, 'h24'::text as reminder_type
    from public.booking_sessions bs
    where bs.student_uid = p_student_uid
      and bs.status = 'scheduled'
      and bs.session_start > now()
      and bs.session_start <= now() + interval '24 hours'
      and bs.session_start > now() + interval '23 hours'
      and bs.reminder_h24_sent_at is null
    union all
    select bs.id, bs.tutor_uid, 'h2'::text as reminder_type
    from public.booking_sessions bs
    where bs.student_uid = p_student_uid
      and bs.status = 'scheduled'
      and bs.session_start > now()
      and bs.session_start <= now() + interval '2 hours'
      and bs.session_start > now() + interval '1 hour'
      and bs.reminder_h2_sent_at is null
  loop
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    ) values (
      p_student_uid,
      item.tutor_uid,
      'reminder',
      case when item.reminder_type = 'h24' then 'Reminder Kelas Besok' else 'Reminder Kelas 2 Jam Lagi' end,
      case when item.reminder_type = 'h24'
        then 'Sesi akan dimulai dalam 24 jam. Jangan lupa konfirmasi hadir.'
        else 'Sesi akan dimulai dalam 2 jam. Siapkan materi belajar ya.'
      end,
      'booking_session',
      item.id::text,
      false
    );

    if item.reminder_type = 'h24' then
      update public.booking_sessions
      set reminder_h24_sent_at = now(), updated_at = now()
      where id = item.id;
    else
      update public.booking_sessions
      set reminder_h2_sent_at = now(), updated_at = now()
      where id = item.id;
    end if;

    sent_count := sent_count + 1;
  end loop;

  return sent_count;
end;
$$;

revoke all on function public.process_student_session_reminders(uuid) from public;
grant execute on function public.process_student_session_reminders(uuid) to authenticated;
-- Milestone week 14 - Operational flow hardening for no-show and auto booking completion

create or replace function public.is_terminal_booking_session_status(
  p_status text
)
returns boolean
language sql
immutable
as $$
  select p_status in (
    'confirmed',
    'disputed_resolved',
    'cancelled_by_student',
    'cancelled_by_tutor',
    'cancelled_early',
    'cancelled_late',
    'rescheduled',
    'student_no_show',
    'tutor_no_show'
  );
$$;

create or replace function public.enforce_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  has_open_sessions boolean := false;
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah booking ini.';
  end if;

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
    return new;
  end if;

  if old.status = 'paid' and new.status = 'completed' then
    select exists (
      select 1
      from public.booking_sessions bs
      where bs.booking_id = old.id
        and not public.is_terminal_booking_session_status(bs.status)
    )
    into has_open_sessions;

    if has_open_sessions then
      raise exception 'Booking belum bisa selesai karena masih ada sesi aktif.';
    end if;
    return new;
  end if;

  if old.status in ('pending', 'awaiting_payment', 'paid') and new.status = 'cancelled' then
    return new;
  end if;

  raise exception 'Transisi status booking tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

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

  if old.status = 'scheduled' and new.status = 'done_pending_confirmation' then
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

  if old.status = 'disputed_pending' and new.status = 'disputed_resolved' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menutup status dispute.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'student_no_show' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai murid tidak hadir.';
    end if;
    if old.session_end > now() then
      raise exception 'Tunggu sesi berakhir sebelum menandai murid tidak hadir.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'tutor_no_show' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa menandai tutor tidak hadir.';
    end if;
    if old.session_end > now() then
      raise exception 'Tunggu sesi berakhir sebelum menandai tutor tidak hadir.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status in ('cancelled_early', 'cancelled_late') then
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

  raise exception 'Transisi status sesi tidak diizinkan: % -> %', old.status, new.status;
end;
$$;
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
-- Fix ambiguous column reference in complete_dummy_booking_payment RPC

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
  from public.bookings b
  where b.id = p_booking_id;

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
-- Milestone 16 - Chat notification automation, backend-driven reminders,
-- and push delivery foundation.

create table if not exists public.user_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_uid uuid not null references public.users(uid) on delete cascade,
  push_provider text not null default 'fcm' check (push_provider in ('fcm')),
  platform text not null check (platform in ('android', 'ios', 'web')),
  device_token text not null,
  device_label text not null default '',
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (device_token)
);

create index if not exists idx_user_push_tokens_user_active
  on public.user_push_tokens (user_uid, is_active, updated_at desc);

drop trigger if exists trg_user_push_tokens_touch_updated_at on public.user_push_tokens;
create trigger trg_user_push_tokens_touch_updated_at
before update on public.user_push_tokens
for each row
execute function public.touch_updated_at();

alter table public.user_push_tokens enable row level security;

drop policy if exists user_push_tokens_select_owner on public.user_push_tokens;
create policy user_push_tokens_select_owner
on public.user_push_tokens
for select
to authenticated
using (auth.uid() = user_uid);

drop policy if exists user_push_tokens_insert_owner on public.user_push_tokens;
create policy user_push_tokens_insert_owner
on public.user_push_tokens
for insert
to authenticated
with check (auth.uid() = user_uid);

drop policy if exists user_push_tokens_update_owner on public.user_push_tokens;
create policy user_push_tokens_update_owner
on public.user_push_tokens
for update
to authenticated
using (auth.uid() = user_uid)
with check (auth.uid() = user_uid);

drop policy if exists user_push_tokens_delete_owner on public.user_push_tokens;
create policy user_push_tokens_delete_owner
on public.user_push_tokens
for delete
to authenticated
using (auth.uid() = user_uid);

create table if not exists public.push_delivery_queue (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.app_notifications(id) on delete cascade,
  token_id uuid not null references public.user_push_tokens(id) on delete cascade,
  user_uid uuid not null references public.users(uid) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'processing', 'sent', 'failed')),
  scheduled_for timestamptz not null default now(),
  attempt_count integer not null default 0,
  claimed_at timestamptz,
  sent_at timestamptz,
  provider_message_id text not null default '',
  last_error text not null default '',
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_push_delivery_queue_pending
  on public.push_delivery_queue (status, scheduled_for asc, created_at asc);

create index if not exists idx_push_delivery_queue_user_created
  on public.push_delivery_queue (user_uid, created_at desc);

drop trigger if exists trg_push_delivery_queue_touch_updated_at on public.push_delivery_queue;
create trigger trg_push_delivery_queue_touch_updated_at
before update on public.push_delivery_queue
for each row
execute function public.touch_updated_at();

alter table public.push_delivery_queue enable row level security;

drop policy if exists push_delivery_queue_select_owner on public.push_delivery_queue;
create policy push_delivery_queue_select_owner
on public.push_delivery_queue
for select
to authenticated
using (auth.uid() = user_uid);

create or replace function public.enqueue_push_delivery_for_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.push_delivery_queue (
    notification_id,
    token_id,
    user_uid,
    payload
  )
  select
    new.id,
    token.id,
    new.user_uid,
    jsonb_build_object(
      'title', new.title,
      'body', new.body,
      'category', new.category,
      'target_type', new.target_type,
      'target_id', new.target_id,
      'notification_id', new.id
    )
  from public.user_push_tokens token
  where token.user_uid = new.user_uid
    and token.is_active = true;

  return new;
end;
$$;

drop trigger if exists trg_enqueue_push_delivery_for_notification on public.app_notifications;
create trigger trg_enqueue_push_delivery_for_notification
after insert on public.app_notifications
for each row
execute function public.enqueue_push_delivery_for_notification();

create or replace function public.notify_chat_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  sender_name text;
  title_text text;
  body_text text;
  preview_text text;
  message_count bigint;
begin
  select coalesce(u.display_name, '')
  into sender_name
  from public.users u
  where u.uid = new.sender_uid;

  sender_name := coalesce(nullif(trim(sender_name), ''), 'Pengguna EduConnect');
  preview_text := left(coalesce(new.body, ''), 90);

  select count(*)
  into message_count
  from public.messages m
  where m.booking_id = new.booking_id;

  if message_count <= 1 then
    title_text := 'Percakapan baru dimulai';
    body_text := sender_name || ' memulai percakapan untuk booking ini.';
  else
    title_text := 'Pesan baru dari ' || sender_name;
    body_text := case
      when length(coalesce(new.body, '')) > 90 then preview_text || '...'
      else coalesce(new.body, '')
    end;
  end if;

  insert into public.app_notifications (
    user_uid,
    actor_uid,
    category,
    title,
    body,
    target_type,
    target_id,
    is_read
  ) values (
    new.receiver_uid,
    new.sender_uid,
    'chat',
    title_text,
    body_text,
    'booking_chat',
    new.booking_id::text,
    false
  );

  return new;
end;
$$;

drop trigger if exists trg_notify_chat_message_insert on public.messages;
create trigger trg_notify_chat_message_insert
after insert on public.messages
for each row
execute function public.notify_chat_message_insert();

create or replace function public.process_student_session_reminders(
  p_student_uid uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  sent_count integer := 0;
  item record;
begin
  if actor_uid is not null and actor_uid <> p_student_uid then
    raise exception 'Tidak berhak memproses reminder user lain.';
  end if;

  for item in
    select
      bs.id,
      bs.student_uid,
      bs.tutor_uid,
      case
        when bs.reminder_h2_sent_at is null
          and bs.session_start > now() + interval '1 hour'
          and bs.session_start <= now() + interval '2 hours'
          then 'h2'
        when bs.reminder_h24_sent_at is null
          and bs.session_start > now() + interval '23 hours'
          and bs.session_start <= now() + interval '24 hours'
          then 'h24'
      end as reminder_type
    from public.booking_sessions bs
    join public.bookings b on b.id = bs.booking_id
    where bs.student_uid = p_student_uid
      and bs.status = 'scheduled'
      and b.status = 'paid'
      and (
        (
          bs.reminder_h24_sent_at is null
          and bs.session_start > now() + interval '23 hours'
          and bs.session_start <= now() + interval '24 hours'
        )
        or (
          bs.reminder_h2_sent_at is null
          and bs.session_start > now() + interval '1 hour'
          and bs.session_start <= now() + interval '2 hours'
        )
      )
    for update of bs skip locked
  loop
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    ) values (
      item.student_uid,
      item.tutor_uid,
      'reminder',
      case when item.reminder_type = 'h24' then 'Reminder kelas besok' else 'Reminder kelas 2 jam lagi' end,
      case when item.reminder_type = 'h24'
        then 'Sesi akan dimulai sekitar 24 jam lagi. Jangan lupa konfirmasi hadir.'
        else 'Sesi akan dimulai sekitar 2 jam lagi. Siapkan materi belajarmu ya.'
      end,
      'booking_session',
      item.id::text,
      false
    );

    update public.booking_sessions
    set
      reminder_h24_sent_at = case when item.reminder_type = 'h24' then now() else reminder_h24_sent_at end,
      reminder_h2_sent_at = case when item.reminder_type = 'h2' then now() else reminder_h2_sent_at end,
      updated_at = now()
    where id = item.id;

    sent_count := sent_count + 1;
  end loop;

  return sent_count;
end;
$$;

create or replace function public.process_due_session_reminders()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  sent_count integer := 0;
  item record;
begin
  for item in
    select
      bs.id,
      bs.student_uid,
      bs.tutor_uid,
      case
        when bs.reminder_h2_sent_at is null
          and bs.session_start > now() + interval '1 hour'
          and bs.session_start <= now() + interval '2 hours'
          then 'h2'
        when bs.reminder_h24_sent_at is null
          and bs.session_start > now() + interval '23 hours'
          and bs.session_start <= now() + interval '24 hours'
          then 'h24'
      end as reminder_type
    from public.booking_sessions bs
    join public.bookings b on b.id = bs.booking_id
    where bs.status = 'scheduled'
      and b.status = 'paid'
      and (
        (
          bs.reminder_h24_sent_at is null
          and bs.session_start > now() + interval '23 hours'
          and bs.session_start <= now() + interval '24 hours'
        )
        or (
          bs.reminder_h2_sent_at is null
          and bs.session_start > now() + interval '1 hour'
          and bs.session_start <= now() + interval '2 hours'
        )
      )
    for update of bs skip locked
  loop
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    ) values (
      item.student_uid,
      item.tutor_uid,
      'reminder',
      case when item.reminder_type = 'h24' then 'Reminder kelas besok' else 'Reminder kelas 2 jam lagi' end,
      case when item.reminder_type = 'h24'
        then 'Sesi akan dimulai sekitar 24 jam lagi. Jangan lupa konfirmasi hadir.'
        else 'Sesi akan dimulai sekitar 2 jam lagi. Siapkan materi belajarmu ya.'
      end,
      'booking_session',
      item.id::text,
      false
    );

    update public.booking_sessions
    set
      reminder_h24_sent_at = case when item.reminder_type = 'h24' then now() else reminder_h24_sent_at end,
      reminder_h2_sent_at = case when item.reminder_type = 'h2' then now() else reminder_h2_sent_at end,
      updated_at = now()
    where id = item.id;

    sent_count := sent_count + 1;
  end loop;

  return sent_count;
end;
$$;

revoke all on function public.process_due_session_reminders() from public;
grant execute on function public.process_due_session_reminders() to service_role;

create or replace function public.claim_pending_push_deliveries(
  p_limit integer default 50
)
returns table (
  id uuid,
  notification_id uuid,
  token_id uuid,
  user_uid uuid,
  device_token text,
  platform text,
  push_provider text,
  payload jsonb
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  with claimed as (
    update public.push_delivery_queue q
    set
      status = 'processing',
      claimed_at = now(),
      attempt_count = q.attempt_count + 1,
      updated_at = now()
    where q.id in (
      select q2.id
      from public.push_delivery_queue q2
      where q2.status = 'pending'
        and q2.scheduled_for <= now()
      order by q2.created_at asc
      limit greatest(coalesce(p_limit, 50), 1)
      for update skip locked
    )
    returning q.*
  )
  select
    c.id,
    c.notification_id,
    c.token_id,
    c.user_uid,
    t.device_token,
    t.platform,
    t.push_provider,
    c.payload
  from claimed c
  join public.user_push_tokens t on t.id = c.token_id
  where t.is_active = true;
end;
$$;

revoke all on function public.claim_pending_push_deliveries(integer) from public;
grant execute on function public.claim_pending_push_deliveries(integer) to service_role;

create or replace function public.mark_push_delivery_sent(
  p_delivery_id uuid,
  p_provider_message_id text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.push_delivery_queue
  set
    status = 'sent',
    provider_message_id = coalesce(p_provider_message_id, ''),
    sent_at = now(),
    last_error = '',
    updated_at = now()
  where id = p_delivery_id;
end;
$$;

revoke all on function public.mark_push_delivery_sent(uuid, text) from public;
grant execute on function public.mark_push_delivery_sent(uuid, text) to service_role;

create or replace function public.mark_push_delivery_failed(
  p_delivery_id uuid,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.push_delivery_queue
  set
    status = 'failed',
    last_error = coalesce(p_error, 'unknown error'),
    updated_at = now()
  where id = p_delivery_id;
end;
$$;

revoke all on function public.mark_push_delivery_failed(uuid, text) from public;
grant execute on function public.mark_push_delivery_failed(uuid, text) to service_role;

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      if not exists (
        select 1
        from cron.job
        where jobname = 'educonnect-process-reminders'
      ) then
        perform cron.schedule(
          'educonnect-process-reminders',
          '*/15 * * * *',
          $cron$select public.process_due_session_reminders();$cron$
        );
      end if;
    exception
      when undefined_table then
        raise notice 'pg_cron terdeteksi, namun catalog cron.job tidak tersedia. Jadwalkan process_due_session_reminders() dari scheduler eksternal.';
    end;
  else
    raise notice 'pg_cron belum aktif. Jadwalkan process_due_session_reminders() dari Supabase scheduler atau backend worker.';
  end if;
end
$$;
alter table public.booking_sessions
  drop constraint if exists booking_sessions_status_check;

alter table public.booking_sessions
  add constraint booking_sessions_status_check check (
    status in (
      'scheduled',
      'in_progress',
      'done_pending_confirmation',
      'confirmed',
      'disputed_pending',
      'disputed_resolved',
      'cancelled_by_student',
      'cancelled_by_tutor',
      'cancelled_early',
      'cancelled_late',
      'rescheduled',
      'student_no_show',
      'tutor_no_show'
    )
  );

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

  if old.status = 'disputed_pending' and new.status = 'disputed_resolved' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menutup status dispute.';
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

create or replace function public.process_auto_confirm_sessions()
returns void
language plpgsql
security definer
as $$
declare
  now_utc timestamp with time zone := now() at time zone 'utc';
begin
  update public.booking_sessions
  set 
    status = 'confirmed',
    updated_at = now_utc
  where status = 'done_pending_confirmation'
    and tutor_marked_done_at < (now_utc - interval '24 hours');
end;
$$;
-- 202605180001_milestone17_reviews_system.sql

create table public.tutor_reviews (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid references public.tutors(uid) on delete cascade not null,
  student_uid uuid references public.users(uid) on delete cascade not null,
  booking_id uuid references public.bookings(id) on delete set null,
  rating numeric not null check (rating >= 1 and rating <= 5),
  review_text text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.tutor_reviews enable row level security;

create policy "Reviews are viewable by everyone" 
  on public.tutor_reviews for select 
  using (true);

create policy "Students can insert their own reviews" 
  on public.tutor_reviews for insert 
  with check (auth.uid() = student_uid);

create policy "Students can update their own reviews"
  on public.tutor_reviews for update
  using (auth.uid() = student_uid);

-- Trigger to update tutor's rating
create or replace function public.handle_tutor_review_insert_or_update()
returns trigger
language plpgsql security definer
as $$
declare
  v_avg_rating numeric;
  v_total_reviews integer;
  v_target_tutor uuid;
begin
  if tg_op = 'DELETE' then
    v_target_tutor := old.tutor_uid;
  else
    v_target_tutor := new.tutor_uid;
  end if;

  select count(*), coalesce(avg(rating), 0)
  into v_total_reviews, v_avg_rating
  from public.tutor_reviews
  where tutor_uid = v_target_tutor;

  update public.tutors
  set rating = v_avg_rating,
      total_reviews = v_total_reviews,
      updated_at = timezone('utc'::text, now())
  where uid = v_target_tutor;

  if tg_op = 'DELETE' then
    return old;
  else
    return new;
  end if;
end;
$$;

create trigger on_tutor_review_changed
  after insert or update or delete on public.tutor_reviews
  for each row execute procedure public.handle_tutor_review_insert_or_update();
-- 202605180002_milestone18_ebook_library.sql

-- 1. Create table library_ebooks
create table public.library_ebooks (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid references public.tutors(uid) on delete cascade not null,
  title text not null,
  description text not null default '',
  file_url text not null,
  file_size_mb numeric not null default 0,
  format text not null default 'PDF',
  accent_color_hex text not null default '#4B176E',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.library_ebooks enable row level security;

create policy "Ebooks are viewable by everyone" 
  on public.library_ebooks for select 
  using (true);

create policy "Tutors can insert their own ebooks" 
  on public.library_ebooks for insert 
  with check (auth.uid() = tutor_uid);

create policy "Tutors can update their own ebooks"
  on public.library_ebooks for update
  using (auth.uid() = tutor_uid);

create policy "Tutors can delete their own ebooks"
  on public.library_ebooks for delete
  using (auth.uid() = tutor_uid);

-- 2. Create Storage Bucket for Ebooks
insert into storage.buckets (id, name, public) 
values ('ebooks', 'ebooks', true)
on conflict do nothing;

-- 3. Storage Policies
create policy "Ebook files are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'ebooks' );

create policy "Tutors can upload ebook files"
  on storage.objects for insert
  with check (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );

create policy "Tutors can update their ebook files"
  on storage.objects for update
  using (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );

create policy "Tutors can delete their ebook files"
  on storage.objects for delete
  using (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );
-- Milestone week 19 - Security Hardening & RLS Audit Fixes
-- Relax SELECT policy on public.users so authenticated users can view each other's profile metadata (e.g. name, photo_url, role)
-- This is critical for features like Student Roster, Chat Inbox, and Reviews to display actual student/tutor profiles.

drop policy if exists users_select_own on public.users;
drop policy if exists users_select_all_auth on public.users;

create policy users_select_all_auth
on public.users
for select
to authenticated
using (
  auth.uid() = uid
  or role = 'tutor'
  or exists (
    select 1 from public.bookings b
    where (b.student_uid = auth.uid() and b.tutor_uid = uid)
       or (b.tutor_uid = auth.uid() and b.student_uid = uid)
  )
);
-- Fase 3: Sistem Rekomendasi Tutor Cerdas Berbasis Jarak & Preferensi Murid

-- 1. Tambahkan kolom preferensi pada tabel users
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS preferred_subjects text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS max_price_preference numeric NOT NULL DEFAULT 0;

-- 2. Buat fungsi get_recommended_tutors yang menghitung skor pencocokan dinamis
CREATE OR REPLACE FUNCTION public.get_recommended_tutors(
  p_student_uid uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 25
)
RETURNS TABLE (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  consistency_score double precision,
  experience_years integer,
  distance_km double precision,
  recommendation_score double precision
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_preferred_subjects text[];
  v_max_price numeric;
BEGIN
  -- Ambil preferensi siswa
  SELECT preferred_subjects, max_price_preference
  INTO v_preferred_subjects, v_max_price
  FROM public.users
  WHERE users.uid = p_student_uid;

  -- Normalisasi nilai default preferensi jika kosong
  IF v_preferred_subjects IS NULL THEN
    v_preferred_subjects := '{}';
  END IF;
  
  IF v_max_price IS NULL OR v_max_price <= 0 THEN
    v_max_price := 1000000; -- Fallback jika budget tidak dibatasi
  END IF;

  RETURN QUERY
  SELECT
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    t.consistency_score::double precision as consistency_score,
    t.experience_years,
    -- Hitung Jarak (km) dari koordinat siswa ke tutor menggunakan PostGIS geography
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000.0 as distance_km,
    -- Hitung Skor Rekomendasi Dinamis (0 - 100)
    ROUND(
      -- A. Bobot Jarak (40%): semakin dekat semakin tinggi skornya
      (CASE 
        WHEN st_dwithin(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography, p_radius_km * 1000) THEN
          (1.0 - (st_distance(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography) / 1000.0) / p_radius_km) * 40.0
        ELSE 0.0
      END) +
      -- B. Bobot Mapel (35%): jika ada mata pelajaran yang diajarkan tutor beririsan dengan preferensi murid
      (CASE 
        WHEN t.subjects && v_preferred_subjects THEN 35.0
        ELSE 0.0
      END) +
      -- C. Bobot Batas Harga/Budget (10%)
      (CASE 
        WHEN t.price_per_hour <= v_max_price THEN 10.0
        WHEN t.price_per_hour > 0 THEN (v_max_price / t.price_per_hour) * 10.0
        ELSE 0.0
      END) +
      -- D. Bobot Rating & Kualitas (10%)
      (CASE 
        WHEN t.rating > 0 THEN (t.rating / 5.0) * 10.0
        ELSE 0.0
      END) +
      -- E. Bobot Disiplin/Konsistensi (5%)
      (CASE 
        WHEN t.consistency_score > 0 THEN (t.consistency_score::double precision / 100.0) * 5.0
        ELSE 0.0
      END)
    ) as recommendation_score
  FROM public.tutors t
  WHERE t.is_active = true
    AND t.location IS NOT NULL
    AND st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  ORDER BY recommendation_score DESC, distance_km ASC
  LIMIT greatest(coalesce(p_limit, 25), 1);
END;
$$;
-- Migration for Tutor Verification & Curation System
alter table public.tutors 
add column if not exists verification_status text not null default 'none' check (verification_status in ('none', 'pending', 'approved', 'rejected')),
add column if not exists identity_card_url text,
add column if not exists certificate_url text,
add column if not exists rejection_reason text;

-- Create storage bucket for tutor documents if not exists
insert into storage.buckets (id, name, public)
values ('tutor-documents', 'tutor-documents', false) -- Private bucket for secure document storage
on conflict (id) do nothing;

-- RLS policies for tutor-documents storage bucket
drop policy if exists tutor_docs_select_own on storage.objects;
create policy tutor_docs_select_own
on storage.objects
for select
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_insert_own on storage.objects;
create policy tutor_docs_insert_own
on storage.objects
for insert
with check (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_update_own on storage.objects;
create policy tutor_docs_update_own
on storage.objects
for update
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_delete_own on storage.objects;
create policy tutor_docs_delete_own
on storage.objects
for delete
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);
-- Milestone 20 - Wallet and payout foundation
--
-- NOTE:
-- This migration originally only added `rejection_reason` to `payout_requests`.
-- In practice, the base wallet tables were missing in some environments, so the
-- migration now bootstraps the wallet schema safely before applying that field.

create table if not exists public.tutor_wallets (
  tutor_uid uuid primary key references public.tutors(uid) on delete cascade,
  available_balance numeric not null default 0 check (available_balance >= 0),
  pending_balance numeric not null default 0 check (pending_balance >= 0),
  total_earned numeric not null default 0 check (total_earned >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null check (amount > 0),
  type text not null check (type in ('credit', 'debit')),
  description text not null default '',
  reference_type text not null default '',
  reference_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.payout_requests (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null check (amount > 0),
  bank_name text not null default '',
  account_number text not null default '',
  account_holder text not null default '',
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected', 'completed')
  ),
  rejection_reason text,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payout_requests
  add column if not exists rejection_reason text;

create index if not exists idx_wallet_transactions_tutor_created
  on public.wallet_transactions (tutor_uid, created_at desc);

create index if not exists idx_payout_requests_tutor_created
  on public.payout_requests (tutor_uid, created_at desc);

drop trigger if exists trg_tutor_wallets_touch_updated_at on public.tutor_wallets;
create trigger trg_tutor_wallets_touch_updated_at
before update on public.tutor_wallets
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_payout_requests_touch_updated_at on public.payout_requests;
create trigger trg_payout_requests_touch_updated_at
before update on public.payout_requests
for each row
execute function public.touch_updated_at();

create or replace function public.ensure_tutor_wallet_row(p_tutor_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.tutor_wallets (tutor_uid)
  values (p_tutor_uid)
  on conflict (tutor_uid) do nothing;
end;
$$;

create or replace function public.request_tutor_payout(
  p_tutor_uid uuid,
  p_amount numeric,
  p_bank_name text,
  p_account_number text,
  p_account_holder text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  wallet_row public.tutor_wallets%rowtype;
  payout_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus login untuk mengajukan payout.';
  end if;

  if auth.uid() <> p_tutor_uid then
    raise exception 'Anda tidak berhak mengajukan payout untuk tutor lain.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Jumlah payout tidak valid.';
  end if;

  if coalesce(trim(p_bank_name), '') = ''
    or coalesce(trim(p_account_number), '') = ''
    or coalesce(trim(p_account_holder), '') = '' then
    raise exception 'Informasi rekening payout wajib lengkap.';
  end if;

  perform public.ensure_tutor_wallet_row(p_tutor_uid);

  select *
  into wallet_row
  from public.tutor_wallets
  where tutor_uid = p_tutor_uid
  for update;

  if wallet_row.available_balance < p_amount then
    raise exception 'Saldo tersedia tidak mencukupi untuk payout ini.';
  end if;

  insert into public.payout_requests (
    tutor_uid,
    amount,
    bank_name,
    account_number,
    account_holder,
    status
  )
  values (
    p_tutor_uid,
    p_amount,
    trim(p_bank_name),
    trim(p_account_number),
    trim(p_account_holder),
    'pending'
  )
  returning id into payout_id;

  update public.tutor_wallets
  set
    available_balance = available_balance - p_amount,
    pending_balance = pending_balance + p_amount
  where tutor_uid = p_tutor_uid;

  insert into public.wallet_transactions (
    tutor_uid,
    amount,
    type,
    description,
    reference_type,
    reference_id
  )
  values (
    p_tutor_uid,
    p_amount,
    'debit',
    'Permintaan payout diajukan',
    'payout',
    payout_id::text
  );

  return payout_id;
end;
$$;

create or replace function public.create_wallet_for_new_tutor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ensure_tutor_wallet_row(new.uid);
  return new;
end;
$$;

drop trigger if exists trg_tutors_create_wallet on public.tutors;
create trigger trg_tutors_create_wallet
after insert on public.tutors
for each row
execute function public.create_wallet_for_new_tutor();

insert into public.tutor_wallets (tutor_uid)
select t.uid
from public.tutors t
on conflict (tutor_uid) do nothing;

alter table public.tutor_wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.payout_requests enable row level security;

drop policy if exists tutor_wallets_select_own on public.tutor_wallets;
create policy tutor_wallets_select_own
on public.tutor_wallets
for select
using (auth.uid() = tutor_uid);

drop policy if exists wallet_transactions_select_own on public.wallet_transactions;
create policy wallet_transactions_select_own
on public.wallet_transactions
for select
using (auth.uid() = tutor_uid);

drop policy if exists payout_requests_select_own on public.payout_requests;
create policy payout_requests_select_own
on public.payout_requests
for select
using (auth.uid() = tutor_uid);

drop policy if exists payout_requests_update_own on public.payout_requests;
create policy payout_requests_update_own
on public.payout_requests
for update
using (auth.uid() = tutor_uid)
with check (auth.uid() = tutor_uid);

grant execute on function public.request_tutor_payout(uuid, numeric, text, text, text)
to authenticated;

-- Migration to fix Tutor Curation Bypass
-- Ensure tutors are NOT active and do NOT show up on maps or searches until approved by an admin.

-- 1. Cleanse existing database state: set is_active to false for any tutor whose verification_status is not 'approved'
update public.tutors
set is_active = false
where verification_status <> 'approved';

-- 2. Update get_nearby_tutors RPC to strictly filter for approved verification_status
create or replace function public.get_nearby_tutors(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 250
)
returns table (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  distance_km double precision
)
language sql
stable
as $$
  select
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000 as distance_km
  from public.tutors t
  where t.is_active = true
    and t.verification_status = 'approved' -- Strictly allow only verified/approved tutors
    and t.location is not null
    and st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  order by distance_km asc
  limit greatest(coalesce(p_limit, 250), 1);
$$;

-- 3. Update get_recommended_tutors RPC to strictly filter for approved verification_status
create or replace function public.get_recommended_tutors(
  p_student_uid uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 25
)
returns table (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  consistency_score double precision,
  experience_years integer,
  distance_km double precision,
  recommendation_score double precision
)
language plpgsql
stable
as $$
declare
  v_preferred_subjects text[];
  v_max_price numeric;
BEGIN
  -- Ambil preferensi siswa
  SELECT preferred_subjects, max_price_preference
  INTO v_preferred_subjects, v_max_price
  FROM public.users
  WHERE users.uid = p_student_uid;

  -- Normalisasi nilai default preferensi jika kosong
  IF v_preferred_subjects IS NULL THEN
    v_preferred_subjects := '{}';
  END IF;
  
  IF v_max_price IS NULL OR v_max_price <= 0 THEN
    v_max_price := 1000000; -- Fallback jika budget tidak dibatasi
  END IF;

  RETURN QUERY
  SELECT
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    t.consistency_score::double precision as consistency_score,
    t.experience_years,
    -- Hitung Jarak (km) dari koordinat siswa ke tutor menggunakan PostGIS geography
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000.0 as distance_km,
    -- Hitung Skor Rekomendasi Dinamis (0 - 100)
    ROUND(
      -- A. Bobot Jarak (40%): semakin dekat semakin tinggi skornya
      (CASE 
        WHEN st_dwithin(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography, p_radius_km * 1000) THEN
          (1.0 - (st_distance(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography) / 1000.0) / p_radius_km) * 40.0
        ELSE 0.0
      END) +
      -- B. Bobot Mapel (35%): jika ada mata pelajaran yang diajarkan tutor beririsan dengan preferensi murid
      (CASE 
        WHEN t.subjects && v_preferred_subjects THEN 35.0
        ELSE 0.0
      END) +
      -- C. Bobot Batas Harga/Budget (10%)
      (CASE 
        WHEN t.price_per_hour <= v_max_price THEN 10.0
        WHEN t.price_per_hour > 0 THEN (v_max_price / t.price_per_hour) * 10.0
        ELSE 0.0
      END) +
      -- D. Bobot Rating & Kualitas (10%)
      (CASE 
        WHEN t.rating > 0 THEN (t.rating / 5.0) * 10.0
        ELSE 0.0
      END) +
      -- E. Bobot Disiplin/Konsistensi (5%)
      (CASE 
        WHEN t.consistency_score > 0 THEN (t.consistency_score::double precision / 100.0) * 5.0
        ELSE 0.0
      END)
    ) as recommendation_score
  FROM public.tutors t
  WHERE t.is_active = true
    and t.verification_status = 'approved' -- Strictly allow only verified/approved tutors
    AND t.location IS NOT NULL
    AND st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  ORDER BY recommendation_score DESC, distance_km ASC
  LIMIT greatest(coalesce(p_limit, 25), 1);
END;
$$;
-- Migration to fix Celah Kedua: Wallet Revenue Integration
-- Automatically credit the tutor's wallet when a booking session transitions to a payable status.

create or replace function public.process_tutor_session_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price_per_hour numeric;
  v_duration_minutes numeric;
  v_session_cost numeric;
  v_payout_amount numeric;
  v_description text;
  v_is_payable boolean := false;
  v_transaction_type text := 'credit';
begin
  -- 1. Check if the status transitioned to a payable status
  -- Payable statuses: 'confirmed', 'disputed_resolved', 'student_no_show', 'cancelled_late' (if cancelled by student)
  if (new.status = 'confirmed' and (old.status is null or old.status <> 'confirmed')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout
    v_description := 'Pendapatan sesi les selesai & dikonfirmasi';
  elsif (new.status = 'disputed_resolved' and (old.status is null or old.status <> 'disputed_resolved')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout (dispute resolved in tutor favor)
    v_description := 'Pendapatan sesi les (dispute selesai)';
  elsif (new.status = 'student_no_show' and (old.status is null or old.status <> 'student_no_show')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout (murid tidak hadir)
    v_description := 'Kompensasi penuh (murid tidak hadir/no-show)';
  elsif (new.status = 'cancelled_late' and (old.status is null or old.status <> 'cancelled_late') and new.cancelled_by_role = 'student') then
    v_is_payable := true;
    v_payout_amount := 0.5; -- 50% late cancellation compensation by student
    v_description := 'Kompensasi pembatalan terlambat oleh murid (50%)';
  end if;

  if not v_is_payable then
    return new;
  end if;

  -- 2. Fetch tutor's price_per_hour
  select price_per_hour into v_price_per_hour
  from public.tutors
  where uid = new.tutor_uid;

  if v_price_per_hour is null or v_price_per_hour <= 0 then
    -- If tutor rate is not set, we cannot calculate payment. Do not raise error to avoid blocking transaction.
    return new;
  end if;

  -- 3. Calculate session duration in minutes
  v_duration_minutes := round(extract(epoch from (new.session_end - new.session_start)) / 60.0);
  if v_duration_minutes <= 0 then
    return new;
  end if;

  -- 4. Calculate net credit cost matching Flutter's rounding logic
  v_session_cost := round(((v_price_per_hour * v_duration_minutes) / 60.0) * v_payout_amount);

  if v_session_cost <= 0 then
    return new;
  end if;

  -- 5. Ensure tutor wallet row exists
  perform public.ensure_tutor_wallet_row(new.tutor_uid);

  -- 6. Update tutor's wallet balance
  update public.tutor_wallets
  set
    available_balance = available_balance + v_session_cost,
    total_earned = total_earned + v_session_cost,
    updated_at = now()
  where tutor_uid = new.tutor_uid;

  -- 7. Record transaction history in wallet_transactions
  insert into public.wallet_transactions (
    tutor_uid,
    amount,
    type,
    description,
    reference_type,
    reference_id
  )
  values (
    new.tutor_uid,
    v_session_cost,
    v_transaction_type,
    v_description,
    'booking_session',
    new.id::text
  );

  return new;
end;
$$;

-- Create trigger on booking_sessions
drop trigger if exists trg_booking_sessions_process_payment on public.booking_sessions;
create trigger trg_booking_sessions_process_payment
after update on public.booking_sessions
for each row
execute function public.process_tutor_session_payment();
-- Migration to introduce secure simulated webhook payment confirmation and deprecate direct dummy payments.

-- 1. Deprecate and revoke direct execution permissions on the old client-triggered RPC
revoke execute on function public.complete_dummy_booking_payment(uuid) from public, authenticated;

-- 2. Create the secure simulated webhook handler
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
  v_expected_signature := encode(hmac(p_booking_id::text, 'EDUCONNECT_SECRET_SERVER_KEY', 'sha256'), 'hex');
  
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

-- Grant execution to authenticated users (they can invoke the simulated gateway webhook trigger, but it will only succeed with a valid signature key)
grant execute on function public.handle_secure_webhook_payment(uuid, text, text) to authenticated;

-- Security Hardening & RLS Audit Fixes for Ebooks, Sessions, and Transactions (2026-05-28)
-- 1. Tighten storage policies for ebooks bucket to ensure folder ownership matching tutor UID
drop policy if exists "Tutors can upload ebook files" on storage.objects;
drop policy if exists "Tutors can update their ebook files" on storage.objects;
drop policy if exists "Tutors can delete their ebook files" on storage.objects;

create policy "Tutors can upload ebook files"
  on storage.objects for insert
  with check (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Tutors can update their ebook files"
  on storage.objects for update
  using (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Tutors can delete their ebook files"
  on storage.objects for delete
  using (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2. Restrict booking_sessions insert policy to ensure sessions can only be created for bookings that are paid
drop policy if exists booking_sessions_insert_owner on public.booking_sessions;

create policy booking_sessions_insert_owner
  on public.booking_sessions
  for insert
  with check (
    (auth.uid() = student_uid or auth.uid() = tutor_uid)
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and b.status = 'paid'
    )
  );

-- 3. Remove direct client-side INSERT on transactions
drop policy if exists transactions_insert_student_or_tutor on public.transactions;

-- 4. Secure transactions UPDATE policy to prevent unauthorized payment status modification (only allow transition to pending or keeping status unchanged)
drop policy if exists transactions_update_student_or_tutor on public.transactions;

create policy transactions_update_student_or_tutor
  on public.transactions
  for update
  using (auth.uid() = student_uid or auth.uid() = tutor_uid)
  with check (
    (auth.uid() = student_uid or auth.uid() = tutor_uid)
    and (payment_status = 'pending' or payment_status = old.payment_status)
  );

-- =========================================================================
-- double booking prevention trigger on booking_sessions
-- =========================================================================
create or replace function public.prevent_double_booking()
returns trigger
language plpgsql
as $$
begin
  if new.status in ('cancelled_by_student', 'cancelled_by_tutor', 'cancelled_early', 'cancelled_late', 'rescheduled') then
    return new;
  end if;

  if exists (
    select 1 from public.booking_sessions s
    where s.tutor_uid = new.tutor_uid
      and s.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and s.status not in ('cancelled_by_student', 'cancelled_by_tutor', 'cancelled_early', 'cancelled_late', 'rescheduled')
      and s.session_start < new.session_end
      and s.session_end > new.session_start
  ) then
    raise exception 'Tutor sudah memiliki sesi lain yang tumpang tindih pada waktu tersebut.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_prevent_double_booking on public.booking_sessions;
create trigger trg_prevent_double_booking
before insert or update of session_start, session_end, status on public.booking_sessions
for each row
execute function public.prevent_double_booking();

-- =========================================================================
-- reschedule & cancel time constraints triggers
-- =========================================================================
create or replace function public.check_session_change_request_time()
returns trigger
language plpgsql
as $$
declare
  v_session_start timestamptz;
begin
  select session_start into v_session_start
  from public.booking_sessions
  where id = new.session_id;

  if not found then
    raise exception 'Sesi tidak ditemukan.';
  end if;

  if v_session_start <= now() then
    raise exception 'Sesi sudah dimulai atau sudah lewat, tidak bisa diajukan perubahan.';
  end if;

  if new.request_type = 'reschedule' then
    if v_session_start - now() < interval '6 hours' then
      raise exception 'Request reschedule harus diajukan minimal H-6 sebelum sesi.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_session_change_request_time on public.session_change_requests;
create trigger trg_check_session_change_request_time
before insert on public.session_change_requests
for each row
execute function public.check_session_change_request_time();


create or replace function public.check_booking_session_status_time()
returns trigger
language plpgsql
as $$
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'cancelled_early' then
    if old.session_start - now() < interval '12 hours' then
      raise exception 'Pembatalan kurang dari 12 jam harus berupa cancelled_late.';
    end if;
  end if;

  if new.status = 'rescheduled' then
    if old.session_start - now() < interval '6 hours' then
      raise exception 'Reschedule kurang dari 6 jam tidak diperbolehkan.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_booking_session_status_time on public.booking_sessions;
create trigger trg_check_booking_session_status_time
before update of status on public.booking_sessions
for each row
execute function public.check_booking_session_status_time();

-- Automate payout request approvals for verified tutors and amounts < Rp 2,000,000
create or replace function public.auto_approve_payout_requests()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_verification_status text;
begin
  select verification_status into v_verification_status
  from public.tutors
  where uid = new.tutor_uid;

  if v_verification_status = 'approved' and new.amount < 2000000 then
    update public.payout_requests
    set status = 'completed'
    where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_auto_approve_payout_requests on public.payout_requests;
create trigger trg_auto_approve_payout_requests
  after insert
  on public.payout_requests
  for each row
  execute function public.auto_approve_payout_requests();


-- Function to scan for ended sessions and trigger attendance validation notifications
create or replace function public.check_and_trigger_session_end_notifications()
returns void
language plpgsql
security definer
as $$
declare
  item record;
  now_utc timestamp with time zone := now();
begin
  for item in
    select bs.id, bs.tutor_uid, bs.student_uid, b.subject
    from public.booking_sessions bs
    join public.bookings b on b.id = bs.booking_id
    where bs.status = 'scheduled'
      and bs.session_end < now_utc
      and not exists (
        select 1 from public.app_notifications
        where category = 'session_ended'
          and target_id = bs.id::text
      )
  loop
    -- Send notification to tutor to validate presence
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    ) values (
      item.tutor_uid,
      item.student_uid,
      'session_change',
      'Sesi Belajar Telah Berakhir',
      'Sesi pelajaran ' || item.subject || ' telah selesai. Silakan lakukan validasi kehadiran agar dapat mengirimkan materi/PR.',
      'booking_session',
      item.id::text,
      false
    );

    -- Send notification to student to wait/confirm
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    ) values (
      item.student_uid,
      item.tutor_uid,
      'session_change',
      'Sesi Belajar Telah Berakhir',
      'Sesi pelajaran ' || item.subject || ' telah selesai. Harap tunggu tutor memvalidasi kehadiran.',
      'booking_session',
      item.id::text,
      false
    );
  end loop;
end;
$$;

grant execute on function public.check_and_trigger_session_end_notifications() to authenticated;
grant execute on function public.check_and_trigger_session_end_notifications() to service_role;

-- Milestone week 24 - Enable pg_net extension
create extension if not exists pg_net with schema extensions;

-- Function to trigger dispatch-push Edge Function via HTTP POST
create or replace function public.trigger_push_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url text;
begin
  v_url := coalesce(
    current_setting('app.settings.supabase_url', true),
    'https://vkhmleulohwavtdvkwdb.supabase.co'
  ) || '/functions/v1/dispatch-push';

  perform net.http_post(
    url := v_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  return new;
end;
$$;

-- Trigger to dispatch enqueued push delivery queue messages
drop trigger if exists trg_push_dispatch on public.push_delivery_queue;
create trigger trg_push_dispatch
after insert on public.push_delivery_queue
for each statement
execute function public.trigger_push_dispatch();
