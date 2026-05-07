-- Milestone week 14 - Operational flow hardening for no-show and auto booking completion

create or replace function public.is_terminal_booking_session_status(
  p_status text
)
returns boolean
language sql
immutable
as $$
  select p_status in (
    'confirmed',
    'disputed_resolved',
    'cancelled_by_student',
    'cancelled_by_tutor',
    'cancelled_early',
    'cancelled_late',
    'rescheduled',
    'student_no_show',
    'tutor_no_show'
  );
$$;

create or replace function public.enforce_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  has_open_sessions boolean := false;
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah booking ini.';
  end if;

  if new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.subject <> old.subject
    or new.session_start <> old.session_start
    or new.session_end <> old.session_end
    or new.package_months <> old.package_months
    or new.sessions_per_week <> old.sessions_per_week
    or new.weekly_schedule <> old.weekly_schedule
    or new.package_start_date <> old.package_start_date
    or new.package_end_date <> old.package_end_date then
    raise exception 'Field inti booking tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status = 'pending' and new.status in ('awaiting_payment', 'rejected') then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa memproses permintaan booking.';
    end if;
    return new;
  end if;

  if old.status = 'awaiting_payment' and new.status = 'paid' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa membayar booking.';
    end if;
    if new.paid_at is null then
      raise exception 'paid_at wajib diisi saat status paid.';
    end if;
    return new;
  end if;

  if old.status = 'paid' and new.status = 'completed' then
    select exists (
      select 1
      from public.booking_sessions bs
      where bs.booking_id = old.id
        and not public.is_terminal_booking_session_status(bs.status)
    )
    into has_open_sessions;

    if has_open_sessions then
      raise exception 'Booking belum bisa selesai karena masih ada sesi aktif.';
    end if;
    return new;
  end if;

  if old.status in ('pending', 'awaiting_payment', 'paid') and new.status = 'cancelled' then
    return new;
  end if;

  raise exception 'Transisi status booking tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

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

  if old.status = 'scheduled' and new.status = 'student_no_show' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai murid tidak hadir.';
    end if;
    if old.session_end > now() then
      raise exception 'Tunggu sesi berakhir sebelum menandai murid tidak hadir.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'tutor_no_show' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa menandai tutor tidak hadir.';
    end if;
    if old.session_end > now() then
      raise exception 'Tunggu sesi berakhir sebelum menandai tutor tidak hadir.';
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
