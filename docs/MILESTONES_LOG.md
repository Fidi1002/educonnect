# Milestones Log (Implementasi EduConnect)

Dokumen ini merangkum milestone yang telah dikerjakan serta artefak teknis yang dihasilkan (kode Flutter dan migrasi Supabase).

Catatan: rencana awal menggunakan Firebase, namun pada implementasi aktual backend dipindahkan ke Supabase karena kendala aktivasi Firebase. Arah fitur tetap sama (Auth, pencarian tutor terdekat, booking, chat, notifikasi, dll), hanya lapisan backend yang berubah.

## Milestone 1 - Fondasi Proyek
Output:
- Struktur project Flutter, routing dasar, dan setup dependency utama.
- Folder dokumentasi awal pada `docs/`.

## Milestone 2 - Auth dan Role
Output:
- Registrasi/login via email/password.
- Onboarding pemilihan role `student` atau `tutor` tersimpan ke tabel `public.users`.
- Guard route berdasarkan role (redirect ke home sesuai role).

Artefak:
- Router: `lib/app/routes/app_router.dart`
- Controller/auth flow: `lib/features/auth/`
- DB: `supabase/migrations/202604190001_phase1_auth_tutor_nearby.sql` (tabel `users`)

## Milestone 3 - Profil Tutor + Storage Foto
Output:
- Tutor dapat melengkapi profil (bio, mapel, harga, pengalaman, lokasi).
- Upload foto ke Supabase Storage bucket `tutor-photos`.

Artefak:
- UI tutor profile: `lib/features/tutor_profile/` (nama folder dapat bervariasi sesuai repo)
- Storage policy: bagian storage policy pada migrasi phase 1.

## Milestone 4 - Lokasi dan Pencarian Tutor Terdekat
Output:
- Ambil lokasi user + permission handling.
- Query tutor terdekat dengan radius 1/5/10/20 km.
- Sinkron list dengan radius yang dipilih.

Artefak:
- RPC: `get_nearby_tutors` pada `supabase/migrations/202604190001_phase1_auth_tutor_nearby.sql`
- UI Student home/nearby: `lib/features/home/` (student)

## Milestone 5 - Booking Dasar
Output:
- Murid dapat membuat booking ke tutor.
- Tutor dapat menerima/menolak booking.

Artefak:
- DB: `supabase/migrations/202604190003_milestone5_bookings.sql`
- UI booking: `lib/features/booking/`

## Milestone 6 - Payment Dummy + Status Flow
Output:
- Skema `transactions` dan status pembayaran dummy.
- Booking masuk ke state "awaiting_payment" dan "paid".

Artefak:
- DB: `supabase/migrations/202604190004_milestone6_payment_flow.sql`

## Milestone 7 - Chat dan Realtime
Output:
- Chat student <-> tutor berbasis booking.
- Pesan unread/read.

Artefak:
- DB: `supabase/migrations/202604190005_milestone7_chat_realtime.sql`
- UI chat: `lib/features/chat/` (nama folder dapat bervariasi)

## Milestone 8 - Availability Tutor
Output:
- Tutor mengatur jadwal ketersediaan (weekday, start-end time).
- Digunakan sebagai dasar validasi scheduling paket.

Artefak:
- DB: `supabase/migrations/202604190006_milestone8_availability_scheduling.sql`

## Milestone 9 - Paket Booking (1/2/3/6 bulan) + Siklus Bulanan
Output:
- Booking paket 1/2/3/6 bulan, frekuensi 2x/minggu (weekly_schedule 2 slot).
- Pembayaran per bulan (cycle).
- Validasi slot dan kapasitas tutor maks 2 murid aktif.

Artefak:
- DB:
  - `supabase/migrations/202604200007_milestone9_package_booking.sql`
  - `supabase/migrations/202604200008_milestone9_monthly_cycles.sql`

## Milestone 10 - Konfirmasi Sesi + Basis Penilaian
Output:
- Sesi pertemuan tersimpan sebagai `booking_sessions`.
- Alur tutor mark done -> murid confirm/dispute.
- Landasan rating: tidak hanya dari input murid, tetapi juga dari kedisiplinan tutor (consistency score).

Artefak:
- DB:
  - `supabase/migrations/202604210009_milestone10_session_confirmation.sql`
  - `supabase/migrations/202604210010_milestone10_tutor_consistency_score.sql`
- UI kalender murid/tutor:
  - `lib/features/home/presentation/pages/student_study_calendar_page.dart`
  - `lib/features/home/presentation/pages/tutor_study_calendar_page.dart`

## Milestone 11 - Reschedule/Cancel + Notifikasi In-App
Output:
- Workflow reschedule/cancel berbasis request (approve/reject).
- Notifikasi in-app yang bisa di-tap untuk deep-link ke target.

Artefak:
- DB:
  - `supabase/migrations/202604210011_milestone11_session_reschedule_cancel.sql`
  - `supabase/migrations/202604210012_milestone11_inapp_notifications.sql`
- UI notifikasi: `lib/features/notifications/`

## Milestone 12 - Hardening: Status Transition + Atomic Create + Expiry + Dispute Lifecycle
Output:
- Trigger untuk memastikan transisi status valid (booking/transaction/session).
- Pembuatan booking paket atomic lewat RPC (booking + cycle + sesi).
- Expiry untuk session change request + notifikasi otomatis.
- Perbaikan lifecycle dispute agar lebih jelas dan konsisten.

Artefak:
- DB:
  - `supabase/migrations/202604210013_milestone12_harden_state_transitions.sql`
  - `supabase/migrations/202604210014_milestone12_atomic_booking_create.sql`
  - `supabase/migrations/202604210015_milestone12_request_expiry.sql`
  - `supabase/migrations/202604210016_milestone12_dispute_lifecycle.sql`
  - `supabase/migrations/202604210017_milestone12_expiry_notifications.sql`

## Milestone 13 - Learning Progress + Smart Reminders
Output:
- Catatan materi dan PR per sesi (`session_learning_records`).
- Reminder H-24 dan H-2 sebelum sesi + tombol konfirmasi hadir.
- Tap notifikasi fokus ke sesi terkait (auto-scroll + highlight).

Artefak:
- DB:
  - `supabase/migrations/202604210018_milestone13_learning_progress_homework.sql`
  - `supabase/migrations/202604210019_milestone13_smart_reminders.sql`

## Catatan UI/UX dan Stabilitas
Selain milestone fungsional, terdapat aktivitas polishing/hardening:
- Pesan error lebih ramah, loading/empty/retry state.
- Perbaikan konsistensi bottom navigation untuk halaman shell.
- Perbaikan tampilan detail tutor, profile, dan dashboard agar mendekati mockup.
- Perbaikan reliability realtime (retry/timeout handling) untuk web dan device.

