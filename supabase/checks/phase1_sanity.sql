-- Phase 1 sanity checks (run in Supabase SQL Editor)

-- 1) Core objects exist
select table_name
from information_schema.tables
where table_schema = 'public' and table_name in ('users', 'tutors')
order by table_name;

select routine_name
from information_schema.routines
where routine_schema = 'public' and routine_name = 'get_nearby_tutors';

-- 2) RLS enabled
select relname as table_name, relrowsecurity as rls_enabled
from pg_class
where relname in ('users', 'tutors') and relkind = 'r';

-- 3) Policies exist
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname in ('public', 'storage')
  and (
    tablename in ('users', 'tutors')
    or (schemaname = 'storage' and tablename = 'objects')
  )
order by schemaname, tablename, policyname;

-- 4) Storage bucket exists
select id, name, public
from storage.buckets
where id = 'tutor-photos';

-- 5) Nearby function smoke test (adjust coordinates)
select *
from public.get_nearby_tutors(
  p_latitude => -6.200000,
  p_longitude => 106.816666,
  p_radius_km => 5,
  p_limit => 20
)
limit 5;
