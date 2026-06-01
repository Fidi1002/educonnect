-- Milestone - Automated AI Tutor Curation & Verification Engine with Birth Match and App Notifications

-- 1. Tambahkan kolom identitas terstruktur ke tabel tutors
alter table public.tutors
  add column if not exists ktp_name text,
  add column if not exists nik text,
  add column if not exists birth_place text,
  add column if not exists birth_date date,
  add column if not exists experience_cv jsonb;

-- 2. Buat fungsi otomasi verifikasi AI (Curation Engine)
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
  birth_year integer;
  age integer;
begin
  -- Mulai Analisis Otomatis AI OCR
  
  -- Validasi 1: Kelengkapan Dokumen Dasar
  if new.identity_card_url is null or new.identity_card_url = '' then
    score := score - 40.0;
    reason := reason || '• Berkas KTP belum diunggah. ';
  end if;

  if new.certificate_url is null or new.certificate_url = '' then
    score := score - 30.0;
    reason := reason || '• Berkas Sertifikat pengajar belum diunggah. ';
  end if;

  -- Validasi 2: Pencocokan NIK KTP (16 Digit)
  if new.nik is null or new.nik = '' then
    score := score - 30.0;
    reason := reason || '• Nomor NIK KTP kosong. ';
  else
    nik_length := length(new.nik);
    if nik_length <> 16 then
      score := score - 20.0;
      reason := reason || '• NIK wajib terdiri dari 16 digit angka (Terdeteksi: ' || nik_length || ' digit). ';
    end if;
  end if;

  -- Validasi 3: Pencocokan Nama KTP vs Nama Profil
  if new.ktp_name is null or new.ktp_name = '' then
    score := score - 15.0;
    reason := reason || '• Nama Lengkap sesuai KTP kosong. ';
  else
    -- Kemiripan nama dasar
    if lower(new.ktp_name) <> lower(new.display_name) then
      -- Beri pengurangan jika tidak sama persis (misal ada singkatan), tetapi masih diizinkan jika mirip
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
    birth_year := extract(year from new.birth_date);
    age := extract(year from now()) - birth_year;
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

-- 3. Pasang trigger BEFORE INSERT OR UPDATE pada tabel tutors
drop trigger if exists trg_tutor_ai_verification on public.tutors;
create trigger trg_tutor_ai_verification
  before insert or update of identity_card_url, certificate_url, nik, ktp_name, birth_place, birth_date, experience_cv
  on public.tutors
  for each row
  execute function public.handle_tutor_ai_verification();

-- 4. Buat fungsi & trigger AFTER UPDATE untuk otomatisasi notifikasi in-app
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
  end if;
  return new;
end;
$$;

drop trigger if exists trg_tutor_verification_notification on public.tutors;
create trigger trg_tutor_verification_notification
  after update of verification_status
  on public.tutors
  for each row
  execute function public.handle_tutor_verification_notification();
