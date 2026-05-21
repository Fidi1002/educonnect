-- Migration to fix Celah Kedua: Wallet Revenue Integration
-- Automatically credit the tutor's wallet when a booking session transitions to a payable status.

create or replace function public.process_tutor_session_payment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_price_per_hour numeric;
  v_duration_minutes numeric;
  v_session_cost numeric;
  v_payout_amount numeric;
  v_description text;
  v_is_payable boolean := false;
  v_transaction_type text := 'credit';
begin
  -- 1. Check if the status transitioned to a payable status
  -- Payable statuses: 'confirmed', 'disputed_resolved', 'student_no_show', 'cancelled_late' (if cancelled by student)
  if (new.status = 'confirmed' and (old.status is null or old.status <> 'confirmed')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout
    v_description := 'Pendapatan sesi les selesai & dikonfirmasi';
  elsif (new.status = 'disputed_resolved' and (old.status is null or old.status <> 'disputed_resolved')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout (dispute resolved in tutor favor)
    v_description := 'Pendapatan sesi les (dispute selesai)';
  elsif (new.status = 'student_no_show' and (old.status is null or old.status <> 'student_no_show')) then
    v_is_payable := true;
    v_payout_amount := 1.0; -- 100% payout (murid tidak hadir)
    v_description := 'Kompensasi penuh (murid tidak hadir/no-show)';
  elsif (new.status = 'cancelled_late' and (old.status is null or old.status <> 'cancelled_late') and new.cancelled_by_role = 'student') then
    v_is_payable := true;
    v_payout_amount := 0.5; -- 50% late cancellation compensation by student
    v_description := 'Kompensasi pembatalan terlambat oleh murid (50%)';
  end if;

  if not v_is_payable then
    return new;
  end if;

  -- 2. Fetch tutor's price_per_hour
  select price_per_hour into v_price_per_hour
  from public.tutors
  where uid = new.tutor_uid;

  if v_price_per_hour is null or v_price_per_hour <= 0 then
    -- If tutor rate is not set, we cannot calculate payment. Do not raise error to avoid blocking transaction.
    return new;
  end if;

  -- 3. Calculate session duration in minutes
  v_duration_minutes := round(extract(epoch from (new.session_end - new.session_start)) / 60.0);
  if v_duration_minutes <= 0 then
    return new;
  end if;

  -- 4. Calculate net credit cost matching Flutter's rounding logic
  v_session_cost := round(((v_price_per_hour * v_duration_minutes) / 60.0) * v_payout_amount);

  if v_session_cost <= 0 then
    return new;
  end if;

  -- 5. Ensure tutor wallet row exists
  perform public.ensure_tutor_wallet_row(new.tutor_uid);

  -- 6. Update tutor's wallet balance
  update public.tutor_wallets
  set
    available_balance = available_balance + v_session_cost,
    total_earned = total_earned + v_session_cost,
    updated_at = now()
  where tutor_uid = new.tutor_uid;

  -- 7. Record transaction history in wallet_transactions
  insert into public.wallet_transactions (
    tutor_uid,
    amount,
    type,
    description,
    reference_type,
    reference_id
  )
  values (
    new.tutor_uid,
    v_session_cost,
    v_transaction_type,
    v_description,
    'booking_session',
    new.id::text
  );

  return new;
end;
$$;

-- Create trigger on booking_sessions
drop trigger if exists trg_booking_sessions_process_payment on public.booking_sessions;
create trigger trg_booking_sessions_process_payment
after update on public.booking_sessions
for each row
execute function public.process_tutor_session_payment();
