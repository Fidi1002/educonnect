-- Fix ambiguous column reference in complete_dummy_booking_payment RPC

create or replace function public.complete_dummy_booking_payment(
  p_booking_id uuid
)
returns table(
  student_uid uuid,
  tutor_uid uuid,
  duration_minutes integer,
  package_start_date date,
  package_end_date date,
  weekly_schedule jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_uid uuid := auth.uid();
  booking_row public.bookings%rowtype;
  tx_row public.transactions%rowtype;
  now_utc timestamptz := now();
begin
  if actor_uid is null then
    raise exception 'User belum login.';
  end if;

  perform public.expire_stale_bookings(p_booking_id);

  select *
  into booking_row
  from public.bookings b
  where b.id = p_booking_id;

  if not found then
    raise exception 'Booking tidak ditemukan.';
  end if;

  if booking_row.student_uid <> actor_uid then
    raise exception 'Booking ini bukan milik kamu.';
  end if;

  if booking_row.status <> 'awaiting_payment' then
    raise exception 'Booking belum siap dibayar atau sudah diproses.';
  end if;

  select *
  into tx_row
  from public.transactions t
  where t.booking_id = p_booking_id
    and t.student_uid = actor_uid
    and t.payment_status = 'pending'
  order by t.cycle_number asc
  limit 1;

  if not found then
    raise exception 'Tidak ada tagihan aktif yang perlu dibayar.';
  end if;

  update public.bookings
  set status = 'paid',
      paid_at = now_utc,
      total_amount = coalesce(tx_row.amount, 0),
      updated_at = now_utc
  where id = p_booking_id;

  update public.transactions
  set payment_method = 'dummy',
      payment_status = 'paid',
      payment_ref = 'DUMMY-' || extract(epoch from clock_timestamp())::bigint,
      paid_at = now_utc,
      updated_at = now_utc
  where id = tx_row.id;

  return query
  select
    booking_row.student_uid,
    booking_row.tutor_uid,
    booking_row.duration_minutes,
    booking_row.package_start_date,
    booking_row.package_end_date,
    booking_row.weekly_schedule;
end;
$$;

revoke all on function public.complete_dummy_booking_payment(uuid) from public;
grant execute on function public.complete_dummy_booking_payment(uuid) to authenticated;
