-- Milestone week 9 - Monthly payment cycles
alter table public.transactions
  add column if not exists cycle_number integer not null default 1,
  add column if not exists due_at timestamptz;

alter table public.transactions
  drop constraint if exists transactions_booking_id_key;

create unique index if not exists idx_transactions_booking_cycle_unique
  on public.transactions (booking_id, cycle_number);

create index if not exists idx_transactions_booking_due
  on public.transactions (booking_id, due_at asc);
