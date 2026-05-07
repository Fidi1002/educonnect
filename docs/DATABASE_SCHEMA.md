# Database Schema (Supabase/PostgreSQL)

Dokumen ini merangkum tabel inti, relasi, serta aturan keamanan/integritas yang digunakan oleh EduConnect.

Sumber utama skema berada pada folder migrasi: `supabase/migrations/`.

## Prinsip Desain
1. RLS (Row Level Security) aktif pada seluruh tabel inti untuk membatasi akses per user.
2. Aturan bisnis yang kritikal (status flow) dipaksakan di level database (trigger/function), bukan hanya di UI.
3. Operasi penting yang harus atomic (contoh: pembuatan booking paket beserta sesi) dilakukan lewat RPC.

## Tabel Inti

### 1) `public.users`
Profil dasar user yang terhubung ke `auth.users`.
- PK: `uid` (UUID) mereferensikan `auth.users(id)`
- Field penting: `role` (`unknown|student|tutor`), `display_name`, `photo_url`
- RLS: user hanya bisa select/insert/update data miliknya sendiri.

### 2) `public.tutors`
Profil tutor yang dapat ditampilkan pada pencarian.
- PK: `uid` (sama dengan `users.uid`)
- Field penting: `bio`, `subjects` (array), `price_per_hour`, `experience_years`, `location_label`
- Lokasi: `latitude`, `longitude`, `geohash`, dan kolom generated `location` (PostGIS geography point)
- Visibility: tutor aktif (`is_active=true`) dapat dibaca oleh user authenticated; tutor nonaktif hanya dapat dibaca owner.
- Indeks: rating/price, serta gist index untuk query lokasi.

### 3) `public.tutor_availability`
Slot ketersediaan tutor per hari.
- FK: `tutor_uid` -> `tutors.uid`
- Field penting: `weekday` (1-7), `start_time`, `end_time`, `is_active`
- RLS: tutor hanya bisa CRUD slot miliknya.

### 4) `public.bookings`
Entitas utama pemesanan paket belajar.
- FK: `student_uid` -> `users.uid`, `tutor_uid` -> `tutors.uid`
- Paket: `package_months` (1/2/3/6), `sessions_per_week` (=2), `weekly_schedule` (JSON array 2 slot)
- Rentang paket: `package_start_date`, `package_end_date`
- Hold/expiry: `expires_at` dipakai untuk batas waktu booking `pending` dan `awaiting_payment`
- Status booking (ringkas): `pending -> awaiting_payment -> paid -> completed` (+ `rejected`, `cancelled`)
- Validasi database:
  - Trigger `validate_package_booking()` memastikan:
    - weekly_schedule tepat 2 slot
    - slot berada di availability tutor
    - tidak bentrok dengan murid aktif lain atau pending hold yang belum expired
    - kapasitas tutor maksimum 2 murid aktif/held untuk periode overlap

### 5) `public.transactions`
Transaksi pembayaran (dummy) yang terkait booking, per siklus bulanan.
- Unique per booking + cycle: indeks unik `(booking_id, cycle_number)`
- Field penting: `amount`, `payment_status` (`pending|paid|failed|refunded`), `due_at`, `paid_at`
- RLS: dapat dibaca oleh student/tutor peserta booking.

### 6) `public.booking_sessions`
Sesi pertemuan aktual yang dihasilkan dari booking paket.
- FK: `booking_id` -> `bookings.id`, plus `student_uid` dan `tutor_uid`
- Field penting: `session_start`, `session_end`
- Lifecycle: sesi baru digenerate setelah booking berstatus `paid`, bukan saat masih `pending`
- Status sesi (contoh): `scheduled`, `done_pending_confirmation`, `confirmed`, `disputed`, `rescheduled`, `cancelled_*`, `*_no_show`
- Field reminder/attendance: `student_presence_confirmed_at`, `reminder_h24_sent_at`, `reminder_h2_sent_at`
- RLS: dapat diakses oleh student/tutor peserta booking.

### 7) `public.session_change_requests`
Permintaan reschedule/cancel yang harus disetujui oleh pihak lain.
- FK: `session_id` -> `booking_sessions.id`, `booking_id` -> `bookings.id`
- Field penting:
  - `request_type` (`reschedule|cancel`)
  - `status` (`pending|approved|rejected|cancelled|expired` tergantung versi migrasi)
  - `proposed_start/proposed_end` untuk reschedule
  - `expires_at` untuk batas waktu respon (SLA)
- RLS: hanya requester/target yang dapat melihat; insert hanya oleh requester.

### 8) `public.app_notifications`
Notifikasi in-app yang menerima deep-link ke target (booking/session).
- Field penting: `user_uid`, `actor_uid`, `category`, `target_type`, `target_id`, `is_read`
- RLS: only owner dapat membaca/mengubah read state; insert oleh actor.

### 9) `public.messages`
Chat realtime per booking.
- Field penting: `booking_id`, `sender_uid`, `receiver_uid`, `body`, `read_at`
- RLS: hanya peserta chat (sender/receiver) yang dapat membaca; insert oleh sender; update read hanya oleh receiver.

### 10) `public.session_learning_records`
Catatan materi dan PR per sesi.
- 1:1 dengan sesi: `session_id` unique.
- Flow PR dipaksa database:
  - Tutor: assign/review
  - Murid: submit
- RLS: peserta sesi dapat membaca; insert record oleh tutor; update mengikuti aturan transition function.

## RPC Penting
Beberapa aksi kompleks disediakan sebagai function (RPC) agar atomic dan aman:
- `get_nearby_tutors(...)`: query tutor terdekat berbasis PostGIS.
- `process_student_session_reminders(student_uid)`: membuat notifikasi reminder H-24 dan H-2 (untuk sesi yang akan datang).
- (Tambahan dari milestone hardening) RPC untuk pembuatan booking paket secara atomic (lihat migrasi `milestone12_atomic_booking_create`).

## Catatan Keamanan
- RLS adalah batas keamanan utama. Jangan mematikan RLS pada tabel inti di production.
- Jika melakukan perubahan status di UI, pastikan server-side trigger tetap menjadi "source of truth" untuk validasi.
