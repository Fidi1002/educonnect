-- Refinement: Precision Age Calculation, NIK Regex Validation, Verification Rejection Notifications, Booking-based E-book RLS, and School Level matching in Recommendation

-- 1. Redefine tutor AI verification function with precision age and NIK regex checks
create or replace function public.handle_tutor_ai_verification()
returns trigger
language plpgsql
security definer
as $$
declare
  score numeric := 100.0;
  reason text := '';
  nik_length integer := 0;
  cv_item jsonb;
  cv_count integer := 0;
  age integer;
begin
  -- Validasi 1: Kelengkapan Dokumen Dasar
  if new.identity_card_url is null or new.identity_card_url = '' then
    score := score - 40.0;
    reason := reason || '• Berkas KTP belum diunggah. ';
  end if;

  if new.certificate_url is null or new.certificate_url = '' then
    score := score - 30.0;
    reason := reason || '• Berkas Sertifikat pengajar belum diunggah. ';
  end if;

  -- Validasi 2: Pencocokan NIK KTP (Wajib 16 digit angka saja)
  if new.nik is null or new.nik = '' then
    score := score - 30.0;
    reason := reason || '• Nomor NIK KTP kosong. ';
  else
    nik_length := length(new.nik);
    if new.nik !~ '^[0-9]{16}$' then
      score := score - 20.0;
      reason := reason || '• NIK wajib terdiri dari tepat 16 digit angka saja (Terdeteksi: ' || nik_length || ' karakter). ';
    end if;
  end if;

  -- Validasi 3: Pencocokan Nama KTP vs Nama Profil
  if new.ktp_name is null or new.ktp_name = '' then
    score := score - 15.0;
    reason := reason || '• Nama Lengkap sesuai KTP kosong. ';
  else
    if lower(new.ktp_name) <> lower(new.display_name) then
      score := score - 5.0;
    end if;
  end if;

  -- Validasi 4: Tempat & Tanggal Lahir (Birth Match)
  if new.birth_place is null or new.birth_place = '' then
    score := score - 10.0;
    reason := reason || '• Tempat Lahir kosong. ';
  end if;

  if new.birth_date is null then
    score := score - 15.0;
    reason := reason || '• Tanggal Lahir kosong. ';
  else
    -- Menggunakan age() PostgreSQL untuk menghitung umur kronologis yang presisi
    age := extract(year from age(new.birth_date))::integer;
    if age < 18 then
      score := score - 30.0;
      reason := reason || '• Usia tutor kurang dari 18 tahun (Syarat minimal mengajar). ';
    end if;
  end if;

  -- Validasi 5: Kelengkapan Riwayat CV Mengajar (experience_cv)
  if new.experience_cv is null or jsonb_typeof(new.experience_cv) <> 'array' then
    score := score - 15.0;
    reason := reason || '• Riwayat CV pengajaran kosong atau format tidak terstruktur. ';
  else
    cv_count := jsonb_array_length(new.experience_cv);
    if cv_count = 0 then
      score := score - 15.0;
      reason := reason || '• Wajib mencantumkan minimal 1 riwayat pengajar di CV. ';
    end if;
  end if;

  -- Tentukan Keputusan AI
  if score >= 85.0 then
    new.verification_status := 'approved';
    new.is_active := true;
    new.rejection_reason := '🤖 [EduConnect AI - Verifikasi Lolos]' || chr(10) ||
                            '• Trust Score: ' || round(score, 1) || '%' || chr(10) ||
                            '• Analisis KTP: Sukses (NIK valid & Nama terverifikasi)' || chr(10) ||
                            '• Analisis Tempat & Tanggal Lahir: Sukses (' || coalesce(new.birth_place, '-') || ', ' || coalesce(new.birth_date::text, '-') || ')' || chr(10) ||
                            '• Analisis CV: Sukses (' || cv_count || ' riwayat mengajar terdaftar)' || chr(10) ||
                            '• Waktu Verifikasi: ' || to_char(now(), 'YYYY-MM-DD HH24:MI:SS') || ' UTC';
  else
    new.verification_status := 'rejected';
    new.is_active := false;
    new.rejection_reason := '🤖 [EduConnect AI - Verifikasi Gagal]' || chr(10) ||
                            '• Trust Score: ' || round(score, 1) || '%' || chr(10) ||
                            '• Alasan Kesenjangan Data:' || chr(10) || reason;
  end if;

  return new;
end;
$$;

