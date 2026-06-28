-- Migration to add feedback and grade to homework
alter table public.session_learning_records
  add column if not exists tutor_feedback text not null default '',
  add column if not exists homework_grade integer check (homework_grade >= 0 and homework_grade <= 100);

-- Redefine enforce_session_learning_record_transition trigger function to block students from changing feedback/grade
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
      or new.reviewed_at is distinct from old.reviewed_at
      or new.tutor_feedback <> old.tutor_feedback
      or new.homework_grade is distinct from old.homework_grade then
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
    new.tutor_feedback := '';
    new.homework_grade := null;
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
    new.tutor_feedback := '';
    new.homework_grade := null;
    return new;
  end if;

  if old.homework_status = new.homework_status then
    return new;
  end if;

  raise exception 'Transisi PR tidak diizinkan: % -> %', old.homework_status, new.homework_status;
end;
$$;
