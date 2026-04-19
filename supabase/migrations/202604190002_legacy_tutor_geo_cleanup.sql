-- Optional data migration for legacy tutor rows
-- 1) clear impossible coordinate values
update public.tutors
set latitude = null,
    longitude = null,
    geohash = '',
    is_active = false
where latitude is not null
  and longitude is not null
  and (
    latitude < -90
    or latitude > 90
    or longitude < -180
    or longitude > 180
  );

-- 2) deactivate tutor profiles that still have no valid coordinate
update public.tutors
set is_active = false
where latitude is null or longitude is null;
