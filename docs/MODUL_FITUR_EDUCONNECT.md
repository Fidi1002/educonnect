# MODUL FITUR APLIKASI EDUCONNECT
## Panduan Fungsional dan Teknis Fitur Sistem (Flutter & Supabase)

Modul ini mendokumentasikan seluruh fitur utama yang ada di dalam aplikasi **EduConnect**. Setiap modul menjelaskan tujuan, aktor yang terlibat, alur kerja (*workflow*), serta integrasi database/backend. Dokumentasi ini dapat digunakan sebagai lampiran skripsi, buku panduan pengguna (*user manual*), maupun dokumentasi pengembang (*developer guide*).

---

## DAFTAR MODUL FITUR

1. [Modul 1: Autentikasi dan Manajemen Peran (Auth & Role Selection)](#modul-1-autentikasi-dan-manajemen-peran-auth--role-selection)
2. [Modul 2: Profil Profesional & Ketersediaan Tutor (Tutor Profiles & Availability)](#modul-2-profil-profesional--ketersediaan-tutor-tutor-profiles--availability)
3. [Modul 3: Penemuan Tutor Berbasis Jarak Geospasial (Tutor Discovery)](#modul-3-penemuan-tutor-berbasis-jarak-geospasial-tutor-discovery)
4. [Modul 4: Pemesanan Paket Belajar Secara Mandiri (Atomic Package Booking)](#modul-4-pemesanan-paket-belajar-secara-mandiri-atomic-package-booking)
5. [Modul 5: Siklus Pertemuan & Validasi Kehadiran (Session Lifecycle & Attendance)](#modul-5-siklus-pertemuan--validasi-kehadiran-session-lifecycle--attendance)
6. [Modul 6: Pengajuan Perubahan Jadwal (Reschedule & Cancel Requests)](#modul-6-pengajuan-perubahan-jadwal-reschedule--cancel-requests)
7. [Modul 7: Chat Real-Time & Notifikasi Instan (Realtime Chat & In-App Notification)](#modul-7-chat-real-time--notifikasi-instan-realtime-chat--in-app-notification)
8. [Modul 8: Jurnal Belajar dan Penugasan Latihan (Learning Journal & Homework)](#modul-8-jurnal-belajar-dan-penugasan-latihan-learning-journal--homework)
9. [Modul 9: Pengingat Otomatis Sesi Belajar (Smart Reminder System)](#modul-9-pengingat-otomatis-sesi-belajar-smart-reminder-system)
10. [Modul 10: Sistem Dompet Digital Simulasi (Dummy Wallet & Transactions)](#modul-10-sistem-dompet-digital-simulasi-dummy-wallet--transactions)

---

### MODUL 1: AUTENTIKASI DAN MANAJEMEN PERAN (AUTH & ROLE SELECTION)

* **Tujuan**: Mengamankan akses aplikasi dan membagi hak akses pengguna berdasarkan peran (*role*) yang dipilih untuk menyajikan antarmuka yang relevan.
* **Aktor**: Murid, Tutor, dan Pengguna Baru (Tamu).
* **Alur Kerja (Workflow)**:
  1. Pengguna baru melakukan registrasi menggunakan Email dan Password.
  2. Supabase Auth mengirimkan token dan melakukan verifikasi sesi.
  3. Setelah login pertama kali, aplikasi mendeteksi apakah pengguna sudah memiliki peran (*role*). Jika belum, pengguna diarahkan ke halaman **Onboarding Role Selection**.
  4. Pengguna memilih peran: `student` (Murid) atau `tutor` (Tutor). Pilihan ini disimpan secara permanen pada tabel `public.users`.
  5. Setiap kali aplikasi dibuka, `go_router` akan membaca role pengguna dan mengarahkannya ke halaman utama yang sesuai (Beranda Murid atau Dashboard Tutor).
* **Integrasi Database**:
  * Tabel: `public.users` (menyimpan `uid`, `role`, `display_name`, `photo_url`).
  * Aturan RLS: Pengguna hanya diizinkan untuk mengubah dan membaca profil data miliknya sendiri (`auth.uid() = uid`).

---

### MODUL 2: PROFIL PROFESIONAL & KETERSEDIAAN TUTOR (TUTOR PROFILES & AVAILABILITY)

* **Tujuan**: Memungkinkan tutor untuk mempromosikan keahlian mereka dan mengatur slot waktu mengajar yang tersedia bagi murid.
* **Aktor**: Tutor.
* **Alur Kerja (Workflow)**:
  1. Pengguna dengan peran Tutor masuk ke menu **Profil Tutor**.
  2. Tutor melengkapi informasi profesional: biodata (*bio*), daftar mata pelajaran (*subjects*), tarif per jam (*price_per_hour*), pengalaman mengajar (*experience_years*), lokasi mengajar (*location_label*), dan mengunggah foto profil ke Supabase Storage bucket `tutor-photos`.
  3. Tutor masuk ke sub-menu **Availability Slots** untuk menambahkan hari (Senin s.d. Minggu) dan jam ketersediaan (misal: Senin jam 14:00 - 16:00).
  4. Slot yang aktif akan ditampilkan pada halaman detail tutor saat murid ingin melakukan pemesanan.
* **Integrasi Database**:
  * Tabel: `public.tutors` (profil tutor dan titik geospasial) & `public.tutor_availability` (slot ketersediaan mingguan).
  * Aturan RLS: Semua pengguna terautentikasi dapat melihat profil tutor aktif (`is_active = true`), namun hanya tutor pemilik yang dapat menambah, memperbarui, atau menghapus slot ketersediaan mereka.

---

### MODUL 3: PENEMUAN TUTOR BERBASIS JARAK GEOSPASIAL (TUTOR DISCOVERY)

* **Tujuan**: Memudahkan murid mencari dan menyaring tutor les privat terdekat berdasarkan koordinat GPS perangkat murid.
* **Aktor**: Murid.
* **Alur Kerja (Workflow)**:
  1. Murid membuka halaman Beranda. Aplikasi meminta izin akses lokasi perangkat (GPS).
  2. Murid menentukan radius pencarian yang diinginkan: **1 km, 5 km, 10 km, atau 20 km**.
  3. Aplikasi mengambil titik koordinat murid (*latitude* & *longitude*) lalu memanggil fungsi database RPC `get_nearby_tutors(...)`.
  4. Database memproses perhitungan jarak bumi secara spasial menggunakan ekstensi **PostGIS** dan mencocokkannya dengan koordinat lokasi tutor.
  5. Aplikasi menampilkan daftar tutor terdekat beserta informasi jarak dalam kilometer, mata pelajaran, tarif, serta *consistency score* tutor.
  6. Murid dapat menyaring hasil menggunakan filter mata pelajaran, harga maksimum, dan rating minimum.
* **Integrasi Database**:
  * Ekstensi: **PostGIS** (tipe data `geography(Point, 4326)` pada kolom `location` di tabel `public.tutors`).
  * RPC Function: `get_nearby_tutors(lat, lon, max_radius_meters, subject_filter, etc)`.

---

### MODUL 4: PEMESANAN PAKET BELAJAR SECARA MANDIRI (ATOMIC PACKAGE BOOKING)

* **Tujuan**: Mengelola proses transaksi pemesanan paket belajar secara terstruktur untuk mencegah tumpang tindih jadwal dan konflik kapasitas tutor.
* **Aktor**: Murid (Pemesan) dan Tutor (Penerima).
* **Alur Kerja (Workflow)**:
  1. Murid membuka detail tutor, lalu menekan tombol **Booking Paket**.
  2. Murid memilih durasi paket: **1 bulan, 2 bulan, 3 bulan, atau 6 bulan**.
  3. Murid memilih **2 slot jadwal mingguan** dari ketersediaan jadwal tutor yang terdaftar.
  4. Murid mengirimkan pemesanan. Database memicu fungsi RPC `create_atomic_booking(...)` untuk memastikan pembuatan data booking bersifat aman:
     * Validasi: Sistem memeriksa apakah slot yang dipilih bentrok dengan murid lain, atau kapasitas tutor melampaui batas (maksimal 2 murid aktif dalam periode yang sama).
     * Jika valid, sistem membuat data di tabel `bookings` dengan status `pending` dan mengunci (*hold*) jadwal tersebut untuk sementara waktu.
  5. Tutor menerima notifikasi booking baru. Tutor dapat memilih **Terima (Approve)** atau **Tolak (Reject)**.
  6. Jika tutor menyetujui, status booking berubah menjadi `awaiting_payment` dan murid diarahkan untuk melakukan pembayaran.
* **Integrasi Database**:
  * Tabel: `public.bookings` (status: `pending`, `awaiting_payment`, `paid`, `completed`, `rejected`, `cancelled`).
  * Trigger: `validate_package_booking()` untuk menegakkan aturan bisnis di tingkat server.

---

### MODUL 5: SIKLUS PERTEMUAN & VALIDASI KEHADIRAN (SESSION LIFECYCLE & ATTENDANCE)

* **Tujuan**: Mengatur pelaksanaan sesi tatap muka belajar secara bertahap dan merekam kehadiran murid secara transparan.
* **Aktor**: Tutor (Pelaksana Sesi) dan Murid (Konfirmator).
* **Alur Kerja (Workflow)**:
  1. Setelah booking berstatus `paid` (lunas), sistem backend secara otomatis menghasilkan sesi-sesi pertemuan aktual (`booking_sessions`) sesuai jadwal mingguan selama durasi paket.
  2. Menjelang waktu sesi, status sesi adalah `scheduled`.
  3. Saat sesi dimulai, tutor masuk ke aplikasi dan menekan tombol **Mulai Sesi** (status berubah menjadi `in_progress`).
  4. Setelah sesi selesai, tutor menekan tombol **Selesaikan Sesi**. Status berubah menjadi `done_pending_confirmation`.
  5. Murid menerima notifikasi untuk mengonfirmasi kehadiran. Murid menekan tombol **Konfirmasi Kehadiran**. Status sesi final berubah menjadi `confirmed`.
  6. Jika terdapat ketidaksesuaian (tutor tidak datang tapi menandai selesai), murid dapat menekan **Dispute** untuk membekukan sesi tersebut guna mediasi.
* **Integrasi Database**:
  * Tabel: `public.booking_sessions`.
  * Trigger Keamanan: Trigger database membatasi transisi status sesi agar harus berurutan dan hanya dapat diubah oleh aktor yang berwenang (misal: hanya murid yang bisa mengubah dari `done_pending_confirmation` ke `confirmed`).

---

### MODUL 6: PENGAJUAN PERUBAHAN JADWAL (RESCHEDULE & CANCEL REQUESTS)

* **Tujuan**: Memfasilitasi fleksibilitas waktu belajar dengan aturan yang adil bagi murid maupun tutor agar tidak merugikan salah satu pihak.
* **Aktor**: Murid dan Tutor (Requester & Target).
* **Alur Kerja (Workflow)**:
  1. Aktor yang ingin mengubah jadwal (misal: Murid berhalangan hadir) membuka detail sesi pada kalender lalu mengajukan **Reschedule Request**.
  2. Pengaju memilih tanggal dan jam baru yang diusulkan (*proposed schedule*). Status sesi berubah sementara menjadi `reschedule_pending`.
  3. Sesi perubahan dicatat pada tabel `session_change_requests` dengan batas waktu respons (SLA).
  4. Aktor penerima (Tutor) mendapatkan notifikasi dan dapat menekan **Setuju (Approve)** atau **Tolak (Reject)**.
  5. Jika disetujui, koordinat waktu sesi aktual diperbarui secara otomatis ke jadwal baru. Jika ditolak, sesi kembali ke jadwal semula.
  6. Alur serupa berlaku untuk pengajuan **Pembatalan Sesi (Cancel Request)**.
* **Integrasi Database**:
  * Tabel: `public.session_change_requests`.
  * RLS: Hanya pengirim (*requester*) dan penerima (*target*) yang dapat mengakses rekaman permintaan perubahan terkait.

---

### MODUL 7: CHAT REAL-TIME & NOTIFIKASI INSTAN (REALTIME CHAT & IN-APP NOTIFICATION)

* **Tujuan**: Menyediakan media komunikasi langsung antar-aktor di dalam aplikasi tanpa perlu menggunakan aplikasi pihak ketiga.
* **Aktor**: Murid dan Tutor.
* **Alur Kerja (Workflow)**:
  1. Saat booking aktif terjalin, ruang chat eksklusif dibuka berdasarkan ID booking tersebut.
  2. Murid atau tutor mengirim pesan. Pesan langsung disimpan ke tabel `public.messages`.
  3. Supabase Realtime mereplikasi baris data baru tersebut ke aplikasi penerima secara instan (<500 milidetik).
  4. Bersamaan dengan itu, trigger database `notify_chat_message_insert()` secara otomatis mendeteksi pesan masuk dan membuat data notifikasi di tabel `public.app_notifications`.
  5. Lencana (*badge*) unread chat diperbarui, dan notifikasi melayang muncul jika pengguna sedang berada di luar ruang chat.
* **Integrasi Database**:
  * Tabel: `public.messages` & `public.app_notifications`.
  * Trigger Database: `notify_chat_message_insert()` untuk pembentukan notifikasi in-app otomatis saat baris pesan masuk.

---

### MODUL 8: JURNAL BELAJAR DAN PENUGASAN LATIHAN (LEARNING JOURNAL & HOMEWORK)

* **Tujuan**: Mendokumentasikan materi pelajaran yang telah diajarkan dan mengevaluasi hasil pemahaman murid melalui PR.
* **Aktor**: Tutor (Pembuat & Pemeriksa) dan Murid (Pengerja).
* **Alur Kerja (Workflow)**:
  1. Setelah selesai memberikan sesi mengajar, Tutor mengisi form jurnal belajar: materi yang diajarkan, catatan perkembangan, dan deskripsi pekerjaan rumah (PR).
  2. Data tersimpan di tabel `session_learning_records` dengan status PR `assigned`.
  3. Murid membuka menu **Kelas / Jurnal Belajar**, melihat materi dan tugas PR yang harus dikerjakan.
  4. Setelah selesai mengerjakan, Murid mengunggah jawaban tugas berupa teks/tautan dokumen (*submit PR*). Status PR berubah menjadi `submitted`.
  5. Tutor menerima pemberitahuan PR selesai dikerjakan, memeriksa jawaban murid, lalu memberikan nilai/ulasan (*review*). Status PR berubah menjadi `reviewed`.
* **Integrasi Database**:
  * Tabel: `public.session_learning_records`.
  * Constraint: Satu sesi pertemuan hanya memiliki maksimal satu rekaman jurnal belajar (relasi 1:1).

---

### MODUL 9: PENGINGAT OTOMATIS SESI BELAJAR (SMART REMINDER SYSTEM)

* **Tujuan**: Meminimalkan tingkat lupa jadwal sesi belajar (*no-show*) dengan mengirimkan pengingat terjadwal.
* **Aktor**: Murid dan Tutor (Sistem Otomatis).
* **Alur Kerja (Workflow)**:
  1. Sistem penjadwalan backend secara periodik memeriksa tabel `booking_sessions` yang akan datang.
  2. Sistem menyaring sesi yang akan dimulai dalam **H-24 jam** dan **H-2 jam**.
  3. Sistem memicu pengiriman notifikasi pengingat pintar ke tabel `public.app_notifications` dan antrian push notification.
  4. Pengguna menerima notifikasi pop-up di ponsel mereka. Ketika notifikasi di-tap, fitur *deep-linking* mengarahkan pengguna secara instan menuju detail sesi pertemuan yang dituju untuk bersiap-siap.
* **Integrasi Database**:
  * Kolom pelacak: `reminder_h24_sent_at`, `reminder_h2_sent_at` pada tabel `booking_sessions`.
  * RPC Function: `process_due_session_reminders()` untuk memproses seluruh reminder yang jatuh tempo secara massal oleh sistem.

---

### MODUL 10: SISTEM DOMPET DIGITAL SIMULASI (DUMMY WALLET & TRANSACTIONS)

* **Tujuan**: Menyimulasikan alur pembayaran uang les secara aman dalam lingkup penelitian tanpa menggunakan *payment gateway* berbayar asli.
* **Aktor**: Murid dan Tutor.
* **Alur Kerja (Workflow)**:
  1. Setelah pemesanan paket disetujui tutor, murid memiliki tagihan aktif di bawah menu Pembayaran.
  2. Sistem mencatat rencana transaksi per siklus bulan pada tabel `public.transactions`.
  3. Murid menekan tombol **Bayar Simulasi (Dummy)**.
  4. Aplikasi mengirimkan permintaan perubahan status pembayaran ke server.
  5. Database mengubah status transaksi menjadi `paid` dan mencatat tanggal pelunasan (`paid_at`).
  6. Sesi belajar yang tadinya tertunda (*hold*) langsung dinyatakan aktif dan siap dilaksanakan sesuai jadwal.
* **Integrasi Database**:
  * Tabel: `public.transactions` (menyimpan detail tagihan per bulan `booking_id`, `cycle_number`, `amount`, `payment_status`).
  * Index Unik: `(booking_id, cycle_number)` untuk mencegah pembayaran ganda pada siklus bulan yang sama.

---
*Dokumen ini merupakan aset resmi dokumentasi fungsional EduConnect. Segala bentuk perubahan alur bisnis pada aplikasi wajib diikuti dengan pembaruan pada modul ini.*
