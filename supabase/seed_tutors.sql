-- SQL Seed Script to create Tutor Users in EduConnect Supabase Database
-- Run this script in the SQL Editor on your Supabase Dashboard

-- 1. Ensure pgcrypto is enabled for password hashing
create extension if not exists pgcrypto;

-- 2. Cleanup old seed data to prevent duplicates
delete from auth.users 
where email in (
  'budi.tutor@educonnect.com', 
  'siti.tutor@educonnect.com', 
  'andi.tutor@educonnect.com', 
  'citra.tutor@educonnect.com', 
  'john.tutor@educonnect.com'
);

-- 3. Declare Variables and Seed Auth Users
do $$
declare
  budi_id uuid := 'a1a1a1a1-b1b1-c1c1-d1d1-e1e1e1e1e1e1';
  siti_id uuid := 'a2a2a2a2-b2b2-c2c2-d2d2-e2e2e2e2e2e2';
  andi_id uuid := 'a3a3a3a3-b3b3-c3c3-d3d3-e3e3e3e3e3e3';
  citra_id uuid := 'a4a4a4a4-b4b4-c4c4-d4d4-e4e4e4e4e4e4';
  john_id  uuid := 'a5a5a5a5-b5b5-c5c5-d5d5-e5e5e5e5e5e5';
  
  pwd_hash text := crypt('PasswordTutor123!', gen_salt('bf'));
