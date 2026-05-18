# Final Test Scenarios

Dokumen ini merangkum skenario pengujian final EduConnect yang disarankan sebelum demo, presentasi, atau finalisasi laporan.

## Tujuan

Pengujian final bertujuan memastikan bahwa alur utama aplikasi berjalan konsisten dari sudut pandang murid, tutor, dan backend. Fokus utama bukan hanya pada tampilan, tetapi pada integritas data, transisi status, serta pengalaman penggunaan end-to-end.

## Prasyarat

Sebelum memulai pengujian:
- database Supabase sudah menggunakan migration terbaru
- akun demo murid dan tutor sudah tersedia
- profil tutor sudah terisi
- availability tutor sudah diset
- data tutor sudah bisa muncul di daftar pencarian
- koneksi realtime Supabase dalam kondisi normal
- jika menguji push/device reminder, token device dan queue notifikasi sudah siap

## Skenario 1 - Auth dan Role

### Tujuan
Memastikan user dapat masuk sesuai role dan data role terbaca konsisten.

### Langkah uji
1. Register akun baru.
2. Pilih role murid atau tutor.
3. Logout.
4. Login kembali dengan akun yang sama.
5. Pastikan user diarahkan ke halaman sesuai role.

### Hasil yang diharapkan
- login berhasil
- role tetap tersimpan
- route setelah login sesuai role

## Skenario 2 - Tutor Discovery

### Tujuan
Memastikan murid dapat menemukan tutor sesuai pencarian dan radius.

### Langkah uji
1. Login sebagai murid.
2. Buka student home.
3. Ubah radius pencarian ke 1, 5, 10, dan 20 km.
4. Gunakan filter mapel, harga, rating, dan jarak.
5. Buka detail tutor dari hasil pencarian.

### Hasil yang diharapkan
- daftar tutor berubah sesuai radius
- filter bekerja sesuai input
- detail tutor tampil lengkap

## Skenario 3 - Booking Paket Belajar

### Tujuan
Memastikan alur booking dari murid ke tutor berjalan valid.

### Langkah uji
1. Login sebagai murid.
2. Buka detail tutor.
3. Pilih paket belajar (1/2/3/6 bulan sesuai aturan yang dipakai).
4. Pilih jadwal mingguan yang tersedia.
5. Submit booking.

### Hasil yang diharapkan
- booking tercatat dengan status `pending`
- tutor dapat melihat booking baru di halaman booking tutor
- sesi belum aktif sebelum pembayaran selesai jika flow aktivasi sesi setelah payment digunakan

## Skenario 4 - Approval dan Payment

### Tujuan
Memastikan transisi booking dan transaksi berjalan sesuai aturan.

### Langkah uji
1. Login sebagai tutor.
2. Terima booking murid.
3. Login kembali sebagai murid.
4. Lakukan payment dummy.
5. Buka ulang halaman booking murid dan tutor.

### Hasil yang diharapkan
- status booking berubah dari `pending` ke `awaiting_payment`
- setelah pembayaran, status berubah menjadi `paid`
- sesi belajar aktif/generate sesuai flow terbaru

## Skenario 5 - Session Lifecycle

### Tujuan
Memastikan siklus sesi belajar berjalan dari mulai hingga konfirmasi.

### Langkah uji
1. Tutor membuka booking aktif.
2. Tutor menandai sesi dimulai.
3. Setelah waktu sesi selesai, tutor menandai sesi selesai.
4. Murid membuka booking dan mengonfirmasi sesi.
5. Ulangi satu skenario lagi dengan dispute/no-show bila diperlukan.

### Hasil yang diharapkan
- sesi berpindah status sesuai aturan
- murid dapat mengonfirmasi sesi
- dispute/no-show hanya dapat dilakukan pada kondisi yang valid

## Skenario 6 - Reschedule dan Cancel

### Tujuan
Memastikan request perubahan sesi terkendali.

### Langkah uji
1. Murid atau tutor membuat request reschedule.
2. Lawan pihak merespons request.
3. Ulangi dengan request cancel.
4. Cek notifikasi dan status sesi terkait.

### Hasil yang diharapkan
- request tersimpan sebagai pending
- pihak yang berwenang dapat approve/reject
- status sesi berubah sesuai hasil request
- deep-link notifikasi menuju booking/sesi terkait

## Skenario 7 - Chat dan Notifikasi

### Tujuan
Memastikan komunikasi real-time berjalan selama booking aktif.

### Langkah uji
1. Student kirim pesan ke tutor dari halaman chat booking.
2. Tutor membuka inbox/chat.
3. Kirim balasan.
4. Buka halaman notifikasi.
5. Tap notifikasi chat atau booking.

### Hasil yang diharapkan
- pesan baru muncul pada kedua sisi
- unread count berubah
- notifikasi chat dan booking muncul sesuai event
- tap notifikasi membuka halaman target yang benar

## Skenario 8 - Learning Journal dan PR

### Tujuan
Memastikan tutor dapat menambahkan materi/PR dan murid dapat melihat progres.

### Langkah uji
1. Tutor membuka sesi pada booking aktif.
2. Tutor mengisi materi atau PR.
3. Murid membuka learning journal.
4. Murid submit PR bila fitur submit tersedia.
5. Tutor review PR.

### Hasil yang diharapkan
- materi dan PR tampil di jurnal belajar murid
- status PR berubah sesuai aksi submit/review
- riwayat pembelajaran tersimpan

## Skenario 9 - Reminder dan Kalender

### Tujuan
Memastikan sesi tampil benar pada kalender dan reminder bekerja sesuai desain.

### Langkah uji
1. Buka kalender murid.
2. Buka kalender tutor.
3. Pastikan sesi booked tampil pada tanggal yang sesuai.
4. Jalankan proses reminder backend bila perlu.

### Hasil yang diharapkan
- kalender mengambil data dari sesi aktif
- badge status tampil sesuai status sesi
- reminder menghasilkan notifikasi sesuai window waktu yang diatur

## Skenario 10 - Negative Testing

### Tujuan
Memastikan database menolak aksi yang tidak valid.

### Langkah uji
1. Coba ubah status dari role yang tidak berwenang.
2. Coba aksi session transition yang tidak sesuai urutan.
3. Coba mengakses data role lain secara tidak sah.

### Hasil yang diharapkan
- aksi ditolak oleh backend
- data tidak berubah
- UI menampilkan pesan yang sesuai atau tetap aman

## Acceptance Criteria Final

Pengujian final dianggap lulus bila:
- alur auth, search, booking, payment, session, chat, dan notifikasi berjalan
- tidak ada error kritis yang memblokir role murid atau tutor
- status booking/sesi konsisten antara UI dan database
- tidak ada transisi status ilegal yang lolos
- data demo cukup stabil untuk dipresentasikan

## Rekomendasi Output Pengujian

Simpan hasil pengujian final dalam bentuk:
- checklist manual lulus/gagal
- screenshot hasil penting
- catatan bug yang ditemukan
- status perbaikan bug

Dengan begitu, hasil pengujian bisa dipakai untuk laporan teknis maupun lampiran skripsi.
