# EduConnect

Fondasi proyek Flutter untuk aplikasi pencarian tutor terdekat (Supabase + Google Maps).

## Setup Lokal

1. Isi `MAPS_API_KEY` di `android/local.properties`.
2. Jalankan dependency:
   - `flutter pub get`
3. Jalankan app dengan kredensial Supabase:
   - `flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY --dart-define=ENABLE_GOOGLE_AUTH=false`
4. (Opsional Google OAuth) tambah redirect URL:
   - `--dart-define=SUPABASE_GOOGLE_REDIRECT_URL=io.supabase.educonnect://login-callback/`

## SQL Phase 1

- Schema + RLS + nearby RPC + storage policy:
  - `supabase/migrations/202604190001_phase1_auth_tutor_nearby.sql`
- Cleanup data tutor lama:
  - `supabase/migrations/202604190002_legacy_tutor_geo_cleanup.sql`

## Catatan

- Nearby search memakai RPC `get_nearby_tutors` (PostGIS).
- Upload foto tutor memakai bucket storage `tutor-photos`.
- Jika kredensial Supabase belum diisi, app menampilkan halaman setup guidance.
