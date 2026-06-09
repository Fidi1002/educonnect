-- Automate payout request approvals for verified tutors and amounts < Rp 2,000,000
create or replace function public.auto_approve_payout_requests()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_verification_status text;
begin
  -- Fetch tutor verification status
  select verification_status into v_verification_status
  from public.tutors
  where uid = new.tutor_uid;

  -- Auto-approve if amount is under 2,000,000 (Rp 2.000.000) and tutor is approved
  if v_verification_status = 'approved' and new.amount < 2000000 then
    update public.payout_requests
    set status = 'completed'
    where id = new.id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_auto_approve_payout_requests on public.payout_requests;
create trigger trg_auto_approve_payout_requests
  after insert
  on public.payout_requests
  for each row
  execute function public.auto_approve_payout_requests();
