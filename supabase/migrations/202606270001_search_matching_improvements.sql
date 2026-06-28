-- Migration: 202606270001_search_matching_improvements.sql
-- Goal: Improve search & matching algorithms and add location synchronization trigger.

-- 1. Update get_recommended_tutors to improve matching score accuracy & filter price > 1.5x budget
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
      (
        -- A. Bobot Jarak (35%): semakin dekat semakin tinggi skornya
        CASE 
          WHEN st_dwithin(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography, p_radius_km * 1000) THEN
            (1.0 - (st_distance(t.location, st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography) / 1000.0) / p_radius_km) * 35.0
          ELSE 0.0
        END
      ) +
      (
        -- B. Bobot Mapel (35%): Proporsional berdasarkan irisan mapel tutor & preferensi murid
        CASE 
          WHEN cardinality(v_preferred_subjects) > 0 THEN
            (SELECT count(*)::double precision 
             FROM (
               SELECT unnest(t.subjects) 
               INTERSECT 
               SELECT unnest(v_preferred_subjects)
             ) AS intersection) / cardinality(v_preferred_subjects) * 35.0
          ELSE 0.0
        END
      ) +
      (
        -- C. Bobot Batas Harga/Budget (10%)
        CASE 
          WHEN t.price_per_hour <= v_max_price THEN 10.0
          WHEN t.price_per_hour > 0 THEN (v_max_price / t.price_per_hour) * 10.0
          ELSE 0.0
        END
      ) +
      (
        -- D. Bobot Rating & Kualitas (10%)
        CASE 
          WHEN t.rating > 0 THEN (t.rating / 5.0) * 10.0
          ELSE 0.0
        END
      ) +
      (
        -- E. Bobot Disiplin/Konsistensi (10%): Naik dari 5% ke 10%
        CASE 
          WHEN t.consistency_score > 0 THEN (t.consistency_score::double precision / 100.0) * 10.0
          ELSE 0.0
        END
      )
    ) as recommendation_score
  FROM public.tutors t
  WHERE t.is_active = true
    and t.verification_status = 'approved' -- Hanya tutor yang terverifikasi/disetujui
    AND t.location IS NOT NULL
    AND t.price_per_hour <= (v_max_price * 1.5) -- Eliminasi tutor di luar budget (> 150%)
    AND st_dwithin(
      t.location,
      st_setsrid(st_makepoint(p_longitude, p_latitude), 4326)::geography,
      p_radius_km * 1000
    )
  ORDER BY recommendation_score DESC, distance_km ASC
  LIMIT greatest(coalesce(p_limit, 25), 1);
END;
$$;

-- 2. Add trigger to automatically sync location (geography) on tutors table
create or replace function public.sync_tutor_location_point()
returns trigger
language plpgsql
as $$
begin
  if (new.latitude is not null and new.longitude is not null) and
     (old.latitude is distinct from new.latitude or old.longitude is distinct from new.longitude or new.location is null) then
    new.location := st_setsrid(st_makepoint(new.longitude, new.latitude), 4326)::geography;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_tutors_sync_location on public.tutors;
create trigger trg_tutors_sync_location
before insert or update on public.tutors
for each row
execute function public.sync_tutor_location_point();
