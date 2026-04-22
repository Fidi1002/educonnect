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
