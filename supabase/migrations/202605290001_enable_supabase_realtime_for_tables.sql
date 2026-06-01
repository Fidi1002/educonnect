-- Enable Realtime by adding tables to supabase_realtime publication
-- This ensures that insertions, updates, and deletions on streamed tables are broadcasted in real-time to the clients.

do $$
begin
  -- messages
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;

  -- users
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'users'
  ) then
    alter publication supabase_realtime add table public.users;
  end if;

  -- tutors
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'tutors'
  ) then
    alter publication supabase_realtime add table public.tutors;
  end if;

  -- bookings
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'bookings'
  ) then
    alter publication supabase_realtime add table public.bookings;
  end if;

  -- app_notifications
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'app_notifications'
  ) then
    alter publication supabase_realtime add table public.app_notifications;
  end if;

  -- tutor_availability
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'tutor_availability'
  ) then
    alter publication supabase_realtime add table public.tutor_availability;
  end if;

  -- tutor_wallets
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'tutor_wallets'
  ) then
    alter publication supabase_realtime add table public.tutor_wallets;
  end if;

  -- payout_requests
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'payout_requests'
  ) then
    alter publication supabase_realtime add table public.payout_requests;
  end if;

  -- wallet_transactions
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'wallet_transactions'
  ) then
    alter publication supabase_realtime add table public.wallet_transactions;
  end if;

  -- booking_sessions
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'booking_sessions'
  ) then
    alter publication supabase_realtime add table public.booking_sessions;
  end if;

  -- tutor_reviews
  if not exists (
    select 1 from pg_publication_rel pr 
    join pg_class c on pr.prrelid = c.oid 
    join pg_publication p on pr.prpubid = p.oid 
    where p.pubname = 'supabase_realtime' and c.relname = 'tutor_reviews'
  ) then
    alter publication supabase_realtime add table public.tutor_reviews;
  end if;
end $$;
