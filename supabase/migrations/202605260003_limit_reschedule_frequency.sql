-- Supabase Migration: Limit Reschedule Frequency
-- Restrict reschedule requests to a maximum of 2 active/approved requests per booking in a rolling 30-day period.

create or replace function public.validate_session_change_request_insert()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  session_row record;
  v_reschedule_count integer;
begin
  if actor_uid is not null and actor_uid <> new.requester_uid then
    raise exception 'Requester tidak sesuai auth user.';
  end if;

  select bs.booking_id, bs.student_uid, bs.tutor_uid, bs.status
  into session_row
  from public.booking_sessions bs
  where bs.id = new.session_id;

  if not found then
    raise exception 'Sesi tidak ditemukan.';
  end if;

  if session_row.booking_id <> new.booking_id then
    raise exception 'booking_id request tidak sesuai sesi.';
  end if;

  if session_row.status <> 'scheduled' then
    raise exception 'Request hanya boleh untuk sesi scheduled.';
  end if;

  if new.requester_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.target_uid not in (session_row.student_uid, session_row.tutor_uid)
     or new.requester_uid = new.target_uid then
    raise exception 'Requester/target tidak valid untuk sesi ini.';
  end if;

  if new.requester_role = 'student' and new.requester_uid <> session_row.student_uid then
    raise exception 'requester_role student tidak cocok.';
  end if;

  if new.requester_role = 'tutor' and new.requester_uid <> session_row.tutor_uid then
    raise exception 'requester_role tutor tidak cocok.';
  end if;

  if new.request_type = 'reschedule' then
    if new.proposed_start is null or new.proposed_end is null or new.proposed_end <= new.proposed_start then
      raise exception 'Waktu reschedule tidak valid.';
    end if;

    -- LIMIT RESCHEDULE FREQUENCY: Max 2 reschedule requests (pending or approved) per booking in rolling 30 days
    select count(*)
    into v_reschedule_count
    from public.session_change_requests
    where booking_id = new.booking_id
      and request_type = 'reschedule'
      and status in ('approved', 'pending')
      and created_at >= (now() - interval '30 days');

    if v_reschedule_count >= 2 then
      raise exception 'Batas maksimal reschedule untuk kelas ini (maksimal 2 kali dalam 30 hari) telah tercapai.';
    end if;
  end if;

  if new.expires_at is null then
    new.expires_at := now() + interval '24 hours';
  end if;

  return new;
end;
$$;
