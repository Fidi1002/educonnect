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
