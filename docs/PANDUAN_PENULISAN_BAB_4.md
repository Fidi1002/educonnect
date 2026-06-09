# PANDUAN DAN DOKUMENTASI PENULISAN BAB IV: HASIL DAN PEMBAHASAN
## APLIKASI EDUCONNECT (FLUTTER + SUPABASE)

Dokumen ini disusun untuk membantu peneliti/mahasiswa dalam menyusun **BAB IV (Hasil dan Pembahasan)** skripsi/tugas akhir berdasarkan implementasi nyata pada proyek **EduConnect**. Dokumen ini merangkum seluruh poin penting yang wajib dicantumkan dalam karya ilmiah, disesuaikan dengan arsitektur kode dan skema database aktual yang ada di dalam repositori.

---

## STRUKTUR UTAMA BAB IV YANG DIREKOMENDASIKAN

Secara umum, BAB IV pada penelitian rekayasa perangkat lunak dengan metode SDLC (seperti Waterfall) dibagi menjadi dua bagian besar:
1. **Hasil Penelitian / Hasil Implementasi**: Menyajikan wujud sistem dari hasil tahapan SDLC (Analisis, Perancangan, Implementasi, dan Pengujian).
2. **Pembahasan**: Menganalisis sistem secara kritis (efektivitas, keamanan data, keandalan arsitektur, dan perbandingan dengan tujuan penelitian).

Berikut adalah detail materi yang harus diisi pada masing-masing sub-bab:

---

## 4.1 GAMBARAN UMUM SISTEM (HASIL PENGEMBANGAN)
Pada bagian ini, jelaskan apa itu **EduConnect** secara komprehensif:
* **Definisi**: Aplikasi pencarian tutor belajar terdekat berbasis lokasi menggunakan framework Flutter (sisi client) dan Supabase (sisi backend/BaaS).
* **Tujuan**: Membantu murid menemukan tutor terdekat dalam radius tertentu (1 km, 5 km, 10 km, 20 km) serta menyediakan sistem pemantauan pembelajaran secara terstruktur (bukan hanya marketplace tutor biasa).
* **Dua Peran Utama (Role-Based)**:
  1. **Murid**: Melakukan pencarian tutor terdekat, memesan paket belajar (1, 2, 3, atau 6 bulan), melakukan pembayaran simulasi, berkomunikasi melalui chat, memantau kalender belajar, melakukan konfirmasi kehadiran sesi, serta mengerjakan PR yang diberikan tutor.
  2. **Tutor**: Mengatur ketersediaan jadwal (*availability*), menyetujui/menolak booking murid, mengelola status sesi, memberikan materi dan PR, serta memberikan ulasan/nilai terhadap PR murid.

---

## 4.2 LINGKUNGAN PENGEMBANGAN DAN UJI COBA (SPESIFIKASI SISTEM)
Tuliskan spesifikasi teknologi yang digunakan untuk membangun dan menguji EduConnect. Ini penting untuk menunjukkan validitas penelitian:
* **Perangkat Lunak Utama**:
  * Bahasa Pemrograman: Dart (Flutter SDK versi terbaru)
  * Database & Backend: PostgreSQL, Supabase Auth, Supabase Database, Supabase Realtime, Supabase Storage.
  * Library Manajemen State: Riverpod (`flutter_riverpod`)
  * Routing: Go Router (`go_router`)
  * Geolokasi & Peta: `geolocator`, PostGIS (pada database PostgreSQL)
* **Lingkungan Deploy & Database**:
  * Database host: Supabase Cloud (PostgreSQL 15+)
  * Skema keamanan: Row Level Security (RLS) diaktifkan di seluruh tabel.
  * Node.js / CLI: Supabase CLI untuk migrasi skema database secara otomatis.

---

## 4.3 IMPLEMENTASI REALISASI TAHAPAN SDLC WATERFALL
Sub-bab ini menjabarkan bagaimana setiap tahapan Waterfall diterjemahkan ke dalam komponen riil proyek EduConnect.

