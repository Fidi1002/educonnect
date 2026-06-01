-- Migration: Security Hardening & RLS Audit Fixes for Ebooks, Sessions, and Transactions
-- Created at: 2026-05-28

-- 1. Tighten storage policies for ebooks bucket to ensure folder ownership matching tutor UID
drop policy if exists "Tutors can upload ebook files" on storage.objects;
drop policy if exists "Tutors can update their ebook files" on storage.objects;
drop policy if exists "Tutors can delete their ebook files" on storage.objects;

create policy "Tutors can upload ebook files"
  on storage.objects for insert
  with check (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Tutors can update their ebook files"
  on storage.objects for update
  using (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Tutors can delete their ebook files"
  on storage.objects for delete
  using (
    bucket_id = 'ebooks' 
    and auth.uid() is not null
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2. Restrict booking_sessions insert policy to ensure sessions can only be created for bookings that are paid
drop policy if exists booking_sessions_insert_owner on public.booking_sessions;

create policy booking_sessions_insert_owner
  on public.booking_sessions
  for insert
  with check (
    (auth.uid() = student_uid or auth.uid() = tutor_uid)
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id
        and b.status = 'paid'
    )
  );

-- 3. Remove direct client-side INSERT on transactions
drop policy if exists transactions_insert_student_or_tutor on public.transactions;

-- 4. Secure transactions UPDATE policy to prevent unauthorized payment status modification (only allow transition to pending or keeping status unchanged)
drop policy if exists transactions_update_student_or_tutor on public.transactions;

create policy transactions_update_student_or_tutor
  on public.transactions
  for update
  using (
    (auth.uid() = student_uid or auth.uid() = tutor_uid)
    and (payment_status = 'pending' or payment_status = 'none')
  )
  with check (
    (auth.uid() = student_uid or auth.uid() = tutor_uid)
    and payment_status = 'pending'
  );
