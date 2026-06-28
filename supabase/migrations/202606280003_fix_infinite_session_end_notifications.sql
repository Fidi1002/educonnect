-- Fix infinite looping session end notifications caused by category mismatch in the check condition
create or replace function public.check_and_trigger_session_end_notifications()
returns void
language plpgsql
security definer
as $$
declare
  item record;
  now_utc timestamp with time zone := now();
begin
  for item in
    select bs.id, bs.tutor_uid, bs.student_uid, b.subject
    from public.booking_sessions bs
    join public.bookings b on b.id = bs.booking_id
    where bs.status = 'scheduled'
      and bs.session_end < now_utc
      and not exists (
        select 1 from public.app_notifications
        where target_id = bs.id::text
          and title = 'Sesi Belajar Telah Berakhir'
      )
  loop
    -- Send notification to tutor to validate presence
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
      item.tutor_uid,
      item.student_uid,
      'session_change',
      'Sesi Belajar Telah Berakhir',
      'Sesi pelajaran ' || item.subject || ' telah selesai. Silakan lakukan validasi kehadiran agar dapat mengirimkan materi/PR.',
      'booking_session',
      item.id::text,
      false
    );

    -- Send notification to student to wait/confirm
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
      item.student_uid,
      item.tutor_uid,
      'session_change',
      'Sesi Belajar Telah Berakhir',
      'Sesi pelajaran ' || item.subject || ' telah selesai. Harap tunggu tutor memvalidasi kehadiran.',
      'booking_session',
      item.id::text,
      false
    );
  end loop;
end;
$$;
