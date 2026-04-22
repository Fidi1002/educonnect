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
