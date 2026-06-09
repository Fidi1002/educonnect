-- Supabase Migration: Double Booking Prevention
-- Ensure tutors cannot have overlapping booking sessions.

create or replace function public.prevent_double_booking()
returns trigger
language plpgsql
as $$
begin
  if new.status in ('cancelled_by_student', 'cancelled_by_tutor', 'cancelled_early', 'cancelled_late', 'rescheduled') then
    return new;
  end if;

  if exists (
    select 1 from public.booking_sessions s
    where s.tutor_uid = new.tutor_uid
      and s.id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
      and s.status not in ('cancelled_by_student', 'cancelled_by_tutor', 'cancelled_early', 'cancelled_late', 'rescheduled')
      and s.session_start < new.session_end
      and s.session_end > new.session_start
  ) then
    raise exception 'Tutor sudah memiliki sesi lain yang tumpang tindih pada waktu tersebut.';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_prevent_double_booking on public.booking_sessions;
create trigger trg_prevent_double_booking
before insert or update of session_start, session_end, status on public.booking_sessions
for each row
execute function public.prevent_double_booking();
