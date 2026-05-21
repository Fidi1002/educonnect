-- Migration for Tutor Verification & Curation System
alter table public.tutors 
add column if not exists verification_status text not null default 'none' check (verification_status in ('none', 'pending', 'approved', 'rejected')),
add column if not exists identity_card_url text,
add column if not exists certificate_url text,
add column if not exists rejection_reason text;

-- Create storage bucket for tutor documents if not exists
insert into storage.buckets (id, name, public)
values ('tutor-documents', 'tutor-documents', false) -- Private bucket for secure document storage
on conflict (id) do nothing;

-- RLS policies for tutor-documents storage bucket
drop policy if exists tutor_docs_select_own on storage.objects;
create policy tutor_docs_select_own
on storage.objects
for select
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_insert_own on storage.objects;
create policy tutor_docs_insert_own
on storage.objects
for insert
with check (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_update_own on storage.objects;
create policy tutor_docs_update_own
on storage.objects
for update
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists tutor_docs_delete_own on storage.objects;
create policy tutor_docs_delete_own
on storage.objects
for delete
using (
  bucket_id = 'tutor-documents'
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text
);
