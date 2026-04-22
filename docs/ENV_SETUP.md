# Environment Setup (Flutter + Supabase)

Dokumen ini menjelaskan cara menjalankan EduConnect secara lokal (Chrome/Android) menggunakan Supabase sebagai backend.

## Prasyarat
- Flutter SDK terpasang dan `flutter doctor` sudah hijau untuk target yang digunakan.
- Aplikasi sudah memiliki project Supabase (URL + anon key).
- Untuk Android emulator/perangkat: Android SDK + device terdeteksi (`flutter devices`).

## Konfigurasi Runtime (dart-define)
Aplikasi membaca konfigurasi Supabase melalui `--dart-define` (tidak disimpan di repo agar aman).

Parameter yang digunakan:
- `SUPABASE_URL`: URL project Supabase (contoh format: `https://<project-ref>.supabase.co`)
- `SUPABASE_ANON_KEY`: publishable/anon key dari Supabase
- `ENABLE_GOOGLE_AUTH`: `true/false` (untuk sementara dapat `false` bila Google provider belum aktif)

Contoh menjalankan di Chrome:
```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY `
  --dart-define=ENABLE_GOOGLE_AUTH=false
```

Contoh menjalankan di Android device/emulator:
```powershell
flutter run -d <device_id> `
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY `
  --dart-define=ENABLE_GOOGLE_AUTH=false
```

Catatan:
- Jangan menulis `SUPABASE_ANON_KEY` secara hardcode di source code atau commit ke Git.
- Bila muncul error "configuration not found", hampir selalu berarti `--dart-define` belum diberikan atau salah format.

## Mengambil Supabase URL dan Anon Key
Di Supabase Dashboard:
- Project Settings -> API
- Ambil:
  - Project URL
  - Project API keys -> `anon` / `publishable` key

## Google Auth (Opsional)
Jika ingin mengaktifkan Google provider:
1. Supabase Dashboard -> Authentication -> Providers -> Google -> Enable.
2. Tambahkan redirect URL yang digunakan aplikasi (misalnya custom scheme):
   - `io.supabase.educonnect://login-callback/`
3. Jalankan app dengan `--dart-define=ENABLE_GOOGLE_AUTH=true`.

Jika Google provider belum siap, gunakan email/password flow terlebih dahulu dan set `ENABLE_GOOGLE_AUTH=false`.