### 4.3.1 Tahap Analisis Kebutuhan Sistem
Uraikan kebutuhan fungsional dan non-fungsional yang berhasil diimplementasikan:
1. **Kebutuhan Fungsional (Functional Requirements)**:
   * Sistem harus mampu memfilter tutor berdasarkan radius jarak geospasial (menggunakan GPS perangkat murid).
   * Sistem harus mampu menangani siklus pemesanan paket belajar secara atomic (booking terbuat bersamaan dengan transaksi bulanan dan pembentukan sesi pertemuan).
   * Sistem harus mampu mendistribusikan notifikasi in-app dan chat secara real-time.
   * Sistem harus mampu melacak jurnal belajar murid (materi, penugasan PR, pengumpulan, dan review).
2. **Kebutuhan Non-Fungsional (Non-Functional Requirements)**:
   * **Keamanan Data**: Penerapan Row Level Security (RLS) pada PostgreSQL untuk mencegah kebocoran data antar-pengguna.
   * **Integritas Status**: Penggunaan Database Trigger untuk menolak transisi status ilegal (contoh: murid mencoba mengubah sesi ke status `completed` secara sepihak).

### 4.3.2 Tahap Perancangan Sistem
Jelaskan rancangan arsitektur dan database yang telah direalisasikan di dalam sistem:

#### A. Arsitektur Kode (Feature-First Architecture)
EduConnect menerapkan struktur folder berbasis fitur untuk memudahkan pemeliharaan kode (*maintainability*). Gambarkan arsitektur ini dalam diagram blok atau deskripsi terstruktur:
* **Presentation Layer**: Widget UI Flutter yang merespons aksi pengguna.
* **Application Layer**: State management menggunakan Riverpod untuk mengatur status pemuatan (*loading*), data (*data*), dan error (*error*).
* **Domain Layer**: Model data Dart yang merepresentasikan entitas database (misal: `BookingModel`, `SessionModel`).
* **Data Layer**: Repository yang berinteraksi langsung dengan REST API/Realtime SDK Supabase.

#### B. Skema Database Aktual (Relational Schema)
Gambarkan struktur tabel dan relasi antar-tabel di Supabase yang telah dibangun. Berikut adalah tabel-tabel utama yang harus dijelaskan:
1. `public.users`: Profil dasar user (uid, role, display_name, photo_url).
2. `public.tutors`: Profil detail tutor, termasuk koordinat geospasial (`latitude`, `longitude`, `geohash`, dan data spasial PostGIS `location`).
3. `public.tutor_availability`: Slot ketersediaan hari dan jam tutor.
4. `public.bookings`: Transaksi induk pemesanan paket belajar oleh murid.
5. `public.transactions`: Catatan transaksi pembayaran dummy per siklus bulan.
6. `public.booking_sessions`: Daftar sesi belajar riil yang di-generate otomatis setelah booking dibayar (`scheduled`, `confirmed`, `disputed`, dll).
7. `public.session_change_requests`: Pengelolaan permintaan reschedule dan pembatalan sesi belajar.
8. `public.session_learning_records`: Jurnal belajar berisi materi, deskripsi PR, submission murid, dan review tutor.
9. `public.app_notifications`: Notifikasi in-app untuk interaksi antar-aktor.
10. `public.messages`: Pesan chat real-time yang terikat pada ID booking.

### 4.3.3 Tahap Implementasi Fitur Utama (Disertai Penjelasan Kode & Tampilan)
Tuliskan bagaimana fitur-fitur penting diimplementasikan dalam kode program dan sertakan screenshot UI masing-masing fitur.

#### 1. Onboarding dan Manajemen Peran (Role-Based Onboarding)
* **Penjelasan Teknis**: Pengguna baru yang mendaftar wajib memilih peran sebagai `student` atau `tutor`. Peran ini disimpan di tabel `public.users` dan dibaca oleh `go_router` untuk menentukan navigasi shell route yang sesuai.
* **Cuplikan Kode / Logika**: Router memvalidasi role pengguna sebelum mengizinkan akses ke halaman beranda khusus murid atau dashboard tutor.

#### 2. Pencarian Tutor Berbasis Jarak Geospasial (PostGIS & Geolocator)
* **Penjelasan Teknis**: Aplikasi mengakses GPS perangkat murid untuk mendapatkan garis lintang (*latitude*) dan bujur (*longitude*). Koordinat tersebut dikirimkan ke database melalui RPC `get_nearby_tutors(...)`. Database PostgreSQL menggunakan ekstensi **PostGIS** untuk menghitung jarak nyata secara efisien dan mengembalikan daftar tutor aktif yang berada dalam radius yang dipilih (1, 5, 10, atau 20 km).

#### 3. Pemesanan Paket Belajar Secara Atomic (Atomic Package Booking via RPC)
* **Penjelasan Teknis**: Ketika murid memilih paket belajar, sistem harus membuat entitas booking, membuat transaksi pembayaran pertama, dan menjadwalkan sesi belajar mingguan (2 kali seminggu) secara sekaligus. Proses ini diimplementasikan menggunakan Remote Procedure Call (RPC) database di sisi server agar prosesnya bersifat *atomic* (jika salah satu gagal, seluruh transaksi dibatalkan, menghindari data korup/setengah jadi).
* **Validasi Bentrok**: Database memvalidasi ketersediaan tutor (*availability*) dan kapasitas mengajar tutor (maksimal 2 murid aktif) untuk mencegah bentrok jadwal.

#### 4. Siklus Hidup Sesi Belajar & Validasi Transisi Status (Session Lifecycle)
* **Penjelasan Teknis**: Setiap pertemuan memiliki status terstruktur (`scheduled` -> `done_pending_confirmation` -> `confirmed` / `disputed`). Transisi ini dijaga ketat di tingkat database melalui PostgreSQL Trigger Function. Jika murid mencoba menandai sesi selesai sebelum dikonfirmasi tutor, atau jika tutor mencoba melakukan tindakan ilegal, database akan melempar error dan UI akan menampilkan pesan penolakan yang aman.

#### 5. Chat Real-Time dan Notifikasi Otomatis
* **Penjelasan Teknis**: Menggunakan fitur realtime replication dari Supabase. Ketika data baru masuk ke tabel `public.messages`, trigger database secara otomatis menyisipkan record baru ke tabel `public.app_notifications`. Di sisi client, StreamProvider Riverpod menangkap perubahan data secara realtime dan langsung memperbarui tampilan chat atau lencana notifikasi tanpa perlu memuat ulang halaman.

#### 6. Jurnal Belajar dan Monitoring PR (Learning Journal)
* **Penjelasan Teknis**: Tutor mengisi materi yang diajarkan dan memberikan pekerjaan rumah (PR) setelah sesi selesai. Murid dapat melihat daftar PR aktif, melakukan unggahan jawaban (*submit*), yang kemudian statusnya berubah menjadi `submitted` dan menunggu ulasan dari tutor. Setelah tutor memberikan nilai/review, status berubah menjadi `reviewed`.

---

## 4.4 PENGUJIAN SISTEM (VERIFICATION PHASE)
Bagian ini menyajikan hasil pengujian fungsionalitas dan keamanan sistem menggunakan metode **Black Box Testing** dan **Negative Testing**.

### 4.4.1 Pengujian Black Box (Tabel Hasil Skenario Fungsional)
Sajikan tabel pengujian yang membuktikan bahwa seluruh alur utama aplikasi telah berjalan dengan sukses.

| No | Skenario Uji | Deskripsi / Langkah Uji | Input Data | Hasil yang Diharapkan | Status |
|---:|---|---|---|---|---|
| 1 | Registrasi Akun Baru | Mendaftar akun baru dan memilih role pengguna. | Email & Password valid, Role = `student` | Akun berhasil dibuat, tersimpan di database, dialihkan ke beranda murid. | **Lulus** |
| 2 | Pencarian Tutor Radius | Mengatur filter radius jarak pencarian pada beranda murid. | Koordinat GPS, Radius = 5 km | Hanya tutor aktif dalam radius 5 km yang muncul di daftar hasil. | **Lulus** |
| 3 | Booking Paket Belajar | Memesan paket belajar dengan memilih slot waktu tutor yang kosong. | Paket 1 bulan, 2 slot waktu/minggu | Booking berstatus `pending` berhasil dibuat di database. | **Lulus** |
| 4 | Persetujuan & Pembayaran | Tutor menyetujui booking, lalu murid melakukan pembayaran simulasi. | ID Booking, Aksi = Bayar | Status booking berubah jadi `paid` dan sesi belajar langsung terbentuk. | **Lulus** |
| 5 | Chat Real-Time | Murid mengirimkan pesan chat dalam diskusi booking kepada tutor. | Teks pesan chat | Pesan langsung muncul pada layar chat tutor secara real-time. | **Lulus** |
| 6 | Penugasan PR | Tutor mengisi materi belajar dan memberikan tugas PR pada sesi. | Detail materi, judul PR | Murid menerima notifikasi in-app dan PR muncul di jurnal belajar. | **Lulus** |
| 7 | Pengumpulan & Review PR | Murid mengumpulkan PR, lalu tutor memberikan nilai ulasan. | Teks Jawaban, Nilai Review | Status PR berubah dari `submitted` menjadi `reviewed`. | **Lulus** |

### 4.4.2 Pengujian Negatif (Negative / Hardening Testing)
Tuliskan hasil pengujian di mana sistem dengan sengaja diberikan masukan salah atau manipulasi ilegal untuk menguji ketahanan sistem.
* **Kasus Uji 1**: Pengguna dengan role `student` mencoba memanggil API/Query untuk mengubah ketersediaan jadwal tutor lain.
  * *Hasil Aktual*: Sistem menolak karena Row Level Security (RLS) PostgreSQL aktif membatasi hak akses berdasarkan user ID pemilik. (Status: **Lulus / Aman**).
* **Kasus Uji 2**: Murid mencoba memotong alur status dengan langsung mengubah status sesi belajar menjadi `confirmed` sebelum tutor menandai sesi sebagai `done_pending_confirmation`.
  * *Hasil Aktual*: Database melempar error constraint trigger dan membatalkan transaksi update status. (Status: **Lulus / Aman**).
* **Kasus Uji 3**: Pembuatan booking baru dengan slot jadwal yang berbenturan dengan murid lain yang sudah aktif pada tutor tersebut.
  * *Hasil Aktual*: Prosedur RPC `validate_package_booking` menolak pembuatan data dan mengembalikan pesan error bentrok jadwal. (Status: **Lulus / Aman**).

---

## 4.5 PEMBAHASAN AKADEMIK (DISCUSSION)
Pada sub-bab Pembahasan, lakukan analisis mendalam mengenai nilai kontribusi aplikasi EduConnect terhadap penyelesaian masalah penelitian:

1. **Efektivitas Geolokasi & PostGIS**:
   * Penggunaan PostGIS terbukti memberikan efisiensi tinggi dalam menghitung koordinat bola bumi langsung di tingkat database. Hal ini mempercepat waktu pemuatan halaman beranda murid secara signifikan dibanding jika perhitungan jarak dilakukan secara manual di sisi client Flutter.
2. **Kestabilan Sinkronisasi Real-Time**:
   * Implementasi Supabase Realtime (Replication) memangkas latensi komunikasi chat antara murid dan tutor menjadi kurang dari 500ms. Ini mengeliminasi kebutuhan proses *polling* berkala yang boros daya baterai perangkat mobile dan bandwidth jaringan.
3. **Pentingnya Keamanan Tingkat Basis Data (RLS & Triggers)**:
   * Dalam penelitian ini dibuktikan bahwa validasi di tingkat UI saja tidak cukup untuk menjamin keaslian data skripsi. Dengan mengimplementasikan RLS dan Trigger di sisi PostgreSQL, EduConnect menjamin bahwa histori belajar murid, status pembayaran, dan rekam kehadiran adalah valid, tidak dapat dimanipulasi secara ilegal, dan aman dari potensi celah keamanan aplikasi mobile.
4. **Peningkatan Kualitas Monitoring Belajar**:
   * Fitur Jurnal Belajar (riwayat materi & PR) dan sistem Reminder pintar (H-24 dan H-2 jam sebelum sesi) berhasil meningkatkan kedisiplinan belajar. Kehadiran murid dan tutor terpantau secara transparan melalui proses konfirmasi dua belah pihak, meminimalkan potensi perselisihan (*dispute*) dalam pelaksanaan les privat.

---

### CARA MEMANFAATKAN DOKUMEN INI
* **Salin Struktur**: Gunakan poin-poin di atas sebagai draf awal bab skripsi Anda.
* **Sesuaikan Visual**: Tambahkan screenshot antarmuka (UI) dari aplikasi EduConnect yang sedang berjalan (seperti beranda radius, detail tutor, kalender, chat, dan riwayat PR) pada masing-masing poin implementasi.
* **Hubungkan dengan Landasan Teori (BAB II)**: Hubungkan penjelasan SDLC Waterfall di sub-bab 4.3 dengan teori siklus Waterfall yang telah Anda tulis di Bab II skripsi Anda.
