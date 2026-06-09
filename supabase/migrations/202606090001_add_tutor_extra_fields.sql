-- Tambahkan kolom penunjang data diri tutor
alter table public.tutors
  add column if not exists bank_name text,
  add column if not exists bank_account_number text,
  add column if not exists languages text[] not null default '{Bahasa Indonesia}',
  add column if not exists introduction_video_url text;
