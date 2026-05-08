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
