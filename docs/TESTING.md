# Testing Guide (Manual E2E + Regression)

Dokumen ini menyatukan langkah pengujian manual yang digunakan selama pengembangan EduConnect.

## Cara Menjalankan Aplikasi untuk Testing
Lihat `docs/ENV_SETUP.md` untuk command `flutter run` beserta konfigurasi `--dart-define`.

Rekomendasi untuk smoke test cepat:
- Jalankan di Chrome untuk iterasi UI/logic cepat.
- Jalankan di Android device untuk validasi lokasi, permission, dan behavior native.

## Checklist E2E (Phase 1)
Dokumen:
- `docs/e2e-phase1-manual-test.md`
- `docs/phase1-post-push-checklist.md`

Fokus:
- Register/login
- Role onboarding
- Tutor profile + upload foto
- Student nearby search (1/5/10/20 km)

## Checklist Milestone Lanjutan
Dokumen:
- `docs/milestone5-e2e-checklist.md` (booking)
- `docs/milestone6-e2e-checklist.md` (payment dummy)
- `docs/milestone7-e2e-checklist.md` (chat + realtime)
- `docs/milestone8-e2e-checklist.md` (availability + scheduling)
- `supabase/migrations/202605070001_milestone15_booking_schedule_activation.sql` (booking hold/expiry + aktivasi sesi setelah bayar)

## Skenario Regression Minimal (Disarankan)
Setiap kali ada perubahan besar pada DB migrations atau logic booking/sessions, lakukan hard-test ini:

1) Auth + Role
- Register -> pilih role -> logout -> login ulang -> role tetap terbaca.

2) Pencarian Tutor
- Student -> nearby search -> radius 1/5/10/20 km -> list update dengan benar.

3) Booking Paket (Happy Path)
- Student membuat booking paket 1 bulan (2 slot/minggu).
- Tutor accept -> booking `awaiting_payment`.
- Student "pay" dummy -> booking `paid`.

4) Sesi dan Konfirmasi
- Tutor mark done pada satu sesi -> student confirm.
- Pastikan status sesi masuk `confirmed`.

5) Chat
- Kirim pesan dari student ke tutor dan sebaliknya.
- Unread badge/count berubah sesuai read state.

6) Notifikasi Deep-link
- Tap notifikasi reschedule/approval/reminder -> masuk halaman target dan fokus sesi yang tepat.
- Booking `pending` yang melewati SLA hold dan booking `awaiting_payment` yang melewati SLA pembayaran harus auto-expire menjadi `cancelled`.
- Kalender dan daftar sesi tidak boleh menampilkan sesi dari booking `pending`, `rejected`, atau `cancelled`.

7) Skenario Harus Ditolak DB (Negative)
- Student mencoba complete booking atau mengubah status transaksi yang bukan haknya.
- Tutor mencoba menandai transaksi menjadi paid tanpa flow yang benar.

Kriteria lulus:
- UI menampilkan error yang jelas (atau silent fail) dan data di DB tidak berubah.

## Regression Suite Booking
Regression suite booking sekarang disatukan dalam satu file:
- `test/booking/booking_regression_suite_test.dart`

Isi suite:
- Rule-level regression untuk `BookingStatus` dan `BookingSessionStatus`
- Remote hard-test flow booking:
  - `pending`
  - `awaiting_payment`
  - `paid`
  - session activation setelah bayar
  - expiry `pending` / `awaiting_payment`
  - filter source sesi agar hanya booking aktif yang tampil

Command yang direkomendasikan:
```bash
flutter test test/booking/booking_regression_suite_test.dart
```

Untuk menjalankan hard-test remote, isi environment:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
