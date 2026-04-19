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
