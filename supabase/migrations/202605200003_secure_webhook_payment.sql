-- Migration to introduce secure simulated webhook payment confirmation and deprecate direct dummy payments.

-- 1. Deprecate and revoke direct execution permissions on the old client-triggered RPC
revoke execute on function public.complete_dummy_booking_payment(uuid) from public, authenticated;

-- 2. Create the secure simulated webhook handler
create or replace function public.handle_secure_webhook_payment(
  p_booking_id uuid,
  p_payment_method text,
  p_signature_key text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expected_signature text;
  booking_row public.bookings%rowtype;
  tx_row public.transactions%rowtype;
  now_utc timestamptz := now();
begin
  -- Secure validation: Verify signature using a mock server secret key (simulating Midtrans signature logic)
  v_expected_signature := md5(p_booking_id::text || 'EDUCONNECT_SECRET_SERVER_KEY');
  
  if p_signature_key <> v_expected_signature then
    return jsonb_build_object(
      'success', false,
      'message', 'Tanda tangan transaksi (Signature Key) tidak valid. Akses ditolak.'
    );
  end if;

  -- Locate the targeted booking
  select *
  into booking_row
  from public.bookings b
  where b.id = p_booking_id;

  if not found then
    return jsonb_build_object(
      'success', false,
      'message', 'Booking tidak ditemukan.'
    );
  end if;

  -- Ensure booking is in a state ready to accept payment
  if booking_row.status <> 'awaiting_payment' then
    return jsonb_build_object(
      'success', false,
      'message', 'Booking tidak sedang menunggu pembayaran.'
    );
  end if;

  -- Find the active pending billing transaction
  select *
  into tx_row
  from public.transactions t
  where t.booking_id = p_booking_id
    and t.payment_status = 'pending'
  order by t.cycle_number asc
  limit 1;

  if not found then
    return jsonb_build_object(
      'success', false,
      'message', 'Tidak ada tagihan aktif yang perlu dibayar.'
    );
  end if;

  -- Update booking state to paid
  update public.bookings
  set status = 'paid',
      paid_at = now_utc,
      total_amount = coalesce(tx_row.amount, 0),
      updated_at = now_utc
  where id = p_booking_id;

  -- Update transaction state to paid with a proper gateway transaction reference prefix
  update public.transactions
  set payment_method = p_payment_method,
      payment_status = 'paid',
      payment_ref = 'PAY-' || upper(p_payment_method) || '-' || extract(epoch from clock_timestamp())::bigint,
      paid_at = now_utc,
      updated_at = now_utc
  where id = tx_row.id;

  -- Return successful state with all details required to generate learning sessions (analogous to the old RPC payload)
  return jsonb_build_object(
    'success', true,
    'message', 'Pembayaran berhasil diverifikasi secara aman via Webhook Server-to-Server.',
    'student_uid', booking_row.student_uid,
    'tutor_uid', booking_row.tutor_uid,
    'duration_minutes', booking_row.duration_minutes,
    'package_start_date', booking_row.package_start_date,
    'package_end_date', booking_row.package_end_date,
    'weekly_schedule', booking_row.weekly_schedule
  );
end;
$$;

-- Grant execution to authenticated users (they can invoke the simulated gateway webhook trigger, but it will only succeed with a valid signature key)
grant execute on function public.handle_secure_webhook_payment(uuid, text, text) to authenticated;
