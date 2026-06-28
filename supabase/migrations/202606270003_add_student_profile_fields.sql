-- Add phone_number, address, latitude, longitude, and preferred_tutor_gender to public.users table
alter table public.users add column if not exists phone_number text;
alter table public.users add column if not exists address text;
alter table public.users add column if not exists latitude double precision;
alter table public.users add column if not exists longitude double precision;
alter table public.users add column if not exists preferred_tutor_gender text default 'any' check (preferred_tutor_gender in ('male', 'female', 'any'));
