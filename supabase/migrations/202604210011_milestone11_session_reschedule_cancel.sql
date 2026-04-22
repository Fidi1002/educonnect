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
