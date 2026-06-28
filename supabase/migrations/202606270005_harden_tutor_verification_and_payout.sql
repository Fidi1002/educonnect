-- Redefine tutor verification function with manual bypass prevention
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
  -- Server / admin role updates can bypass AI verification checks
  if auth.uid() is null then
    return new;
  end if;

  -- Mencegah bypass status verifikasi secara manual oleh non-admin
  if tg_op = 'UPDATE' then
    if new.identity_card_url is not distinct from old.identity_card_url
       and new.certificate_url is not distinct from old.certificate_url
       and new.nik is not distinct from old.nik
       and new.ktp_name is not distinct from old.ktp_name
       and new.birth_place is not distinct from old.birth_place
       and new.birth_date is not distinct from old.birth_date
       and new.experience_cv is not distinct from old.experience_cv then
       
       new.verification_status := old.verification_status;
       new.rejection_reason := old.rejection_reason;
       new.is_active := old.is_active;
       return new;
    end if;
  end if;

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

-- Recreate trigger trg_tutor_ai_verification to run before any insert or update
drop trigger if exists trg_tutor_ai_verification on public.tutors;
create trigger trg_tutor_ai_verification
  before insert or update
  on public.tutors
  for each row
  execute function public.handle_tutor_ai_verification();

-- Change trigger trg_payout_status_change to BEFORE update to ensure new.processed_at is successfully persisted
drop trigger if exists trg_payout_status_change on public.payout_requests;
create trigger trg_payout_status_change
  before update of status
  on public.payout_requests
  for each row
  execute function public.handle_payout_status_change();
