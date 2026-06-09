-- Supabase Migration: Enforce Reschedule & Cancel Time Constraints
-- Enforce H-6 hours limit for reschedule requests and H-12 hours limit for early cancellations.

-- 1) Function & Trigger for session_change_requests (BEFORE INSERT)
create or replace function public.check_session_change_request_time()
returns trigger
language plpgsql
as $$
declare
  v_session_start timestamptz;
begin
  select session_start into v_session_start
  from public.booking_sessions
  where id = new.session_id;

  if not found then
    raise exception 'Sesi tidak ditemukan.';
  end if;

  if v_session_start <= now() then
    raise exception 'Sesi sudah dimulai atau sudah lewat, tidak bisa diajukan perubahan.';
  end if;

  if new.request_type = 'reschedule' then
    if v_session_start - now() < interval '6 hours' then
      raise exception 'Request reschedule harus diajukan minimal H-6 sebelum sesi.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_session_change_request_time on public.session_change_requests;
create trigger trg_check_session_change_request_time
before insert on public.session_change_requests
for each row
execute function public.check_session_change_request_time();


-- 2) Function & Trigger for booking_sessions (BEFORE UPDATE of status)
create or replace function public.check_booking_session_status_time()
returns trigger
language plpgsql
as $$
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status = 'cancelled_early' then
    if old.session_start - now() < interval '12 hours' then
      raise exception 'Pembatalan kurang dari 12 jam harus berupa cancelled_late.';
    end if;
  end if;

  if new.status = 'rescheduled' then
    if old.session_start - now() < interval '6 hours' then
      raise exception 'Reschedule kurang dari 6 jam tidak diperbolehkan.';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_booking_session_status_time on public.booking_sessions;
create trigger trg_check_booking_session_status_time
before update of status on public.booking_sessions
for each row
execute function public.check_booking_session_status_time();
