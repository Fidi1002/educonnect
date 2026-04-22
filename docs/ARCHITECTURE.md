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

## Domain Rules (Business Rules)
Business rules dijaga di 2 sisi:
1. Klien (Flutter) untuk UX (validasi awal, disable button, pesan error)
2. Database (Supabase) untuk otorisasi & integritas data:
   - Trigger untuk transisi status booking/transaction/session
   - Validasi request reschedule/cancel
   - Expiry request (SLA) dan notifikasi otomatis

