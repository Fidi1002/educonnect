# Screenshot Feature Checklist

Dokumen ini membantu pengambilan screenshot final agar hasil dokumentasi aplikasi rapi, konsisten, dan mudah dipakai untuk laporan atau sidang.

## Panduan Umum

- Gunakan data demo yang stabil sebelum mulai screenshot.
- Jika memungkinkan, gunakan ukuran layar yang konsisten.
- Untuk web, gunakan zoom 100%.
- Untuk mobile, gunakan emulator/device dengan rasio yang seragam.
- Ambil screenshot setelah state loading selesai.
- Hindari mengambil screenshot pada state error kecuali memang ingin dijadikan bukti pengujian.

## Format Nama File yang Disarankan

Gunakan pola:
`fitur_nomor_nama-halaman.png`

Contoh:
- `01_login.png`
- `02_register.png`
- `03_onboarding-role.png`
- `04_student-home.png`
- `05_tutor-list.png`
- `06_tutor-detail.png`
- `07_student-booking.png`
- `08_tutor-booking.png`
- `09_chat.png`
- `10_notifications.png`
- `11_student-calendar.png`
- `12_learning-journal.png`
- `13_student-profile.png`
- `14_tutor-dashboard.png`
- `15_tutor-profile.png`
- `16_tutor-availability.png`

## Checklist Screenshot per Fitur

### 1. Autentikasi
- [ ] Halaman login
- [ ] Halaman registrasi
- [ ] Halaman onboarding role

Contoh caption:
- "Halaman login pengguna pada aplikasi EduConnect."
- "Halaman registrasi akun baru pada aplikasi EduConnect."
- "Halaman pemilihan role murid atau tutor setelah registrasi."

### 2. Murid - Dashboard dan Pencarian Tutor
- [ ] Student home / dashboard murid
- [ ] Search bar dan section radius tutor
- [ ] Halaman daftar tutor
- [ ] Filter tutor (mapel, harga, rating, jarak)
- [ ] Halaman detail tutor

Contoh caption:
- "Halaman beranda murid yang menampilkan ringkasan jadwal, progres, dan pencarian tutor."
- "Halaman daftar tutor berdasarkan hasil pencarian dan filter yang dipilih pengguna."
- "Halaman detail tutor yang menampilkan informasi profil, mapel, dan CTA booking."

### 3. Murid - Booking dan Pembelajaran
- [ ] Form booking tutor
- [ ] Halaman booking murid
- [ ] Status pembayaran booking
- [ ] Kalender belajar murid
- [ ] Learning journal / jurnal belajar
- [ ] PR atau materi yang telah direkam

Contoh caption:
- "Halaman booking murid yang menampilkan status paket belajar dan sesi aktif."
- "Halaman kalender belajar murid yang menampilkan jadwal sesi per tanggal."
- "Halaman jurnal belajar murid yang menampilkan materi, PR, dan progres pembelajaran."

### 4. Murid - Komunikasi
- [ ] Halaman inbox
- [ ] Halaman chat student-tutor
- [ ] Halaman notifikasi

Contoh caption:
- "Halaman inbox yang menampilkan daftar percakapan antara murid dan tutor."
- "Halaman chat real-time yang digunakan untuk komunikasi terkait booking."
- "Halaman notifikasi yang menampilkan informasi booking, reminder, dan chat."

### 5. Murid - Profil
- [ ] Halaman profil murid
- [ ] Halaman e-book / resource bila dipakai dalam laporan

### 6. Tutor - Dashboard dan Operasional
- [ ] Halaman dashboard tutor
- [ ] Halaman booking tutor
- [ ] Halaman murid aktif tutor
- [ ] Halaman kalender tutor
- [ ] Halaman availability tutor
- [ ] Halaman profil tutor
- [ ] Halaman form edit profil tutor

Contoh caption:
- "Halaman dashboard tutor yang menampilkan ringkasan booking, sesi, dan murid aktif."
- "Halaman booking tutor untuk menerima, menolak, dan memantau paket belajar murid."
- "Halaman pengaturan ketersediaan waktu tutor."

## Screenshot Pengujian (Opsional untuk Lampiran)

Jika ingin memperkuat bagian pengujian, tambahkan screenshot berikut:
- [ ] Booking berhasil diajukan
- [ ] Booking diterima tutor
- [ ] Status menunggu pembayaran
- [ ] Booking aktif setelah payment dummy
- [ ] Chat berhasil berjalan
- [ ] Notifikasi masuk
- [ ] Reminder sesi / fokus ke sesi tertentu

## Saran Folder Penyimpanan

Buat folder terpisah di luar source code, misalnya:
- `screenshots/final/`
- `screenshots/testing/`

Dengan cara ini, file gambar mudah dipakai ulang untuk Word, PowerPoint, atau lampiran skripsi.
