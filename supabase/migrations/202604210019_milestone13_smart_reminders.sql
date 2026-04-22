-- Milestone week 13.1 - Smart reminders H-24 and H-2 + student attendance confirmation
alter table public.booking_sessions
  add column if not exists student_presence_confirmed_at timestamptz,
  add column if not exists reminder_h24_sent_at timestamptz,
  add column if not exists reminder_h2_sent_at timestamptz;

create index if not exists idx_booking_sessions_student_upcoming
  on public.booking_sessions (student_uid, session_start asc, status);

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
    select bs.id, bs.tutor_uid, 'h24'::text as reminder_type
    from public.booking_sessions bs
    where bs.student_uid = p_student_uid
      and bs.status = 'scheduled'
      and bs.session_start > now()
      and bs.session_start <= now() + interval '24 hours'
      and bs.session_start > now() + interval '23 hours'
      and bs.reminder_h24_sent_at is null
    union all
    select bs.id, bs.tutor_uid, 'h2'::text as reminder_type
    from public.booking_sessions bs
    where bs.student_uid = p_student_uid
      and bs.status = 'scheduled'
      and bs.session_start > now()
      and bs.session_start <= now() + interval '2 hours'
      and bs.session_start > now() + interval '1 hour'
      and bs.reminder_h2_sent_at is null
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
      p_student_uid,
      item.tutor_uid,
      'reminder',
      case when item.reminder_type = 'h24' then 'Reminder Kelas Besok' else 'Reminder Kelas 2 Jam Lagi' end,
      case when item.reminder_type = 'h24'
        then 'Sesi akan dimulai dalam 24 jam. Jangan lupa konfirmasi hadir.'
        else 'Sesi akan dimulai dalam 2 jam. Siapkan materi belajar ya.'
      end,
      'booking_session',
      item.id::text,
      false
    );

    if item.reminder_type = 'h24' then
      update public.booking_sessions
      set reminder_h24_sent_at = now(), updated_at = now()
      where id = item.id;
    else
      update public.booking_sessions
      set reminder_h2_sent_at = now(), updated_at = now()
      where id = item.id;
    end if;

    sent_count := sent_count + 1;
  end loop;

  return sent_count;
end;
$$;

revoke all on function public.process_student_session_reminders(uuid) from public;
grant execute on function public.process_student_session_reminders(uuid) to authenticated;
