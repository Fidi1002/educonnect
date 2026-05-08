# Architecture

## Flutter App Structure
Pola yang digunakan adalah modular per fitur (feature-first) dengan pemisahan layer:
- `domain/` untuk model dan enum status
- `data/` untuk repository (akses Supabase)
- `application/` untuk controller/provider (Riverpod)
- `presentation/` untuk UI pages/widgets

State management menggunakan Riverpod, routing menggunakan `go_router`.

## Routing (GoRouter)
Router utama berada di `lib/app/routes/app_router.dart`.

Konsep penting:
- Setelah login, user diarahkan sesuai role:
  - Murid: shell route dengan bottom navigation (Home, Kelas, E-Book, Profil)
  - Tutor: route dashboard tutor + halaman pendukung
- Halaman notifikasi berada di luar shell (akses dari icon bell).

## Realtime
Realtime digunakan untuk:
- notifikasi (`app_notifications`)
- chat (realtime messages)
- data booking/sessions yang di-stream dari Supabase

Terkait reliability, stream dibungkus util `resilientStream` untuk menjaga koneksi saat realtime putus sementara.

## Notifikasi & Reminder
Arsitektur notifikasi sekarang dibagi menjadi 3 lapisan:
- `messages` -> trigger database membuat `app_notifications` otomatis untuk percakapan booking
- `app_notifications` -> realtime in-app notification + deep-link ke booking/chat/session
- `push_delivery_queue` -> antrean backend untuk device push notification

Reminder sesi H-24 dan H-2 tidak lagi dipicu dari halaman Flutter. Sumber utamanya dipindah ke backend melalui function `process_due_session_reminders()` yang dapat dijalankan oleh `pg_cron`, Supabase scheduler, atau edge function terjadwal.

Untuk push notification device-level, repo sudah menyiapkan:
- `user_push_tokens` untuk registrasi token perangkat
- `push_delivery_queue` untuk antrian kirim
- edge function `process-reminders`
- edge function `dispatch-push`

`dispatch-push` sekarang memakai FCM HTTP v1 berbasis OAuth 2.0 service account, bukan lagi legacy server key.

Dengan pola ini, UI tidak menjadi trigger utama notifikasi yang sensitif waktu.

## Domain Rules (Business Rules)
Business rules dijaga di 2 sisi:
1. Klien (Flutter) untuk UX (validasi awal, disable button, pesan error)
2. Database (Supabase) untuk otorisasi & integritas data:
   - Trigger untuk transisi status booking/transaction/session
   - Validasi request reschedule/cancel
   - Expiry request (SLA) dan notifikasi otomatis
