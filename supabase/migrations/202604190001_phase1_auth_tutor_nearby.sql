-- Phase 1 schema for EduConnect on Supabase
create extension if not exists postgis;

create table if not exists public.users (
  uid uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  display_name text not null default '',
  photo_url text not null default '',
  role text not null default 'unknown' check (role in ('unknown', 'student', 'tutor')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tutors (
  uid uuid primary key references public.users(uid) on delete cascade,
  display_name text not null default '',
  photo_url text not null default '',
  bio text not null default '',
  subjects text[] not null default '{}',
  price_per_hour numeric not null default 0,
  experience_years integer not null default 0,
  experience_description text not null default '',
  location_label text not null default '',
  latitude double precision,
  longitude double precision,
  geohash text not null default '',
  rating double precision not null default 0,
  total_reviews integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  location geography(point, 4326) generated always as (
    case
      when latitude is null or longitude is null then null
      else st_setsrid(st_makepoint(longitude, latitude), 4326)::geography
    end
  ) stored
);

create index if not exists idx_tutors_active_rating on public.tutors (is_active, rating desc);
create index if not exists idx_tutors_active_price on public.tutors (is_active, price_per_hour asc);
create index if not exists idx_tutors_location on public.tutors using gist (location);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_touch_updated_at on public.users;
create trigger trg_users_touch_updated_at
before update on public.users
for each row
execute function public.touch_updated_at();

drop trigger if exists trg_tutors_touch_updated_at on public.tutors;
create trigger trg_tutors_touch_updated_at
before update on public.tutors
for each row
execute function public.touch_updated_at();

create or replace function public.get_nearby_tutors(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 250
)
returns table (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  distance_km double precision
)
language sql
stable
as $$
  select
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000 as distance_km
  from public.tutors t
  where t.is_active = true
    and t.location is not null
    and st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  order by distance_km asc
  limit greatest(coalesce(p_limit, 250), 1);
$$;

alter table public.users enable row level security;
alter table public.tutors enable row level security;

drop policy if exists users_select_own on public.users;
create policy users_select_own
on public.users
for select
using (auth.uid() = uid);

drop policy if exists users_insert_own on public.users;
create policy users_insert_own
on public.users
for insert
with check (auth.uid() = uid);

drop policy if exists users_update_own on public.users;
create policy users_update_own
on public.users
for update
using (auth.uid() = uid)
with check (auth.uid() = uid);

drop policy if exists tutors_select_authenticated on public.tutors;
create policy tutors_select_authenticated
on public.tutors
for select
using (auth.role() = 'authenticated' and (is_active = true or auth.uid() = uid));

drop policy if exists tutors_insert_own on public.tutors;
create policy tutors_insert_own
on public.tutors
for insert
with check (auth.uid() = uid);

drop policy if exists tutors_update_own on public.tutors;
create policy tutors_update_own
on public.tutors
for update
using (auth.uid() = uid)
with check (auth.uid() = uid);

insert into storage.buckets (id, name, public)
values ('tutor-photos', 'tutor-photos', true)
on conflict (id) do nothing;

drop policy if exists tutor_photos_public_read on storage.objects;
create policy tutor_photos_public_read
on storage.objects
for select
using (bucket_id = 'tutor-photos');

drop policy if exists tutor_photos_insert_own on storage.objects;
create policy tutor_photos_insert_own
on storage.objects
for insert
with check (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_photos_update_own on storage.objects;
create policy tutor_photos_update_own
on storage.objects
for update
using (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_photos_delete_own on storage.objects;
create policy tutor_photos_delete_own
on storage.objects
for delete
using (
  bucket_id = 'tutor-photos'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);
