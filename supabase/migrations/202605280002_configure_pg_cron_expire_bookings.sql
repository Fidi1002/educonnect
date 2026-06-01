-- Supabase Migration: Configure pg_cron for expire_stale_bookings
-- Schedule a cron job to call public.expire_stale_bookings() every hour.

do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    begin
      -- Remove existing job if any to ensure clean schedule update
      if exists (
        select 1
        from cron.job
        where jobname = 'educonnect-expire-stale-bookings'
      ) then
        perform cron.unschedule('educonnect-expire-stale-bookings');
      end if;

      perform cron.schedule(
        'educonnect-expire-stale-bookings',
        '0 * * * *', -- Every hour
        $cron$select public.expire_stale_bookings();$cron$
      );
    exception
      when undefined_table then
        -- pg_cron is not enabled or accessible in this context
        raise warning 'pg_cron extension table not accessible, skipping job scheduling';
    end;
  else
    raise warning 'pg_cron extension not found, skipping job scheduling';
  end if;
end;
$$;
