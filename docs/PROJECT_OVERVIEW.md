# Project Overview (EduConnect)

## Tujuan
EduConnect adalah aplikasi pencarian tutor berbasis lokasi yang menghubungkan murid dan tutor. Setelah murid menemukan tutor yang sesuai, proses belajar dilanjutkan melalui booking paket, sesi pertemuan terjadwal, chat real-time, notifikasi in-app, kalender, serta pencatatan materi dan PR per sesi.

## Platform dan Teknologi
- Frontend: Flutter
- Backend: Supabase (Auth + PostgreSQL + Realtime)
- Lokasi: GPS/perizinan lokasi perangkat, radius pencarian 1/5/10/20 km

## Role Pengguna

### Murid
Murid berfokus pada penemuan tutor, pemesanan, dan aktivitas belajar.
Fitur utama yang tersedia:
- Registrasi/login (email; Google opsional sesuai konfigurasi)
- Onboarding role `student`
- Cari tutor terdekat (radius) + daftar tutor + detail tutor
- Booking paket belajar 1/2/3/6 bulan dengan jadwal tetap 2x/minggu (mengikuti slot availability tutor)
- Pembayaran simulasi (dummy) per siklus bulan
- Jadwal: daftar booking + kalender sesi berbasis `booking_sessions`
- Chat real time per booking
- Notifikasi in-app (status booking, perubahan sesi, reminder)
- Reminder pintar (H-24 dan H-2 sebelum sesi) + tombol konfirmasi hadir
- Progres belajar + riwayat materi dan PR per sesi

### Tutor
Tutor berfokus pada penyediaan profil, jadwal availability, pengelolaan booking/sesi, dan pendampingan belajar.
Fitur utama yang tersedia:
- Onboarding role `tutor`
- Lengkapi profil tutor + upload foto (Supabase Storage bucket `tutor-photos`)
- Atur availability (jadwal ketersediaan)
- Kelola booking: terima/tolak, lihat jadwal aktif/riwayat
- Kelola sesi: tandai sesi selesai, alur konfirmasi murid, reschedule/cancel (approve/reject), dan penutupan dispute
- Chat real time per booking
- Kalender mengajar + kartu "Sesi Hari Ini"
- Halaman "Murid Aktif" (maks 2 murid aktif) + ringkasan PR menunggu review
- Consistency score tutor (attendance/on-time/cancel rate) sebagai badge tambahan pada kartu/detail tutor

## Prinsip Data dan Keamanan
Desain sistem menempatkan aturan penting pada level database untuk menjaga integritas data:
- Akses data dibatasi dengan RLS (Row Level Security) di Supabase.
- Transisi status booking/transaksi/sesi dikunci di level database (trigger), sehingga skenario "harus ditolak DB" tetap aman walaupun ada bug UI.
- Proses pembuatan booking paket dibuat atomic lewat RPC agar tidak ada data "setengah jadi" (booking, cycle bulanan, dan sesi pertemuan dibuat dalam 1 transaksi).

