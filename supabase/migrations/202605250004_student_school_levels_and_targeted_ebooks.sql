-- Add school_level to public.users
alter table public.users
  add column if not exists school_level text check (school_level in ('SD', 'SMP', 'SMA'));

-- Add teaching_levels to public.tutors
alter table public.tutors
  add column if not exists teaching_levels text[] not null default '{}';

-- Add target_level to public.library_ebooks
alter table public.library_ebooks
  add column if not exists target_level text check (target_level in ('SD', 'SMP', 'SMA'));

-- Delete existing ebooks with null booking_id to allow setting not null constraint
delete from public.library_ebooks where booking_id is null;

-- Make booking_id not null
alter table public.library_ebooks
  alter column booking_id set not null;

-- Drop old select policies on library_ebooks
drop policy if exists "Ebooks are viewable by everyone" on public.library_ebooks;
drop policy if exists "Ebooks are viewable if public or linked to user's booking" on public.library_ebooks;

-- Create new RLS policy for targeted select
create policy "Ebooks are viewable by booking participants matching student school level"
  on public.library_ebooks for select
  using (
    auth.uid() = tutor_uid
    or (
      exists (
        select 1 from public.bookings b
        join public.users u on u.uid = b.student_uid
        where b.id = booking_id
          and b.student_uid = auth.uid()
          and u.school_level = target_level
      )
    )
  );