begin
  -- BUDI (Jakarta)
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (budi_id, '00000000-0000-0000-0000-000000000000', 'budi.tutor@educonnect.com', pwd_hash, now(), '{"provider": "email", "providers": ["email"]}', '{"display_name": "Budi Santoso, S.Pd."}', now(), now(), 'authenticated', 'authenticated');

  insert into public.users (uid, email, display_name, photo_url, role, created_at, updated_at)
  values (budi_id, 'budi.tutor@educonnect.com', 'Budi Santoso, S.Pd.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Budi', 'tutor', now(), now());

  insert into public.tutors (uid, display_name, photo_url, bio, subjects, price_per_hour, experience_years, experience_description, location_label, latitude, longitude, geohash, rating, total_reviews, is_active, verification_status, consistency_score, attendance_rate, on_time_rate, cancellation_rate, created_at, updated_at)
  values (budi_id, 'Budi Santoso, S.Pd.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Budi', 'Halo! Saya Kak Budi, lulusan Pendidikan Matematika dengan pengalaman mengajar 5 tahun. Saya suka mengajar Matematika & Fisika dengan cara yang seru dan mudah dipahami.', '{"Matematika", "Fisika"}', 75000, 5, 'Mengajar di bimbingan belajar terkemuka dan menjadi tutor privat aktif.', 'Jakarta Selatan, DKI Jakarta', -6.2088, 106.8456, '', 4.9, 12, true, 'approved', 98, 100, 95, 0, now(), now());

  -- SITI (Bandung)
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (siti_id, '00000000-0000-0000-0000-000000000000', 'siti.tutor@educonnect.com', pwd_hash, now(), '{"provider": "email", "providers": ["email"]}', '{"display_name": "Siti Rahma, M.Hum."}', now(), now(), 'authenticated', 'authenticated');

  insert into public.users (uid, email, display_name, photo_url, role, created_at, updated_at)
  values (siti_id, 'siti.tutor@educonnect.com', 'Siti Rahma, M.Hum.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Siti', 'tutor', now(), now());

  insert into public.tutors (uid, display_name, photo_url, bio, subjects, price_per_hour, experience_years, experience_description, location_label, latitude, longitude, geohash, rating, total_reviews, is_active, verification_status, consistency_score, attendance_rate, on_time_rate, cancellation_rate, created_at, updated_at)
  values (siti_id, 'Siti Rahma, M.Hum.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Siti', 'Hello! Saya Kak Siti, dosen praktisi Bahasa Inggris. Siap membantumu menguasai percakapan Bahasa Inggris, persiapan ujian sekolah, maupun TOEFL/IELTS.', '{"Bahasa Inggris"}', 60000, 6, 'Dosen Bahasa Inggris & tutor profesional bersertifikasi TOEFL.', 'Cibeunying Kaler, Kota Bandung', -6.9175, 107.6191, '', 4.8, 8, true, 'approved', 95, 96, 92, 2, now(), now());

  -- ANDI (Surabaya)
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (andi_id, '00000000-0000-0000-0000-000000000000', 'andi.tutor@educonnect.com', pwd_hash, now(), '{"provider": "email", "providers": ["email"]}', '{"display_name": "Dr. Andi Wijaya"}', now(), now(), 'authenticated', 'authenticated');

  insert into public.users (uid, email, display_name, photo_url, role, created_at, updated_at)
  values (andi_id, 'andi.tutor@educonnect.com', 'Dr. Andi Wijaya', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Andi', 'tutor', now(), now());

  insert into public.tutors (uid, display_name, photo_url, bio, subjects, price_per_hour, experience_years, experience_description, location_label, latitude, longitude, geohash, rating, total_reviews, is_active, verification_status, consistency_score, attendance_rate, on_time_rate, cancellation_rate, created_at, updated_at)
  values (andi_id, 'Dr. Andi Wijaya', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Andi', 'Salam kenal! Saya Dr. Andi, akademisi IPA & Biologi. Saya fokus pada pembelajaran konseptual agar siswa paham sains dari akarnya, bukan sekadar menghafal.', '{"Biologi", "Kimia", "IPA"}', 85000, 10, 'Peneliti, penulis jurnal, dan praktisi pengajar olimpiade sains.', 'Gubeng, Kota Surabaya', -7.2575, 112.7521, '', 5.0, 15, true, 'approved', 99, 100, 98, 0, now(), now());

  -- CITRA (Yogyakarta)
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (citra_id, '00000000-0000-0000-0000-000000000000', 'citra.tutor@educonnect.com', pwd_hash, now(), '{"provider": "email", "providers": ["email"]}', '{"display_name": "Citra Lestari, S.Pd."}', now(), now(), 'authenticated', 'authenticated');

  insert into public.users (uid, email, display_name, photo_url, role, created_at, updated_at)
  values (citra_id, 'citra.tutor@educonnect.com', 'Citra Lestari, S.Pd.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Citra', 'tutor', now(), now());

  insert into public.tutors (uid, display_name, photo_url, bio, subjects, price_per_hour, experience_years, experience_description, location_label, latitude, longitude, geohash, rating, total_reviews, is_active, verification_status, consistency_score, attendance_rate, on_time_rate, cancellation_rate, created_at, updated_at)
  values (citra_id, 'Citra Lestari, S.Pd.', 'https://api.dicebear.com/7.x/adventurer/svg?seed=Citra', 'Halo semuanya! Saya Kak Citra, spesialis IPS dan IPAS untuk jenjang SD dan SMP. Saya suka membuat peta konsep yang interaktif agar sejarah & sains menjadi seru.', '{"IPAS", "IPS", "Sejarah"}', 45000, 3, 'Tutor privat berpengalaman mendampingi kurikulum Merdeka belajar.', 'Malioboro, Kota Yogyakarta', -7.7956, 110.3695, '', 4.7, 5, true, 'approved', 92, 94, 90, 4, now(), now());

  -- JOHN (Mountain View - EMULATOR DEFAULT GPS)
  insert into auth.users (id, instance_id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role, aud)
  values (john_id, '00000000-0000-0000-0000-000000000000', 'john.tutor@educonnect.com', pwd_hash, now(), '{"provider": "email", "providers": ["email"]}', '{"display_name": "John Doe, M.Sc. (Emulator Spec)"}', now(), now(), 'authenticated', 'authenticated');

  insert into public.users (uid, email, display_name, photo_url, role, created_at, updated_at)
  values (john_id, 'john.tutor@educonnect.com', 'John Doe, M.Sc. (Emulator Spec)', 'https://api.dicebear.com/7.x/adventurer/svg?seed=John', 'tutor', now(), now());

  insert into public.tutors (uid, display_name, photo_url, bio, subjects, price_per_hour, experience_years, experience_description, location_label, latitude, longitude, geohash, rating, total_reviews, is_active, verification_status, consistency_score, attendance_rate, on_time_rate, cancellation_rate, created_at, updated_at)
  values (john_id, 'John Doe, M.Sc. (Emulator Spec)', 'https://api.dicebear.com/7.x/adventurer/svg?seed=John', 'Hello! I am John, seeded at Mountain View California to match Android Emulator GPS defaults. I can help with Mathematics, English, and Science.', '{"Matematika", "Bahasa Inggris", "IPA"}', 90000, 8, 'International school teacher and academic content creator.', 'Mountain View, California, USA', 37.4220, -122.0841, '', 4.9, 20, true, 'approved', 97, 98, 96, 1, now(), now());

  -- 4. Seed Availabilities
  -- Budi (Senin & Rabu 15:00 - 17:00)
  insert into public.tutor_availability (tutor_uid, weekday, start_time, end_time, is_active)
  values (budi_id, 1, '15:00:00', '17:00:00', true), (budi_id, 3, '15:00:00', '17:00:00', true);

  -- Siti (Selasa & Kamis 16:00 - 18:00)
  insert into public.tutor_availability (tutor_uid, weekday, start_time, end_time, is_active)
  values (siti_id, 2, '16:00:00', '18:00:00', true), (siti_id, 4, '16:00:00', '18:00:00', true);

  -- Andi (Rabu & Sabtu 14:00 - 16:00)
  insert into public.tutor_availability (tutor_uid, weekday, start_time, end_time, is_active)
  values (andi_id, 3, '14:00:00', '16:00:00', true), (andi_id, 6, '14:00:00', '16:00:00', true);

  -- Citra (Senin & Jumat 15:00 - 17:00)
  insert into public.tutor_availability (tutor_uid, weekday, start_time, end_time, is_active)
  values (citra_id, 1, '15:00:00', '17:00:00', true), (citra_id, 5, '15:00:00', '17:00:00', true);

  -- John (Sabtu & Minggu 10:00 - 12:00)
  insert into public.tutor_availability (tutor_uid, weekday, start_time, end_time, is_active)
  values (john_id, 6, '10:00:00', '12:00:00', true), (john_id, 7, '10:00:00', '12:00:00', true);

end $$;
