# Troubleshooting

Dokumen ini merangkum masalah yang sering muncul saat menjalankan EduConnect (Flutter + Supabase) dan cara mengatasinya.

## 1) "configuration not found" saat register/login
Penyebab paling umum:
- Aplikasi tidak mendapatkan `SUPABASE_URL` atau `SUPABASE_ANON_KEY`.

Solusi:
- Pastikan menjalankan `flutter run` dengan `--dart-define` (lihat `docs/ENV_SETUP.md`).
- Pastikan tidak ada karakter `<` `>` pada URL/key (gunakan nilai asli).

## 2) "email signup is disabled"
Penyebab:
- Email provider atau email signup dimatikan di Supabase Auth.

Solusi:
- Supabase Dashboard -> Authentication -> Providers -> Email -> aktifkan.

Catatan:
- Saat dev, beberapa tim mematikan email confirmation untuk mempercepat testing. Pastikan setting yang dimatikan tidak ikut mematikan signup.

## 3) "email rate limit exceeded"
Penyebab:
- Terlalu banyak percobaan signup/login dalam waktu singkat, atau environment Supabase menerapkan limit.

Solusi cepat:
- Tunggu beberapa saat dan coba lagi.
- Gunakan akun test yang sama (login ulang) daripada membuat akun baru berulang.
- Untuk dev cepat: nonaktifkan email confirmation (sementara) agar tidak memicu email provider.

## 4) RealtimeSubscribeException: timedOut
Penyebab umum:
- Koneksi websocket terputus/unstable, khususnya saat testing web.
- Firewall/proxy menghalangi websocket.

Solusi:
- Refresh halaman dan pastikan jaringan stabil.
- Coba target lain (Android device) untuk memastikan bukan masalah web-only.
- Pastikan URL Supabase benar dan project aktif.

Catatan teknis:
- Stream realtime sebaiknya dibungkus retry/backoff agar UI tidak "blank" ketika timeout sementara.

## 5) Error Web: "Cannot read properties of undefined (reading 'maps')"
Penyebab:
- Ada komponen yang mengakses API Google Maps di web tanpa script/config yang tersedia, atau widget mengasumsikan object map selalu ada.

Solusi:
- Jika fitur map belum diaktifkan untuk web, guard dengan `kIsWeb` dan fallback ke list-only.
- Pastikan akses data null-safe (cek `null` sebelum render bagian map).

## 6) Lokasi tidak muncul / permission ditolak
Solusi:
- Android: cek permission Location di settings aplikasi.
- Chrome: allow location pada site `localhost` dan refresh.
- Sediakan fallback input lokasi manual (jika fitur ini sudah diaktifkan).

## 7) `npx supabase ...` gagal di PowerShell
Penyebab:
- Kebijakan eksekusi PowerShell (ExecutionPolicy) atau path.

Solusi:
- Jalankan melalui cmd:
```powershell
cmd /c npx supabase db push
```

