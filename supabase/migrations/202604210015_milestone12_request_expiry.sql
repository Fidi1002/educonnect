-- Milestone week 12.2 - Session change request expiry (24h SLA)
alter table public.session_change_requests
  add column if not exists expires_at timestamptz;

update public.session_change_requests
set expires_at = created_at + interval '24 hours'
where expires_at is null;

alter table public.session_change_requests
  alter column expires_at set default (now() + interval '24 hours');

alter table public.session_change_requests
  alter column expires_at set not null;

alter table public.session_change_requests
  drop constraint if exists session_change_requests_status_check;

alter table public.session_change_requests
  add constraint session_change_requests_status_check check (
    status in ('pending', 'approved', 'rejected', 'cancelled', 'expired')
  );

create index if not exists idx_session_change_requests_status_expiry
  on public.session_change_requests (status, expires_at asc);

create or replace function public.validate_session_change_request_insert()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
  session_row record;
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
  end if;

  if new.expires_at is null then
    new.expires_at := now() + interval '24 hours';
  end if;

  return new;
end;
$$;

create or replace function public.enforce_session_change_request_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.requester_uid and actor_uid <> old.target_uid then
    raise exception 'Tidak berhak mengubah request ini.';
  end if;

  if new.session_id <> old.session_id
    or new.booking_id <> old.booking_id
    or new.requester_uid <> old.requester_uid
    or new.target_uid <> old.target_uid
    or new.request_type <> old.request_type
    or coalesce(new.proposed_start, 'epoch'::timestamptz) <> coalesce(old.proposed_start, 'epoch'::timestamptz)
    or coalesce(new.proposed_end, 'epoch'::timestamptz) <> coalesce(old.proposed_end, 'epoch'::timestamptz)
    or new.expires_at <> old.expires_at then
    raise exception 'Field inti request tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status <> 'pending' then
    raise exception 'Hanya request pending yang dapat diubah.';
  end if;

  if old.expires_at <= now() and new.status <> 'expired' then
    raise exception 'Request sudah kedaluwarsa.';
  end if;

  if new.status in ('approved', 'rejected') then
    if actor_uid <> old.target_uid then
      raise exception 'Hanya target request yang bisa approve/reject.';
    end if;
    if new.reviewed_by_uid is distinct from actor_uid or new.reviewed_at is null then
      raise exception 'reviewed_by_uid/reviewed_at tidak valid.';
    end if;
    return new;
  end if;

  if new.status = 'cancelled' then
    if actor_uid <> old.requester_uid then
      raise exception 'Hanya requester yang bisa cancel request.';
    end if;
    return new;
  end if;

  if new.status = 'expired' then
    if old.expires_at > now() then
      raise exception 'Request belum melewati masa kedaluwarsa.';
    end if;
    if new.reviewed_by_uid is not null then
      raise exception 'Request expired tidak memiliki reviewer.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status request tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

create or replace function public.expire_stale_session_change_requests(
  p_booking_id uuid default null,
  p_session_id uuid default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  affected_count integer := 0;
begin
  update public.session_change_requests scr
  set status = 'expired',
      reviewed_at = now(),
      updated_at = now()
  where scr.status = 'pending'
    and scr.expires_at <= now()
    and (p_booking_id is null or scr.booking_id = p_booking_id)
    and (p_session_id is null or scr.session_id = p_session_id)
    and (
      actor_uid is null
      or actor_uid = scr.requester_uid
      or actor_uid = scr.target_uid
    );

  get diagnostics affected_count = row_count;
  return affected_count;
end;
$$;

revoke all on function public.expire_stale_session_change_requests(uuid, uuid) from public;
grant execute on function public.expire_stale_session_change_requests(uuid, uuid) to authenticated;
