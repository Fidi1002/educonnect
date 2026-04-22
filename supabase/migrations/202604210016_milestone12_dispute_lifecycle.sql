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
