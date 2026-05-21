-- Milestone 20 - Wallet and payout foundation
--
-- NOTE:
-- This migration originally only added `rejection_reason` to `payout_requests`.
-- In practice, the base wallet tables were missing in some environments, so the
-- migration now bootstraps the wallet schema safely before applying that field.

create table if not exists public.tutor_wallets (
  tutor_uid uuid primary key references public.tutors(uid) on delete cascade,
  available_balance numeric not null default 0 check (available_balance >= 0),
  pending_balance numeric not null default 0 check (pending_balance >= 0),
  total_earned numeric not null default 0 check (total_earned >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null check (amount > 0),
  type text not null check (type in ('credit', 'debit')),
  description text not null default '',
  reference_type text not null default '',
  reference_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.payout_requests (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid not null references public.tutors(uid) on delete cascade,
  amount numeric not null check (amount > 0),
  bank_name text not null default '',
  account_number text not null default '',
  account_holder text not null default '',
  status text not null default 'pending' check (
    status in ('pending', 'approved', 'rejected', 'completed')
  ),
  rejection_reason text,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.payout_requests
  add column if not exists rejection_reason text;

create index if not exists idx_wallet_transactions_tutor_created
  on public.wallet_transactions (tutor_uid, created_at desc);

create index if not exists idx_payout_requests_tutor_created
  on public.payout_requests (tutor_uid, created_at desc);

drop trigger if exists trg_tutor_wallets_touch_updated_at on public.tutor_wallets;
create trigger trg_tutor_wallets_touch_updated_at
before update on public.tutor_wallets
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_payout_requests_touch_updated_at on public.payout_requests;
create trigger trg_payout_requests_touch_updated_at
before update on public.payout_requests
for each row
execute function public.touch_updated_at();

create or replace function public.ensure_tutor_wallet_row(p_tutor_uid uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.tutor_wallets (tutor_uid)
  values (p_tutor_uid)
  on conflict (tutor_uid) do nothing;
end;
$$;

create or replace function public.request_tutor_payout(
  p_tutor_uid uuid,
  p_amount numeric,
  p_bank_name text,
  p_account_number text,
  p_account_holder text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  wallet_row public.tutor_wallets%rowtype;
  payout_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Anda harus login untuk mengajukan payout.';
  end if;

  if auth.uid() <> p_tutor_uid then
    raise exception 'Anda tidak berhak mengajukan payout untuk tutor lain.';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'Jumlah payout tidak valid.';
  end if;

  if coalesce(trim(p_bank_name), '') = ''
    or coalesce(trim(p_account_number), '') = ''
    or coalesce(trim(p_account_holder), '') = '' then
    raise exception 'Informasi rekening payout wajib lengkap.';
  end if;

  perform public.ensure_tutor_wallet_row(p_tutor_uid);

  select *
  into wallet_row
  from public.tutor_wallets
  where tutor_uid = p_tutor_uid
  for update;

  if wallet_row.available_balance < p_amount then
    raise exception 'Saldo tersedia tidak mencukupi untuk payout ini.';
  end if;

  insert into public.payout_requests (
    tutor_uid,
    amount,
    bank_name,
    account_number,
    account_holder,
    status
  )
  values (
    p_tutor_uid,
    p_amount,
    trim(p_bank_name),
    trim(p_account_number),
    trim(p_account_holder),
    'pending'
  )
  returning id into payout_id;

  update public.tutor_wallets
  set
    available_balance = available_balance - p_amount,
    pending_balance = pending_balance + p_amount
  where tutor_uid = p_tutor_uid;

  insert into public.wallet_transactions (
    tutor_uid,
    amount,
    type,
    description,
    reference_type,
    reference_id
  )
  values (
    p_tutor_uid,
    p_amount,
    'debit',
    'Permintaan payout diajukan',
    'payout',
    payout_id::text
  );

  return payout_id;
end;
$$;

create or replace function public.create_wallet_for_new_tutor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.ensure_tutor_wallet_row(new.uid);
  return new;
end;
$$;

drop trigger if exists trg_tutors_create_wallet on public.tutors;
create trigger trg_tutors_create_wallet
after insert on public.tutors
for each row
execute function public.create_wallet_for_new_tutor();

insert into public.tutor_wallets (tutor_uid)
select t.uid
from public.tutors t
on conflict (tutor_uid) do nothing;

alter table public.tutor_wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.payout_requests enable row level security;

drop policy if exists tutor_wallets_select_own on public.tutor_wallets;
create policy tutor_wallets_select_own
on public.tutor_wallets
for select
using (auth.uid() = tutor_uid);

drop policy if exists wallet_transactions_select_own on public.wallet_transactions;
create policy wallet_transactions_select_own
on public.wallet_transactions
for select
using (auth.uid() = tutor_uid);

drop policy if exists payout_requests_select_own on public.payout_requests;
create policy payout_requests_select_own
on public.payout_requests
for select
using (auth.uid() = tutor_uid);

drop policy if exists payout_requests_update_own on public.payout_requests;
create policy payout_requests_update_own
on public.payout_requests
for update
using (auth.uid() = tutor_uid)
with check (auth.uid() = tutor_uid);

grant execute on function public.request_tutor_payout(uuid, numeric, text, text, text)
to authenticated;

