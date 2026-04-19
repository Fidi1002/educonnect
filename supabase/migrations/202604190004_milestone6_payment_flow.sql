-- Milestone week 6 - Payment schema and status flow
alter table public.bookings
  add column if not exists total_amount numeric not null default 0,
  add column if not exists paid_at timestamptz;

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check check (
    status in (
      'pending',
      'accepted',
      'awaiting_payment',
      'paid',
      'rejected',
      'completed',
      'cancelled'
    )
  );

update public.bookings
set status = 'awaiting_payment'
where status = 'accepted';

alter table public.bookings
  drop constraint if exists bookings_status_check;

alter table public.bookings
  add constraint bookings_status_check check (
    status in (
      'pending',
      'awaiting_payment',
      'paid',
      'rejected',
      'completed',
      'cancelled'
    )
  );

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  student_uid uuid not null references public.users(uid) on delete cascade,
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null default 0,
  payment_method text not null default 'dummy',
  payment_status text not null default 'pending' check (
    payment_status in ('pending', 'paid', 'failed', 'refunded')
  ),
  payment_ref text not null default '',
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_transactions_student_created
  on public.transactions (student_uid, created_at desc);
create index if not exists idx_transactions_tutor_created
  on public.transactions (tutor_uid, created_at desc);
create index if not exists idx_transactions_status
  on public.transactions (payment_status, created_at desc);

drop trigger if exists trg_transactions_touch_updated_at on public.transactions;
create trigger trg_transactions_touch_updated_at
before update on public.transactions
for each row
execute function public.touch_updated_at();

alter table public.transactions enable row level security;

drop policy if exists transactions_select_owner on public.transactions;
create policy transactions_select_owner
on public.transactions
for select
using (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists transactions_insert_student_or_tutor on public.transactions;
create policy transactions_insert_student_or_tutor
on public.transactions
for insert
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);

drop policy if exists transactions_update_student_or_tutor on public.transactions;
create policy transactions_update_student_or_tutor
on public.transactions
for update
using (auth.uid() = student_uid or auth.uid() = tutor_uid)
with check (auth.uid() = student_uid or auth.uid() = tutor_uid);
