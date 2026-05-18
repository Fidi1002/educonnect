-- 202605180002_milestone18_ebook_library.sql

-- 1. Create table library_ebooks
create table public.library_ebooks (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid references public.tutors(uid) on delete cascade not null,
  title text not null,
  description text not null default '',
  file_url text not null,
  file_size_mb numeric not null default 0,
  format text not null default 'PDF',
  accent_color_hex text not null default '#4B176E',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.library_ebooks enable row level security;

create policy "Ebooks are viewable by everyone" 
  on public.library_ebooks for select 
  using (true);

create policy "Tutors can insert their own ebooks" 
  on public.library_ebooks for insert 
  with check (auth.uid() = tutor_uid);

create policy "Tutors can update their own ebooks"
  on public.library_ebooks for update
  using (auth.uid() = tutor_uid);

create policy "Tutors can delete their own ebooks"
  on public.library_ebooks for delete
  using (auth.uid() = tutor_uid);

-- 2. Create Storage Bucket for Ebooks
insert into storage.buckets (id, name, public) 
values ('ebooks', 'ebooks', true)
on conflict do nothing;

-- 3. Storage Policies
create policy "Ebook files are publicly accessible"
  on storage.objects for select
  using ( bucket_id = 'ebooks' );

create policy "Tutors can upload ebook files"
  on storage.objects for insert
  with check (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );

create policy "Tutors can update their ebook files"
  on storage.objects for update
  using (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );

create policy "Tutors can delete their ebook files"
  on storage.objects for delete
  using (
    bucket_id = 'ebooks' 
    and auth.role() = 'authenticated'
  );
