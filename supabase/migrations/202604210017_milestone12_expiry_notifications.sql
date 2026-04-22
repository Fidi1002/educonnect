-- Milestone week 12.4 - Auto in-app notifications for expired session-change requests
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
  expired_row record;
begin
  for expired_row in
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
      )
    returning scr.id, scr.requester_uid, scr.target_uid, scr.session_id
  loop
    affected_count := affected_count + 1;

    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    )
    values (
      expired_row.requester_uid,
      expired_row.target_uid,
      'session_change',
      'Request Kedaluwarsa',
      'Permintaan perubahan sesi kedaluwarsa karena tidak direspons dalam 24 jam.',
      'booking_session',
      expired_row.session_id::text,
      false
    );

    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id,
      is_read
    )
    values (
      expired_row.target_uid,
      expired_row.requester_uid,
      'session_change',
      'Request Kedaluwarsa',
      'Permintaan perubahan sesi otomatis ditutup karena melewati batas respons.',
      'booking_session',
      expired_row.session_id::text,
      false
    );
  end loop;

  return affected_count;
end;
$$;
