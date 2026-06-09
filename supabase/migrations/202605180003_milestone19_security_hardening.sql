-- Milestone week 19 - Security Hardening & RLS Audit Fixes
-- Relax SELECT policy on public.users so authenticated users can view each other's profile metadata (e.g. name, photo_url, role)
-- This is critical for features like Student Roster, Chat Inbox, and Reviews to display actual student/tutor profiles.

drop policy if exists users_select_own on public.users;
drop policy if exists users_select_all_auth on public.users;

create policy users_select_all_auth
on public.users
for select
to authenticated
using (
  auth.uid() = uid
  or role = 'tutor'
  or exists (
    select 1 from public.bookings b
    where (b.student_uid = auth.uid() and b.tutor_uid = uid)
       or (b.tutor_uid = auth.uid() and b.student_uid = uid)
  )
);
