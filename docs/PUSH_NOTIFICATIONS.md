# Push Notifications & Reminder Backend

Dokumen ini menjelaskan fondasi backend notifikasi terbaru untuk EduConnect.

## Tujuan
Perubahan ini memindahkan alur sensitif waktu dari UI Flutter ke backend agar:
- reminder H-24 dan H-2 tetap diproses meski student tidak membuka aplikasi
- pesan chat baru otomatis memicu notifikasi
- notifikasi in-app dapat diteruskan ke push notification device-level

## Komponen yang Disiapkan

### 1) Trigger notif chat
Tabel `messages` sekarang memiliki trigger `trg_notify_chat_message_insert`.

Perilaku:
- setiap pesan baru -> buat `app_notifications`
- pesan pertama dalam sebuah booking -> judul khusus `Percakapan baru dimulai`
- pesan berikutnya -> judul `Pesan baru dari ...`

### 2) Reminder backend-driven
Function utama:
- `public.process_due_session_reminders()`

Function ini:
- mencari sesi `scheduled` dari booking `paid`
- mengirim reminder H-24 dan H-2
- menandai `reminder_h24_sent_at` / `reminder_h2_sent_at`

Function lama:
- `public.process_student_session_reminders(student_uid)`

Function lama masih dipertahankan sebagai wrapper/manual recovery, tetapi bukan lagi trigger utama dari UI.

### 3) Push notification foundation
Tabel:
- `public.user_push_tokens`
- `public.push_delivery_queue`

Alur:
1. aplikasi mendaftarkan token perangkat ke `user_push_tokens`
2. saat `app_notifications` dibuat, trigger otomatis membuat item pada `push_delivery_queue`
3. edge function `dispatch-push` mengambil queue pending lalu mengirim ke provider push

## Edge Functions

### `process-reminders`
Lokasi:
- `supabase/functions/process-reminders/index.ts`

Fungsi:
- memanggil RPC `process_due_session_reminders()`

### `dispatch-push`
Lokasi:
- `supabase/functions/dispatch-push/index.ts`

Fungsi:
- claim batch queue via `claim_pending_push_deliveries()`
- kirim push ke FCM HTTP v1 dengan OAuth 2.0 access token dari service account
- update status queue menjadi `sent` / `failed`

## Secret yang Dibutuhkan

Minimal:
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Untuk push FCM HTTP v1, pilih salah satu:
- `FIREBASE_SERVICE_ACCOUNT_JSON`
- `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`
- atau field terpisah:
  - `FIREBASE_PROJECT_ID`
  - `FIREBASE_CLIENT_EMAIL`
  - `FIREBASE_PRIVATE_KEY`

Contoh set secret paling praktis:
```bash
npx supabase secrets set FIREBASE_PROJECT_ID=aplikasi-educonnect-id
npx supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxx@aplikasi-educonnect-id.iam.gserviceaccount.com
npx supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

## Rekomendasi Deploy

### Opsi A — pg_cron
Jika project Supabase mengaktifkan `pg_cron`, migration akan mencoba membuat job:
- `educonnect-process-reminders`

Schedule:
- setiap 15 menit

### Opsi B — Edge Scheduler
Kalau `pg_cron` tidak aktif, jalankan scheduler eksternal untuk memanggil:
- edge function `process-reminders`
- edge function `dispatch-push`

Rekomendasi interval:
- `process-reminders`: tiap 15 menit
- `dispatch-push`: tiap 1 menit

Alternatif lain, jika ingin satu secret saja:
```bash
npx supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON_BASE64=ISI_BASE64_JSON
```

## Catatan Testing Invoke
Jika edge function dideploy dengan verifikasi JWT aktif (default Supabase), pemanggilan HTTP langsung akan membutuhkan JWT yang valid.

Artinya:
- `apikey` anon saja bisa berujung `401 Unauthorized`
- untuk test manual dari luar app, gunakan access token user yang valid atau service-role call lewat scheduler/backend

## Catatan Integrasi Flutter
Fondasi backend sudah siap, tetapi agar push device-level benar-benar aktif di Android/iOS, aplikasi Flutter tetap perlu:
- SDK push provider pada client
- pengambilan token device
- sinkronisasi token ke `user_push_tokens`
- permission prompt notifikasi native

Jadi status saat ini:
- in-app notification: siap
- backend reminder: siap
- push pipeline backend: siap
- registrasi token dari Flutter native: masih perlu dihubungkan pada tahap mobile push integration
