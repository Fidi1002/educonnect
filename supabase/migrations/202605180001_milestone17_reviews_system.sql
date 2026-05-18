-- 202605180001_milestone17_reviews_system.sql

create table public.tutor_reviews (
  id uuid primary key default gen_random_uuid(),
  tutor_uid uuid references public.tutors(uid) on delete cascade not null,
  student_uid uuid references public.users(uid) on delete cascade not null,
  booking_id uuid references public.bookings(id) on delete set null,
  rating numeric not null check (rating >= 1 and rating <= 5),
  review_text text not null default '',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.tutor_reviews enable row level security;

create policy "Reviews are viewable by everyone" 
  on public.tutor_reviews for select 
  using (true);

create policy "Students can insert their own reviews" 
  on public.tutor_reviews for insert 
  with check (auth.uid() = student_uid);

create policy "Students can update their own reviews"
  on public.tutor_reviews for update
  using (auth.uid() = student_uid);

-- Trigger to update tutor's rating
create or replace function public.handle_tutor_review_insert_or_update()
returns trigger
language plpgsql security definer
as $$
declare
  v_avg_rating numeric;
  v_total_reviews integer;
  v_target_tutor uuid;
begin
  if tg_op = 'DELETE' then
    v_target_tutor := old.tutor_uid;
  else
    v_target_tutor := new.tutor_uid;
  end if;

  select count(*), coalesce(avg(rating), 0)
  into v_total_reviews, v_avg_rating
  from public.tutor_reviews
  where tutor_uid = v_target_tutor;

  update public.tutors
  set rating = v_avg_rating,
      total_reviews = v_total_reviews,
      updated_at = timezone('utc'::text, now())
  where uid = v_target_tutor;

  if tg_op = 'DELETE' then
    return old;
  else
    return new;
  end if;
end;
$$;

create trigger on_tutor_review_changed
  after insert or update or delete on public.tutor_reviews
  for each row execute procedure public.handle_tutor_review_insert_or_update();