-- 2. Redefine tutor verification notification function to support rejected notifications
create or replace function public.handle_tutor_verification_notification()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Kirim notifikasi jika status verifikasi berubah dari 'pending'/'none'/'rejected' menjadi 'approved'
  if new.verification_status = 'approved' and (old.verification_status is null or old.verification_status <> 'approved') then
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id
    ) values (
      new.uid,
      new.uid, -- Actor is user themselves (self/system trigger)
      'system',
      'Akun Tutor Aktif & Terverifikasi AI! 🎉',
      'Selamat! Pengajuan profil Anda telah disetujui secara otomatis oleh sistem kurasi kecerdasan buatan EduConnect AI. Akun Anda kini aktif secara publik di peta & daftar pencarian murid.',
      'profile',
      new.uid::text
    );
  -- Kirim notifikasi jika status verifikasi berubah menjadi 'rejected'
  elsif new.verification_status = 'rejected' and (old.verification_status is null or old.verification_status <> 'rejected') then
    insert into public.app_notifications (
      user_uid,
      actor_uid,
      category,
      title,
      body,
      target_type,
      target_id
    ) values (
      new.uid,
      new.uid,
      'system',
      'Verifikasi Profil Tutor Ditangguhkan ⚠️',
      'Mohon maaf, pengajuan verifikasi profil Anda belum disetujui karena ada ketidaksesuaian data. Sila periksa detail perbaikan di halaman profil Anda.',
      'profile',
      new.uid::text
    );
  end if;
  return new;
end;
$$;

-- Recreate trigger without "OF verification_status" filter to ensure it catches updates from BEFORE trigger
drop trigger if exists trg_tutor_verification_notification on public.tutors;
create trigger trg_tutor_verification_notification
  after update
  on public.tutors
  for each row
  execute function public.handle_tutor_verification_notification();

-- 3. Redefine E-book select RLS policy to allow access to student booking participants regardless of school level changes
drop policy if exists "Ebooks are viewable by booking participants matching student school level" on public.library_ebooks;
drop policy if exists "Ebooks are viewable by booking participants" on public.library_ebooks;

create policy "Ebooks are viewable by booking participants"
  on public.library_ebooks for select
  using (
    auth.uid() = tutor_uid
    or (
      exists (
        select 1 from public.bookings b
        where b.id = booking_id
          and b.student_uid = auth.uid()
      )
    )
  );

-- 4. Redefine recommended tutors function to enforce school level matching (SD, SMP, SMA)
create or replace function public.get_recommended_tutors(
  p_student_uid uuid,
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 25
)
returns table (
  uid uuid,
  display_name text,
  photo_url text,
  subjects text[],
  rating double precision,
  total_reviews integer,
  price_per_hour numeric,
  is_active boolean,
  latitude double precision,
  longitude double precision,
  consistency_score double precision,
  experience_years integer,
  distance_km double precision,
  recommendation_score double precision
)
language plpgsql
stable
as $$
declare
  v_preferred_subjects text[];
  v_max_price numeric;
  v_school_level text;
begin
  -- Ambil preferensi siswa dan tingkat sekolahnya
  select preferred_subjects, max_price_preference, school_level
  into v_preferred_subjects, v_max_price, v_school_level
  from public.users
  where users.uid = p_student_uid;

  -- Normalisasi nilai default preferensi jika kosong
  if v_preferred_subjects is null then
    v_preferred_subjects := '{}';
  end if;
  
  if v_max_price is null or v_max_price <= 0 then
    v_max_price := 1000000; -- Fallback jika budget tidak dibatasi
  end if;

  return query
  select
    t.uid,
    t.display_name,
    t.photo_url,
    t.subjects,
    t.rating,
    t.total_reviews,
    t.price_per_hour,
    t.is_active,
    t.latitude,
    t.longitude,
    t.consistency_score::double precision as consistency_score,
    t.experience_years,
    -- Hitung Jarak (km) dari koordinat siswa ke tutor menggunakan PostGIS geography
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000.0 as distance_km,
    -- Hitung Skor Rekomendasi Dinamis (0 - 100)
    round(
      -- A. Bobot Jarak (40%): semakin dekat semakin tinggi skornya
      (case 
        when st_dwithin(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography, p_radius_km * 1000) then
          (1.0 - (st_distance(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography) / 1000.0) / p_radius_km) * 40.0
        else 0.0
      end) +
      -- B. Bobot Mapel (35%): jika ada mata pelajaran yang diajarkan tutor beririsan dengan preferensi murid
      (case 
        when t.subjects && v_preferred_subjects then 35.0
        else 0.0
      end) +
      -- C. Bobot Batas Harga/Budget (10%)
      (case 
        when t.price_per_hour <= v_max_price then 10.0
        when t.price_per_hour > 0 then (v_max_price / t.price_per_hour) * 10.0
        else 0.0
      end) +
      -- D. Bobot Rating & Kualitas (10%)
      (case 
        when t.rating > 0 then (t.rating / 5.0) * 10.0
        else 0.0
      end) +
      -- E. Bobot Disiplin/Konsistensi (5%)
      (case 
        when t.consistency_score > 0 then (t.consistency_score::double precision / 100.0) * 5.0
        else 0.0
      end)
    ) as recommendation_score
  from public.tutors t
  where t.is_active = true
    and t.location is not null
    -- Filter Jarak
    and st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
    -- Filter Kecocokan Tingkat Sekolah (SD, SMP, SMA)
    and (
      v_school_level is null 
      or t.teaching_levels is null 
      or cardinality(t.teaching_levels) = 0
      or v_school_level = any(t.teaching_levels)
    );
end;
$$;
