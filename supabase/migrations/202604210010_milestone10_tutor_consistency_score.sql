-- Milestone week 10 - Tutor consistency score columns
alter table public.tutors
  add column if not exists consistency_score numeric not null default 0,
  add column if not exists attendance_rate numeric not null default 0,
  add column if not exists on_time_rate numeric not null default 0,
  add column if not exists cancellation_rate numeric not null default 0;
