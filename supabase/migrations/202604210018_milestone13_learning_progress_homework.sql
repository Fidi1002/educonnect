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
