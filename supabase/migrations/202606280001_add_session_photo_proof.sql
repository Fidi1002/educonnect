-- Add session_photo_url column to booking_sessions table
alter table public.booking_sessions add column if not exists session_photo_url text;

-- Register the session-proofs storage bucket
insert into storage.buckets (id, name, public)
values ('session-proofs', 'session-proofs', true)
on conflict (id) do nothing;

-- Create policies for storage objects under session-proofs bucket
drop policy if exists "Session proofs are publicly readable" on storage.objects;
create policy "Session proofs are publicly readable"
  on storage.objects for select
  using (bucket_id = 'session-proofs');

drop policy if exists "Tutors can upload session proofs" on storage.objects;
create policy "Tutors can upload session proofs"
  on storage.objects for insert
  with check (bucket_id = 'session-proofs' and auth.role() = 'authenticated');
