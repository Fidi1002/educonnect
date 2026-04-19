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
