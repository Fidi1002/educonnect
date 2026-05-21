-- Migration to fix Tutor Curation Bypass
-- Ensure tutors are NOT active and do NOT show up on maps or searches until approved by an admin.

-- 1. Cleanse existing database state: set is_active to false for any tutor whose verification_status is not 'approved'
update public.tutors
set is_active = false
where verification_status <> 'approved';

-- 2. Update get_nearby_tutors RPC to strictly filter for approved verification_status
create or replace function public.get_nearby_tutors(
  p_latitude double precision,
  p_longitude double precision,
  p_radius_km double precision,
  p_limit integer default 250
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
  distance_km double precision
)
language sql
stable
as $$
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
    st_distance(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography
    ) / 1000 as distance_km
  from public.tutors t
  where t.is_active = true
    and t.verification_status = 'approved' -- Strictly allow only verified/approved tutors
    and t.location is not null
    and st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  order by distance_km asc
  limit greatest(coalesce(p_limit, 250), 1);
$$;

-- 3. Update get_recommended_tutors RPC to strictly filter for approved verification_status
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
BEGIN
  -- Ambil preferensi siswa
  SELECT preferred_subjects, max_price_preference
  INTO v_preferred_subjects, v_max_price
  FROM public.users
  WHERE users.uid = p_student_uid;

  -- Normalisasi nilai default preferensi jika kosong
  IF v_preferred_subjects IS NULL THEN
    v_preferred_subjects := '{}';
  END IF;
  
  IF v_max_price IS NULL OR v_max_price <= 0 THEN
    v_max_price := 1000000; -- Fallback jika budget tidak dibatasi
  END IF;

  RETURN QUERY
  SELECT
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
    ROUND(
      -- A. Bobot Jarak (40%): semakin dekat semakin tinggi skornya
      (CASE 
        WHEN st_dwithin(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography, p_radius_km * 1000) THEN
          (1.0 - (st_distance(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography) / 1000.0) / p_radius_km) * 40.0
        ELSE 0.0
      END) +
      -- B. Bobot Mapel (35%): jika ada mata pelajaran yang diajarkan tutor beririsan dengan preferensi murid
      (CASE 
        WHEN t.subjects && v_preferred_subjects THEN 35.0
        ELSE 0.0
      END) +
      -- C. Bobot Batas Harga/Budget (10%)
      (CASE 
        WHEN t.price_per_hour <= v_max_price THEN 10.0
        WHEN t.price_per_hour > 0 THEN (v_max_price / t.price_per_hour) * 10.0
        ELSE 0.0
      END) +
      -- D. Bobot Rating & Kualitas (10%)
      (CASE 
        WHEN t.rating > 0 THEN (t.rating / 5.0) * 10.0
        ELSE 0.0
      END) +
      -- E. Bobot Disiplin/Konsistensi (5%)
      (CASE 
        WHEN t.consistency_score > 0 THEN (t.consistency_score::double precision / 100.0) * 5.0
        ELSE 0.0
      END)
    ) as recommendation_score
  FROM public.tutors t
  WHERE t.is_active = true
    and t.verification_status = 'approved' -- Strictly allow only verified/approved tutors
    AND t.location IS NOT NULL
    AND st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  ORDER BY recommendation_score DESC, distance_km ASC
  LIMIT greatest(coalesce(p_limit, 25), 1);
END;
$$;
