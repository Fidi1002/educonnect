-- Supabase Migration: Add Ebook Scan Status and User iCal Feed Generator

-- 1. Tambahkan kolom scan_status ke public.library_ebooks
ALTER TABLE public.library_ebooks ADD COLUMN scan_status text NOT NULL DEFAULT 'clean';
ALTER TABLE public.library_ebooks ALTER COLUMN scan_status SET DEFAULT 'pending';

-- Tambahkan check constraint agar nilainya hanya pending, clean, atau infected
ALTER TABLE public.library_ebooks ADD CONSTRAINT check_ebook_scan_status CHECK (scan_status IN ('pending', 'clean', 'infected'));

-- 2. Buat fungsi pemindai virus simulan
CREATE OR REPLACE FUNCTION public.validate_and_scan_ebook()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Jika judul mengandung kata 'eicar' atau 'virus', tandai terinfeksi (infected)
  IF lower(new.title) LIKE '%eicar%' OR lower(new.title) LIKE '%virus%' THEN
    new.scan_status := 'infected';
  ELSE
    new.scan_status := 'clean';
  END IF;
  RETURN new;
END;
$$;

-- Daftarkan trigger sebelum insert
CREATE TRIGGER validate_and_scan_ebook_trigger
  BEFORE INSERT ON public.library_ebooks
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_and_scan_ebook();

-- 3. Perbarui kebijakan SELECT RLS agar menyaring berkas terinfeksi
DROP POLICY IF EXISTS "Ebooks are viewable by booking participants" ON public.library_ebooks;

CREATE POLICY "Ebooks are viewable by booking participants"
  ON public.library_ebooks FOR SELECT
  USING (
    auth.uid() = tutor_uid
    OR (
      scan_status = 'clean'
      AND EXISTS (
        SELECT 1 FROM public.bookings b
        WHERE b.id = booking_id
          AND b.student_uid = auth.uid()
      )
    )
  );

-- 4. Expose generator iCal Feed
CREATE OR REPLACE FUNCTION public.get_user_ical_feed(p_user_uid uuid)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  v_ics text;
  v_row record;
  v_now text;
BEGIN
  v_now := to_char(now() at time zone 'utc', 'YYYYMMDD"T"HH24MISS"Z"');
  v_ics := 'BEGIN:VCALENDAR' || chr(10) ||
           'VERSION:2.0' || chr(10) ||
           'PRODID:-//EduConnect//NONSGML Calendar Feed//EN' || chr(10) ||
           'CALSCALE:GREGORIAN' || chr(10);
           
  FOR v_row IN (
    SELECT 
      bs.id,
      bs.session_start,
      bs.session_end,
      b.subject,
      t.display_name AS tutor_name,
      u.display_name AS student_name,
      bs.student_uid,
      bs.tutor_uid
    FROM public.booking_sessions bs
    JOIN public.bookings b ON b.id = bs.booking_id
    JOIN public.tutors t ON t.uid = bs.tutor_uid
    JOIN public.users u ON u.uid = bs.student_uid
    WHERE (bs.student_uid = p_user_uid OR bs.tutor_uid = p_user_uid)
      AND bs.status = 'scheduled'
  ) LOOP
    v_ics := v_ics || 'BEGIN:VEVENT' || chr(10) ||
             'UID:' || v_row.id || '@educonnect.com' || chr(10) ||
             'DTSTAMP:' || v_now || chr(10) ||
             'DTSTART:' || to_char(v_row.session_start at time zone 'utc', 'YYYYMMDD"T"HH24MISS"Z"') || chr(10) ||
             'DTEND:' || to_char(v_row.session_end at time zone 'utc', 'YYYYMMDD"T"HH24MISS"Z"') || chr(10) ||
             'SUMMARY:' || v_row.subject || ' (' || 
               CASE 
                 WHEN p_user_uid = v_row.student_uid THEN 'Tutor: ' || v_row.tutor_name 
                 ELSE 'Murid: ' || v_row.student_name 
               END || ')' || chr(10) ||
             'DESCRIPTION:Bimbingan belajar EduConnect untuk mata pelajaran ' || v_row.subject || '.' || chr(10) ||
             'LOCATION:EduConnect Video Classroom' || chr(10) ||
             'END:VEVENT' || chr(10);
  END LOOP;
  
  v_ics := v_ics || 'END:VCALENDAR';
  RETURN v_ics;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_ical_feed(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_ical_feed(uuid) TO service_role;
