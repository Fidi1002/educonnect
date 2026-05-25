-- Milestone - Dynamic Student Capacity for Tutors

-- 1. Tambahkan kolom max_student_capacity di tabel public.tutors
alter table public.tutors
  add column if not exists max_student_capacity integer default 2 check (max_student_capacity > 0);

-- 2. Perbarui trigger validate_package_booking() agar melakukan pengecekan kapasitas secara dinamis
create or replace function public.validate_package_booking()
returns trigger
language plpgsql
as $$
declare
  slot jsonb;
  slot_count integer := 0;
  slot_weekday integer;
  slot_start time;
  slot_end time;
  existing_slot jsonb;
  active_students integer;
  tutor_capacity integer := 2; -- default fallback
begin
  if new.package_months not in (1, 2, 3, 6) then
    raise exception 'Paket hanya boleh 1, 2, 3, atau 6 bulan.';
  end if;

  if new.sessions_per_week != 2 then
    raise exception 'Frekuensi kelas wajib 2x per minggu.';
  end if;

  if jsonb_typeof(new.weekly_schedule) <> 'array' then
    raise exception 'weekly_schedule wajib array.';
  end if;

  slot_count := jsonb_array_length(new.weekly_schedule);
  if slot_count <> 2 then
    raise exception 'weekly_schedule wajib berisi tepat 2 slot.';
  end if;

  if new.package_end_date < new.package_start_date then
    raise exception 'Tanggal akhir paket tidak valid.';
  end if;

  for slot in
    select value from jsonb_array_elements(new.weekly_schedule)
  loop
    slot_weekday := (slot->>'weekday')::integer;
    slot_start := (slot->>'start_time')::time;
    slot_end := (slot->>'end_time')::time;

    if slot_weekday < 1 or slot_weekday > 7 then
      raise exception 'Weekday slot harus antara 1 dan 7.';
    end if;

    if slot_end <= slot_start then
      raise exception 'Jam selesai slot harus lebih besar dari jam mulai.';
    end if;

    if not exists (
      select 1
      from public.tutor_availability ta
      where ta.tutor_uid = new.tutor_uid
        and ta.is_active = true
        and ta.weekday = slot_weekday
        and ta.start_time <= slot_start
        and ta.end_time >= slot_end
    ) then
      raise exception 'Slot tidak termasuk jadwal ketersediaan tutor.';
    end if;
  end loop;

  for slot in
    select value from jsonb_array_elements(new.weekly_schedule)
  loop
    slot_weekday := (slot->>'weekday')::integer;
    slot_start := (slot->>'start_time')::time;
    slot_end := (slot->>'end_time')::time;

    for existing_slot in
      select value
      from public.bookings b,
      lateral jsonb_array_elements(b.weekly_schedule) value
      where b.tutor_uid = new.tutor_uid
        and b.id <> new.id
        and (
          b.status in ('awaiting_payment', 'paid')
          or (
            b.status = 'pending'
            and b.expires_at is not null
            and b.expires_at > now()
          )
        )
        and daterange(b.package_start_date, b.package_end_date, '[]')
            && daterange(new.package_start_date, new.package_end_date, '[]')
    loop
      if slot_weekday = (existing_slot->>'weekday')::integer and public.overlap_time(
        slot_start,
        slot_end,
        (existing_slot->>'start_time')::time,
        (existing_slot->>'end_time')::time
      ) then
        raise exception 'Slot bentrok dengan jadwal murid aktif lain.';
      end if;
    end loop;
  end loop;

  if new.status in ('pending', 'awaiting_payment', 'paid') then
    -- Ambil kapasitas mengajar tutor saat ini dari tabel tutors
    select coalesce(max_student_capacity, 2)
    into tutor_capacity
    from public.tutors
    where uid = new.tutor_uid;

    select count(distinct b.student_uid)
    into active_students
    from public.bookings b
    where b.tutor_uid = new.tutor_uid
      and b.id <> new.id
      and (
        b.status in ('awaiting_payment', 'paid')
        or (
          b.status = 'pending'
          and b.expires_at is not null
          and b.expires_at > now()
        )
      )
      and daterange(b.package_start_date, b.package_end_date, '[]')
          && daterange(new.package_start_date, new.package_end_date, '[]');

    if active_students >= tutor_capacity then
      raise exception 'Tutor sudah mencapai kapasitas maksimal % murid aktif.', tutor_capacity;
    end if;
  end if;

  return new;
end;
$$;
