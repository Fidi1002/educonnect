# E2E Phase 1 Manual Test (Email Only)

Environment:
- Date:
- Device/Emulator:
- Build command:
  flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon> --dart-define=ENABLE_GOOGLE_AUTH=false

## A. Auth & Role

- [ ] Register akun baru (email/password valid)
  - Expected: login sukses, diarahkan ke halaman pilih role.
- [ ] Login akun existing
  - Expected: masuk app tanpa error auth.
- [ ] Onboarding pilih Murid
  - Expected: role tersimpan `student`, masuk ke student home.
- [ ] Onboarding pilih Tutor
  - Expected: role tersimpan `tutor`, masuk ke tutor home.
- [ ] Forgot password
  - Expected: notifikasi link reset terkirim.

## B. Tutor Profile

- [ ] Dari akun tutor, buka edit profil.
- [ ] Isi bio, mapel, harga, pengalaman, lokasi GPS/manual.
- [ ] Upload foto profil.
  - Expected: profil tersimpan, foto tampil, tidak error policy.
- [ ] Nonaktifkan profil.
  - Expected: `is_active=false`, profil tidak muncul di pencarian murid.

## C. Nearby Search (Student)

- [ ] Ambil lokasi GPS.
  - Expected: koordinat tampil, marker user muncul.
- [ ] Ubah radius 1 km.
- [ ] Ubah radius 5 km.
- [ ] Ubah radius 10 km.
- [ ] Ubah radius 20 km.
  - Expected: jumlah tutor menyesuaikan radius, urutan by distance.
- [ ] Set lokasi manual valid.
  - Expected: nearby update sesuai titik baru.
- [ ] Set lokasi manual invalid.
  - Expected: muncul pesan validasi koordinat.

## D. Error/Retry UX

- [ ] Matikan internet lalu refresh list tutor.
  - Expected: muncul state error + tombol `Coba lagi`.
- [ ] Nyalakan internet lalu klik `Coba lagi`.
  - Expected: data kembali normal.

## Result Summary

- Passed:
- Failed:
- Notes:
