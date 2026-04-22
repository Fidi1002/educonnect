# BAB IV HASIL DAN PEMBAHASAN

## 4.1 Gambaran Umum Hasil Penelitian
Penelitian ini menghasilkan sebuah aplikasi mobile berbasis Android menggunakan framework Flutter dengan nama **EduConnect**. Aplikasi ini dirancang sebagai wadah yang mempertemukan **murid** dan **tutor** melalui mekanisme pencarian tutor berdasarkan lokasi terdekat, serta mendukung proses layanan belajar melalui fitur pencarian, profil tutor, pemesanan (booking) paket belajar, penjadwalan pertemuan, chat real time, dan notifikasi in-app.

Hasil pengembangan menunjukkan bahwa EduConnect mampu mengakomodasi kebutuhan utama pengguna pada dua peran (role), yaitu murid dan tutor. Murid dapat melakukan registrasi/login, memilih role, mencari tutor terdekat dalam radius tertentu, melihat detail tutor, melakukan booking paket belajar (1, 2, 3, atau 6 bulan) dengan jadwal maksimal 2 kali per minggu, melakukan komunikasi dengan tutor melalui chat, serta memantau jadwal pertemuan melalui kalender. Tutor dapat membuat dan memperbarui profil, mengatur ketersediaan jadwal, menerima atau menolak booking, mengelola sesi pertemuan, serta menindaklanjuti permintaan reschedule/cancel.

Sebagai dukungan proses layanan belajar, aplikasi juga menyediakan komponen **progress belajar** dan **riwayat materi serta PR (pekerjaan rumah)** per sesi. Progress ini dirancang untuk membantu murid memantau perkembangan pembelajaran secara objektif berdasarkan status sesi, sekaligus membantu tutor mendokumentasikan materi dan evaluasi latihan.

Pada sisi backend, aplikasi memanfaatkan layanan **Supabase** (PostgreSQL + Auth + Realtime) untuk penyimpanan data, otentikasi, dan komunikasi real time. Untuk fitur lokasi dan pemetaan, aplikasi memanfaatkan layanan lokasi perangkat (GPS) dan integrasi peta sesuai kebutuhan pengembangan. Dengan demikian, hasil penelitian ini tidak hanya berupa prototipe antarmuka, tetapi sebuah sistem yang berjalan end-to-end dan dapat diuji melalui skenario penggunaan nyata.

## 4.2 Penerapan Metode SDLC Waterfall
Pengembangan EduConnect menerapkan metode **SDLC Waterfall** yang menekankan tahapan berurutan: analisis kebutuhan, perancangan, implementasi, dan pengujian. Model ini dipilih karena sesuai untuk pengembangan aplikasi dengan kebutuhan yang relatif jelas sejak awal, serta memudahkan pendokumentasian setiap tahap sebagai bagian dari penyusunan karya ilmiah.

### 4.2.1 Tahap Analisis Kebutuhan
Tahap analisis kebutuhan dilakukan untuk mengidentifikasi tujuan sistem, aktor yang terlibat, serta kebutuhan fungsional dan non-fungsional. Analisis dilakukan melalui perumusan masalah penelitian, studi literatur aplikasi sejenis (platform pencarian tutor dan layanan booking), serta pemetaan kebutuhan pengguna (murid dan tutor). Output utama tahap ini meliputi: definisi fitur inti (auth dan role, profil tutor, pencarian terdekat, booking paket, chat, notifikasi), batasan sistem (misalnya maksimal 2 murid aktif untuk tutor, maksimal 2 sesi per minggu), serta kebutuhan data yang harus dikelola (profil pengguna, profil tutor, koordinat, booking, sesi, transaksi, chat, notifikasi, materi/PR).

### 4.2.2 Tahap Perancangan Sistem
Tahap perancangan sistem bertujuan menerjemahkan kebutuhan menjadi rancangan teknis. Pada tahap ini disusun rancangan arsitektur aplikasi (pemisahan layer presentasi, aplikasi, domain, dan data), rancangan alur navigasi berdasarkan role, rancangan basis data dan relasi antar tabel, serta rancangan antarmuka yang mengacu pada mockup. Output pada tahap ini meliputi: use case diagram, activity diagram untuk proses penting, rancangan skema database (ERD dan struktur tabel), serta rancangan tampilan (login/registrasi, home, daftar tutor, detail tutor, booking, chat, notifikasi, kalender belajar, profil).

### 4.2.3 Tahap Implementasi Sistem
Tahap implementasi dilakukan menggunakan Flutter untuk pengembangan aplikasi Android. Implementasi backend menggunakan Supabase untuk autentikasi, database, dan fitur realtime. Pada tahap ini diterapkan pula aturan keamanan (Row Level Security/RLS) dan validasi transisi status pada database agar alur bisnis tidak bergantung sepenuhnya pada validasi klien. Output implementasi berupa aplikasi yang dapat dijalankan, skema database yang terdeploy, dan fitur yang dapat diuji melalui skenario end-to-end.

### 4.2.4 Tahap Pengujian Sistem
Tahap pengujian dilakukan menggunakan metode **Black Box Testing**, yaitu pengujian berdasarkan input-output tanpa menilai detail internal kode. Pengujian difokuskan pada fungsionalitas utama sistem dan kestabilan alur pengguna. Selain itu, dilakukan pula uji skenario untuk memastikan sistem menolak perubahan status yang tidak valid (misalnya murid mencoba menyelesaikan booking yang seharusnya hanya dapat dilakukan oleh tutor).

## 4.3 Analisis Kebutuhan Sistem

### 4.3.1 Kebutuhan Fungsional
Secara fungsional, EduConnect harus mampu melayani dua jenis aktor utama: murid dan tutor. Pada sisi murid, sistem menyediakan kemampuan registrasi/login, pemilihan role, pencarian tutor terdekat berbasis radius, melihat detail tutor, melakukan booking paket belajar, melihat jadwal dan kalender sesi, melakukan pembayaran simulasi (dummy) untuk kebutuhan penelitian, berkomunikasi melalui chat real time, menerima notifikasi, melakukan konfirmasi kehadiran menjelang sesi, serta mengelola progres belajar dan PR. Pada sisi tutor, sistem menyediakan kemampuan melengkapi profil, mengatur availability, menerima/menolak booking, mengelola sesi, merespons reschedule/cancel, chat, serta mengisi materi/PR dan melakukan review terhadap PR murid.

### 4.3.2 Kebutuhan Non-Fungsional
Kebutuhan non-fungsional meliputi keamanan (pembatasan akses data berbasis role dan kepemilikan dengan RLS serta validasi transisi status), kinerja (pencarian radius responsif dan realtime chat/notifikasi), reliabilitas (penanganan jaringan tidak stabil dengan retry state), usability (navigasi konsisten dan pesan error yang jelas), serta maintainability (kode modular berbasis fitur).

## 4.4 Perancangan Sistem

### 4.4.1 Use Case Diagram
Use case diagram menggambarkan interaksi aktor dengan sistem. Dalam EduConnect terdapat dua aktor utama. Murid: registrasi/login, memilih role, mencari tutor terdekat, melihat detail tutor, booking paket, pembayaran simulasi, melihat jadwal dan kalender, chat, notifikasi, konfirmasi kehadiran, submit PR, serta melihat progres dan riwayat materi. Tutor: login, melengkapi profil tutor, mengatur availability, menerima/menolak booking, mengelola sesi, merespons reschedule/cancel, chat, notifikasi, mengisi materi dan PR, serta review PR.

### 4.4.2 Activity Diagram
Activity diagram digunakan untuk memodelkan alur proses utama. Alur yang direkomendasikan: (1) login/registrasi dan onboarding role, (2) pencarian tutor terdekat berbasis radius, (3) booking paket termasuk validasi jadwal dan kapasitas tutor, (4) reschedule/cancel melalui request dengan status pending dan respons target, (5) pencatatan materi dan PR oleh tutor serta submission oleh murid.

### 4.4.3 Perancangan Database
Perancangan database menggunakan model relasional (PostgreSQL). Entitas utama meliputi `users`, `tutors`, `tutor_availability`, `bookings`, `transactions`, `booking_sessions`, `session_change_requests`, `app_notifications`, dan `session_learning_records`. Relasi penting: satu booking menghasilkan banyak sesi; setiap sesi dapat memiliki 0 atau 1 record materi/PR; notifikasi dapat menargetkan booking maupun booking_session.

### 4.4.4 Perancangan Antarmuka
Antarmuka disusun berdasarkan kebutuhan role murid dan tutor. Untuk murid, navigasi utama menggunakan bottom navigation (Home, Kelas, E-Book, Profil). Beranda menampilkan pencarian tutor, pengaturan radius, banner jadwal, kategori mapel, dan list tutor. Halaman Kelas menampilkan jadwal dan riwayat booking termasuk progres sesi, konfirmasi hadir, dan akses PR. Kalender belajar menampilkan sesi per tanggal. Untuk tutor, antarmuka menekankan jadwal/booking, availability, profil tutor, dan chat, serta form materi dan PR.

## 4.5 Implementasi Sistem

### 4.5.1 Implementasi Halaman Login dan Registrasi
Halaman login dan registrasi mengimplementasikan autentikasi berbasis email. Setelah pengguna berhasil login, sistem memastikan profil pengguna tersedia. Apabila role belum ditentukan, aplikasi mengarahkan ke halaman onboarding role. Fungsi utama halaman ini mencakup validasi input, penanganan error, dan pengalihan ke halaman sesuai role.

### 4.5.2 Implementasi Halaman Beranda
Beranda murid menampilkan greeting, pencarian tutor, pengaturan radius, akses notifikasi dan chat, serta banner menuju kalender jadwal belajar. Beranda tutor menyesuaikan konten agar relevan, terutama akses cepat menuju jadwal dan permintaan booking.

### 4.5.3 Implementasi Halaman Pencarian Tutor Terdekat
Pencarian tutor terdekat memanfaatkan lokasi perangkat. Murid memilih radius (misalnya 1/5/10/20 km) untuk memfilter tutor. Sistem menampilkan tutor dalam radius beserta informasi ringkas seperti rating, jarak, dan badge konsistensi tutor. Disediakan fallback ketika lokasi tidak tersedia.

### 4.5.4 Implementasi Halaman Detail Tutor
Halaman detail tutor menampilkan foto, nama, rating, lokasi, mata pelajaran, jam tersedia, deskripsi, serta tombol booking. Murid memilih paket (1/2/3/6 bulan) dan 2 slot jadwal per minggu sesuai availability tutor. Sistem melakukan validasi bentrok jadwal dan kapasitas tutor sebelum booking diproses.

### 4.5.5 Implementasi Halaman Chat Real Time
Chat real time disediakan agar murid dan tutor berkomunikasi dalam konteks booking. Chat dibuat per booking agar percakapan terstruktur. Sistem menyediakan inbox dan indikator pesan belum dibaca.

### 4.5.6 Implementasi Halaman Profil
Halaman profil menampilkan informasi pengguna dan menu seperti pengaturan akun, aktivitas, bantuan, dan logout. Pada tutor, halaman ini juga mengarahkan ke pengelolaan profil tutor dan availability.

## 4.6 Pengujian Sistem

### 4.6.1 Pengujian Black Box
Pengujian black box dilakukan untuk memastikan setiap fungsi utama berjalan sesuai kebutuhan. Tabel berikut merupakan contoh yang siap diedit dan disesuaikan.

**Tabel 4.1 Pengujian Black Box EduConnect (contoh)**

