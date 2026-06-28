-- Migration to introduce database webhook trigger for dispatching pending push notifications

-- 1. Ensure pg_net extension is enabled
create extension if not exists pg_net with schema extensions;

-- 2. Create trigger function to make HTTP POST request to dispatch-push Edge Function
create or replace function public.trigger_push_dispatch()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_url text;
begin
  v_url := coalesce(
    current_setting('app.settings.supabase_url', true),
    'https://vkhmleulohwavtdvkwdb.supabase.co'
  ) || '/functions/v1/dispatch-push';

  perform net.http_post(
    url := v_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  return new;
end;
$$;

-- 3. Create AFTER INSERT trigger on push_delivery_queue FOR EACH STATEMENT
drop trigger if exists trg_push_dispatch on public.push_delivery_queue;
create trigger trg_push_dispatch
after insert on public.push_delivery_queue
for each statement
execute function public.trigger_push_dispatch();
