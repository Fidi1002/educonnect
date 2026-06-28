-- Enforce that each booking can only have one review
alter table public.tutor_reviews add constraint tutor_reviews_booking_id_key unique (booking_id);
