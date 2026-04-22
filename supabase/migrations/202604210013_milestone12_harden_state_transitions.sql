-- Milestone week 12 - Harden booking/payment/session state transitions

-- 1) Guard booking status transitions at database layer.
create or replace function public.enforce_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  -- Server/admin contexts can still perform maintenance updates.
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah booking ini.';
  end if;

  -- Prevent identity fields from being modified by end users.
  if new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.subject <> old.subject
    or new.session_start <> old.session_start
    or new.session_end <> old.session_end
    or new.package_months <> old.package_months
    or new.sessions_per_week <> old.sessions_per_week
    or new.weekly_schedule <> old.weekly_schedule
    or new.package_start_date <> old.package_start_date
    or new.package_end_date <> old.package_end_date then
    raise exception 'Field inti booking tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status = 'pending' and new.status in ('awaiting_payment', 'rejected') then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa memproses permintaan booking.';
    end if;
    return new;
  end if;

  if old.status = 'awaiting_payment' and new.status = 'paid' then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa membayar booking.';
    end if;
    if new.paid_at is null then
      raise exception 'paid_at wajib diisi saat status paid.';
    end if;
    return new;
  end if;

  if old.status = 'paid' and new.status = 'completed' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menyelesaikan booking.';
    end if;
    return new;
  end if;

  if old.status in ('pending', 'awaiting_payment', 'paid') and new.status = 'cancelled' then
    return new;
  end if;

  raise exception 'Transisi status booking tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

drop trigger if exists trg_bookings_enforce_status_transition on public.bookings;
create trigger trg_bookings_enforce_status_transition
before update on public.bookings
for each row
execute function public.enforce_booking_status_transition();

-- 2) Guard transaction/payment transitions.
create or replace function public.enforce_transaction_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah transaksi ini.';
  end if;

  if new.booking_id <> old.booking_id
    or new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.amount <> old.amount
    or new.cycle_number <> old.cycle_number
    or coalesce(new.due_at, 'epoch'::timestamptz) <> coalesce(old.due_at, 'epoch'::timestamptz) then
    raise exception 'Field inti transaksi tidak boleh diubah.';
  end if;

  if new.payment_status = old.payment_status then
    return new;
  end if;

  if old.payment_status = 'pending' and new.payment_status in ('paid', 'failed') then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa memproses pembayaran.';
    end if;
    if new.payment_status = 'paid' and (new.paid_at is null or coalesce(new.payment_ref, '') = '') then
      raise exception 'paid_at dan payment_ref wajib saat transaksi paid.';
    end if;
    return new;
  end if;

  if old.payment_status = 'paid' and new.payment_status = 'refunded' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai refund.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status transaksi tidak diizinkan: % -> %', old.payment_status, new.payment_status;
end;
$$;

drop trigger if exists trg_transactions_enforce_status_transition on public.transactions;
create trigger trg_transactions_enforce_status_transition
before update on public.transactions
for each row
execute function public.enforce_transaction_status_transition();

-- 3) Guard booking session transitions.
create or replace function public.enforce_booking_session_status_transition()
returns trigger
language plpgsql
as $$
declare
  actor_uid uuid := auth.uid();
begin
  if actor_uid is null then
    return new;
  end if;

  if actor_uid <> old.student_uid and actor_uid <> old.tutor_uid then
    raise exception 'Tidak berhak mengubah sesi ini.';
  end if;

  if new.booking_id <> old.booking_id
    or new.student_uid <> old.student_uid
    or new.tutor_uid <> old.tutor_uid
    or new.session_start <> old.session_start
    or new.session_end <> old.session_end then
    raise exception 'Field inti sesi tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'done_pending_confirmation' then
    if actor_uid <> old.tutor_uid then
      raise exception 'Hanya tutor yang bisa menandai sesi selesai.';
    end if;
    if new.tutor_marked_done_at is null then
      raise exception 'tutor_marked_done_at wajib diisi.';
    end if;
    return new;
  end if;

  if old.status = 'done_pending_confirmation' and new.status in ('confirmed', 'disputed') then
    if actor_uid <> old.student_uid then
      raise exception 'Hanya murid yang bisa konfirmasi/dispute sesi.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status in ('cancelled_early', 'cancelled_late') then
    if new.cancelled_by_role not in ('student', 'tutor') then
      raise exception 'cancelled_by_role wajib valid.';
    end if;
    return new;
  end if;

  if old.status = 'scheduled' and new.status = 'rescheduled' then
    if new.rescheduled_to_session_id is null then
      raise exception 'rescheduled_to_session_id wajib diisi.';
    end if;
    return new;
  end if;

  raise exception 'Transisi status sesi tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

drop trigger if exists trg_booking_sessions_enforce_status_transition on public.booking_sessions;
create trigger trg_booking_sessions_enforce_status_transition
before update on public.booking_sessions
for each row
execute function public.enforce_booking_session_status_transition();

-- 4) Validate session change request creation and transitions.
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

  return new;
end;
$$;

drop trigger if exists trg_session_change_requests_validate_insert on public.session_change_requests;
create trigger trg_session_change_requests_validate_insert
before insert on public.session_change_requests
for each row
execute function public.validate_session_change_request_insert();

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
    or coalesce(new.proposed_end, 'epoch'::timestamptz) <> coalesce(old.proposed_end, 'epoch'::timestamptz) then
    raise exception 'Field inti request tidak boleh diubah.';
  end if;

  if new.status = old.status then
    return new;
  end if;

  if old.status <> 'pending' then
    raise exception 'Hanya request pending yang dapat diubah.';
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

  raise exception 'Transisi status request tidak diizinkan: % -> %', old.status, new.status;
end;
$$;

drop trigger if exists trg_session_change_requests_enforce_transition on public.session_change_requests;
create trigger trg_session_change_requests_enforce_transition
before update on public.session_change_requests
for each row
execute function public.enforce_session_change_request_transition();

-- 5) Prevent more than one pending change request per session.
create unique index if not exists idx_session_change_requests_one_pending_per_session
  on public.session_change_requests (session_id)
  where status = 'pending';
