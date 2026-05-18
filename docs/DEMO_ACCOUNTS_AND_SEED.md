# Demo Accounts and Seed Checklist

Dokumen ini membantu menyiapkan akun demo dan data minimum agar presentasi EduConnect berjalan mulus.

## Prinsip Umum

Untuk demo aplikasi, hindari memakai akun acak atau data yang berubah-ubah. Gunakan akun yang stabil dan dataset yang sudah dicek sebelumnya.

## Akun Demo yang Disarankan

Siapkan minimal 2 akun:

### 1. Akun Murid Demo
- Role: `student`
- Tujuan: menunjukkan flow pencarian tutor, booking, chat, notifikasi, kalender, dan jurnal belajar

Template:
- Nama: `Demo Murid`
- Email: `demo.student@educonnect.local`
- Password: `Isi sesuai akun demo yang kamu buat`

### 2. Akun Tutor Demo
- Role: `tutor`
- Tujuan: menunjukkan flow profil tutor, availability, approval booking, sesi, chat, dan PR

Template:
- Nama: `Demo Tutor`
- Email: `demo.tutor@educonnect.local`
- Password: `Isi sesuai akun demo yang kamu buat`

## Data Minimum yang Harus Tersedia Sebelum Demo

### Untuk Akun Tutor
- [ ] profil tutor sudah lengkap
- [ ] foto tutor tersedia
- [ ] mapel tersedia
- [ ] harga tersedia
- [ ] bio tersedia
- [ ] lokasi tutor valid
- [ ] availability tutor sudah diisi

### Untuk Akun Murid
- [ ] akun bisa login normal
- [ ] student home menampilkan tutor
- [ ] minimal ada 1 booking aktif
- [ ] minimal ada 1 riwayat booking
- [ ] minimal ada 1 sesi mendatang
- [ ] minimal ada 1 entri jurnal belajar / PR

## Seed Data yang Disarankan

Agar demo lebih hidup, siapkan data berikut:

### Booking
- [ ] 1 booking `pending`
- [ ] 1 booking `awaiting_payment`
- [ ] 1 booking `paid`
- [ ] 1 booking `completed`

### Session
- [ ] 1 sesi `scheduled`
- [ ] 1 sesi `done_pending_confirmation`
- [ ] 1 sesi `confirmed`
- [ ] 1 sesi dengan jejak reschedule atau cancel

### Chat
- [ ] minimal 1 percakapan student-tutor
- [ ] minimal 2-3 pesan dua arah

### Notification
- [ ] 1 notifikasi booking
- [ ] 1 notifikasi chat
- [ ] 1 notifikasi reminder / perubahan sesi

### Learning Journal
- [ ] 1 materi belajar
- [ ] 1 PR assigned
- [ ] 1 PR submitted/reviewed

## Checklist Demo Harian

Sebelum presentasi, cek cepat:
- [ ] akun murid bisa login
- [ ] akun tutor bisa login
- [ ] daftar tutor tampil
- [ ] detail tutor tampil
- [ ] booking page bisa dibuka
- [ ] chat bisa dibuka
- [ ] notifikasi bisa dibuka
- [ ] kalender bisa dibuka
- [ ] jurnal belajar tampil

## Saran Penyimpanan Informasi Demo

Jangan taruh password akun demo di dokumen publik. Simpan pada salah satu tempat berikut:
- file lokal pribadi yang tidak di-commit
- password manager
- catatan presentasi pribadi

Di repo ini, cukup simpan template akun dan checklist datanya.

## Catatan untuk Skripsi / Demo Sidang

Saat presentasi, tidak semua fitur harus didemokan penuh dari nol. Yang lebih penting adalah memperlihatkan alur utama secara meyakinkan. Karena itu, seed data sangat membantu untuk:
- mempercepat demo
- menghindari proses yang terlalu panjang
- menunjukkan kondisi sistem yang sudah jadi