| No | Skenario Uji | Langkah Uji | Data Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
|---:|---|---|---|---|---|---|
| 1 | Registrasi akun murid | Isi nama, email, password - Register | Email valid | Akun dibuat dan login berhasil | Sesuai | Lulus |
| 2 | Login akun | Isi email dan password - Login | Kredensial valid | Masuk ke aplikasi | Sesuai | Lulus |
| 3 | Onboarding role | Pilih role murid/tutor | Murid | Role tersimpan dan masuk home role | Sesuai | Lulus |
| 4 | Pencarian tutor radius | Atur radius 5 km | Radius=5 | Tutor dalam radius tampil | Sesuai | Lulus |
| 5 | Buka detail tutor | Tap kartu tutor | TutorId valid | Halaman detail tampil lengkap | Sesuai | Lulus |
| 6 | Booking paket | Pilih paket 1 bulan + 2 slot | Paket=1 | Booking dibuat + sesi paket terbentuk | Sesuai | Lulus |
| 7 | Tutor terima booking | Tutor klik Terima | Status pending | Status jadi awaiting_payment | Sesuai | Lulus |
| 8 | Pembayaran dummy | Murid klik Bayar (Dummy) | BookingId | Status booking jadi paid | Sesuai | Lulus |
| 9 | Chat realtime | Kirim pesan murid-tutor | Teks | Pesan terkirim dan muncul realtime | Sesuai | Lulus |
| 10 | Notifikasi status | Trigger status booking/sesi | - | Notifikasi masuk dan bisa dibuka | Sesuai | Lulus |
| 11 | Reminder pintar | Menjelang sesi H-2 dan H-1 jam | SessionId | Notifikasi reminder muncul | Sesuai | Lulus |
| 12 | Deep-link reminder | Tap notif reminder | Target session | Masuk ke booking, fokus sesi target | Sesuai | Lulus |
| 13 | Konfirmasi hadir | Tap Konfirmasi Hadir | Sesi upcoming | Kehadiran tersimpan | Sesuai | Lulus |
| 14 | Materi dan PR | Tutor isi materi dan PR | Teks | Murid melihat materi dan PR | Sesuai | Lulus |
| 15 | Submit PR | Murid kumpulkan PR | Jawaban | Status PR jadi submitted | Sesuai | Lulus |
| 16 | Review PR | Tutor klik Review PR | Submitted | Status PR jadi reviewed | Sesuai | Lulus |
| 17 | Transisi ilegal | Murid coba set booking completed | - | Ditolak backend | Sesuai | Lulus |

### 4.6.2 Hasil Pengujian
Berdasarkan hasil pengujian, seluruh fitur utama yang diuji menunjukkan hasil sesuai dengan keluaran yang diharapkan. Sistem mampu menangani alur role-based dengan baik, pencarian tutor terdekat menampilkan tutor sesuai radius, booking paket menghasilkan sesi yang sesuai jadwal, serta notifikasi dan chat berjalan sebagaimana mestinya. Penguatan aturan status di backend efektif mencegah transisi status yang tidak sah.

## 4.7 Pembahasan
Implementasi EduConnect menunjukkan bahwa aplikasi membantu murid menemukan tutor terdekat secara lebih efektif. Pencarian berbasis radius memudahkan penyaringan tutor sesuai jarak, sementara detail tutor memperkaya informasi sebelum booking. Dari sisi komunikasi, chat realtime dan notifikasi in-app memperlancar koordinasi tanpa keluar aplikasi. Reminder pintar (H-2 dan H-1 jam) serta fitur konfirmasi hadir membantu kesiapan murid menjelang sesi, sehingga proses belajar lebih terstruktur.

Keberadaan kalender belajar, progress pertemuan, serta riwayat materi dan PR memperluas manfaat EduConnect dari sekadar marketplace menjadi alat pendamping pembelajaran. Murid dapat memantau progres sesi dan menyimpan rekam jejak materi, sedangkan tutor dapat mendokumentasikan materi dan evaluasi latihan. Secara keseluruhan, EduConnect telah memenuhi tujuan penelitian dalam membantu pencarian tutor terdekat dan komunikasi murid-tutor, serta memperkaya proses belajar melalui jadwal, reminder, dan dokumentasi pembelajaran.
