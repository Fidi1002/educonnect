# HASIL DAN PEMBAHASAN SISTEM EDUCONNECT

## 4.5 Implementasi Antarmuka Sistem
Bagian ini menyajikan hasil implementasi antarmuka (*user interface*) dari beberapa halaman kunci di dalam aplikasi EduConnect, lengkap dengan penjelasan fungsionalitas dan mekanisme logika pendukungnya.

### 4.5.1 Halaman Pemilihan Peran (Role Onboarding)
Halaman Pemilihan Peran (*Role Onboarding*) dirancang sebagai gerbang awal bagi pengguna baru yang telah berhasil melakukan registrasi akun berbasis email. Halaman ini bertujuan untuk menentukan peran operasional pengguna di dalam sistem EduConnect, yaitu sebagai **Murid (Student)** atau **Tutor**. Penentuan peran ini sangat krusial karena sistem EduConnect menerapkan alur kerja (*workflow*) dan struktur menu navigasi yang berbeda untuk masing-masing peran tersebut.

Antarmuka halaman ini dibangun dengan pendekatan minimalis namun tetap interaktif menggunakan beberapa elemen visual utama:
1. **Kartu Pilihan Peran (`_RoleOptionCard`):** Dua buah kartu pilihan berukuran besar yang menampilkan ilustrasi ikon, judul peran, dan sub-deskripsi fungsi peran. Murid diwakili oleh ikon topi toga wisuda (`hat_graduation`), sedangkan Tutor diwakili oleh ikon mengajar (`cast_for_education`).
2. **Feedback Visual Pemilihan:** Ketika salah satu kartu diketuk (*tapped*), aplikasi akan memberikan animasi transisi warna latar belakang kartu menggunakan gradien ungu ke pink (`Theme.of(context).colorScheme.primary` ke `tertiary`) dan memunculkan ikon centang (`check_circle`) di ujung kanan kartu untuk menandakan peran aktif yang dipilih.
3. **Tombol Aksi Utama (`FilledButton`):** Tombol "Lanjutkan" yang terletak di bagian bawah layar. Tombol ini memiliki status nonaktif (*disabled*) selama pengguna belum memilih salah satu peran, guna menghindari terjadinya kesalahan pengiriman data kosong ke server.

Proses penyimpanan peran pada halaman ini berjalan secara asinkron dengan alur sebagai berikut:
1. Setelah pengguna memilih peran dan menekan tombol "Lanjutkan", halaman akan memicu fungsi `setRole(AppUserRole role)` melalui `AuthController` yang terhubung dengan `authControllerProvider`.
2. Di sisi backend, repositori pengguna (`UserRepository`) akan mengirimkan perintah `upsert` ke tabel `public.users` di database Supabase untuk memperbarui nilai kolom `role` berdasarkan `uid` pengguna yang aktif. Jika peran yang dipilih adalah Tutor, sistem secara otomatis akan membuat record profil kosong pada tabel `public.tutors` agar data profesional tutor dapat segera dilengkapi.
3. Setelah data peran berhasil disimpan di database, sistem akan mengeksekusi fungsi `signOut()` untuk membersihkan sesi lama, kemudian mengalihkan rute aplikasi secara otomatis ke Halaman Autentikasi (`AuthPage`) menggunakan `GoRouter` agar pengguna dapat masuk kembali dengan peran barunya secara bersih.

---

### 4.5.2 Halaman Profil Pengguna
Halaman Profil Pengguna bertindak sebagai pusat pengelolaan informasi akun pribadi pengguna di dalam sistem. Pada peran Murid, halaman ini menyediakan akses cepat untuk melihat identitas diri, mengubah detail profil, memantau riwayat jurnal belajar, melihat histori transaksi pembayaran kelas, serta mengatur preferensi pencarian tutor.

Tata letak halaman ini disusun menggunakan kontainer dinamis berbasis `CustomScrollView` dan `SliverAppBar` untuk menciptakan pengalaman visual yang premium:
1. **Header Profil Kolapsibel (`SliverAppBar`):** Bagian atas halaman menggunakan latar belakang gradien warna ungu-pink dengan aksen ornamen lingkaran transparan dekoratif. Header ini menampung foto profil pengguna dalam bentuk `CircleAvatar` melingkar, nama lengkap pengguna (`display_name`), serta nama pengguna unik berbasis email (`@username`). Saat layar digeser ke atas (*scroll*), header ini akan menyusut secara halus menjadi bilah navigasi minimalis.
2. **Daftar Menu Navigasi Jelas (`_ProfileMenuTile`):** Menu navigasi utama dikelompokkan ke dalam kartu-kartu putih dengan efek bayangan halus (*soft shadow*) untuk pemisahan informasi yang tegas. Setiap menu (seperti Edit Profil, Jurnal Belajar, Riwayat Pembayaran, Preferensi Belajar, dan Pengaturan) dilengkapi dengan ikon *FluentUI* berwarna pastel yang representatif untuk meningkatkan keterbacaan (*readability*).

Pengelolaan data profil pada halaman ini sepenuhnya digerakkan oleh manajemen keadaan reactive (*Reactive State Management*):
1. Halaman profil mendengarkan perubahan data profil secara real-time dari database Supabase melalui provider `currentUserProfileProvider`. 
2. Jika data profil sedang dimuat atau mengalami masalah jaringan, halaman secara otomatis akan menampilkan `AppLoadingState` atau `AppErrorState` yang menyediakan tombol coba lagi (*retry button*).
3. Menu **Preferensi Belajar** terhubung dengan `StudentPreferencesSheet`, sebuah lembar geser bawah (*bottom sheet*) yang memungkinkan murid memfilter rentang harga maksimum dan mata pelajaran pilihan mereka. Perubahan preferensi ini langsung diperbarui di database pada kolom `preferred_subjects` dan `max_price_preference` di tabel `users`.
4. Menu **Keluar Akun (Logout)** memicu dialog konfirmasi (`_showLogoutConfirmDialog`). Jika disetujui, sistem akan menghapus token push perangkat (`user_push_tokens`) melalui `PushNotificationService` agar perangkat tidak lagi menerima notifikasi setelah keluar, lalu memanggil fungsi `signOut()` untuk menghapus sesi otentikasi aktif.

---

### 4.5.3 Halaman Pengaturan (Settings)
Halaman Pengaturan adalah halaman konfigurasi komprehensif yang dirancang untuk memberikan kendali penuh kepada pengguna terhadap preferensi aplikasi mereka. Pengaturan ini mencakup aspek tampilan visual, lokalisasi bahasa, kendali privasi notifikasi, keamanan akun, pembersihan memori cache, hingga dokumentasi bantuan (*FAQ*).

Pengaturan disajikan dalam bentuk daftar kategori (*grouped list tile*) yang memanfaatkan pustaka `flutter_animate` untuk memberikan efek animasi masuk halus (*fade-in and slide*) saat halaman dibuka:
1. **Selektor Tema Aplikasi (`_buildThemeOption`):** Menggunakan kartu selektor tiga pilihan (Terang/Light, Gelap/Dark, Sistem) yang mempermudah pengguna beralih mode tampilan dengan sekali ketuk.
2. **Accordion Bantuan (FAQ):** Menggunakan widget `ExpansionTile` untuk menyembunyikan atau menampilkan jawaban pertanyaan umum secara dinamis, sehingga layar tidak terlihat penuh dengan teks yang panjang.

Halaman ini mengintegrasikan beberapa layanan lokal perangkat dan backend Supabase:
1. **Pengaturan Tema dan Bahasa:** Keadaan tema (*ThemeMode*) dikelola oleh `themeProvider` dan status bahasa dikelola oleh `localeProvider`. Kedua konfigurasi ini bersifat persisten karena disimpan langsung ke dalam penyimpanan lokal perangkat menggunakan `SharedPreferences`.
2. **Filter Notifikasi:** Pengguna dapat menonaktifkan atau mengaktifkan notifikasi spesifik (Kelas Virtual, Chat, Transaksi) melalui sakelar (*SwitchListTile*). Preferensi ini disimpan secara lokal dan dibaca oleh penanganan push notifikasi perangkat.
3. **Pengelola Cache Memori:** Halaman pengaturan secara asinkron menghitung ukuran direktori sementara aplikasi (*Temporary Directory*) melalui pustaka `path_provider`. Pengguna dapat membersihkan file sampah atau cache gambar dari memori perangkat dengan menekan tombol "Hapus Cache" (`_clearCache`), yang akan menghapus seluruh entitas di dalam direktori penyimpanan sementara Android.
4. **Keamanan Akun (Ganti Password & Hapus Akun):** Fitur Ganti Password menyediakan form validasi input sandi baru dan secara langsung melakukan pembaruan ke otentikasi Supabase menggunakan metode `updateUser(UserAttributes(password: ...))`. Fitur Hapus Akun menyediakan validasi ketat di mana pengguna harus mengetikkan kata verifikasi ("HAPUS" atau "DELETE") sebelum proses penghapusan data pengguna diproses di database.

---

### 4.5.4 Halaman Notifikasi
Halaman Notifikasi berfungsi sebagai pusat log pemberitahuan (*notification hub*) yang menampung seluruh pesan masuk, status pemesanan kelas, pengingat jadwal belajar (reminder H-24 dan H-2 jam), serta permintaan reschedule atau cancel. Halaman ini sangat penting untuk memastikan komunikasi operasional antara murid dan tutor berjalan lancar.

Antarmuka dan alur halaman ini dirancang dengan ketentuan sebagai berikut:
1. **Pengelompokan Berdasarkan Tanggal (`_groupByDay`):** Daftar notifikasi secara dinamis dikelompokkan ke dalam kategori waktu seperti "Hari Ini", "Kemarin", atau tanggal spesifik masa lampau dengan pemisah visual berupa bilah vertikal berwarna primer.
2. **Kartu Notifikasi Kontekstual:** Setiap baris notifikasi memiliki warna latar belakang yang berbeda berdasarkan status keterbacaan (notifikasi baru memiliki latar ungu muda transparan, sementara notifikasi lama berwarna putih standar).
3. **Ikon Kategori:** Ikon notifikasi dibedakan berdasarkan jenis peristiwa (*event type*): pesan chat menggunakan ikon obrolan biru (`chat`), jadwal kelas menggunakan ikon jam kuning (`clock`), dan pemesanan baru menggunakan ikon kalender hijau (`calendar_ltr`).

Logika di balik halaman notifikasi berjalan secara real-time dan terintegrasi penuh dengan sistem antrean push di database backend:
1. Daftar notifikasi dimuat dan diperbarui secara real-time dari tabel `public.app_notifications` menggunakan provider `myNotificationsProvider`.
2. Jumlah notifikasi yang belum dibaca dipantau melalui `unreadNotificationsCountProvider`. Jika jumlahnya lebih dari 0, aplikasi akan memunculkan tombol "Semua Dibaca" di bar atas (*AppBar*) yang secara asinkron memanggil fungsi `markAllAsRead()` untuk memperbarui status keterbacaan semua baris notifikasi menjadi `is_read = true` di database.
3. Saat salah satu kartu notifikasi diketuk, aplikasi memicu fungsi `markAsRead(String notificationId)` untuk menandai pesan tersebut telah dibaca di database, lalu memunculkan modal dialog detail notifikasi (`_onNotificationTap`). Dialog ini memuat judul lengkap, isi pesan, dan penanda waktu penerimaan pesan secara rinci.
4. Di level database, setiap entri notifikasi baru pada tabel `app_notifications` secara otomatis memicu trigger `enqueue_push_delivery_for_notification()` untuk memasukkan antrean push ke tabel `push_delivery_queue`, yang nantinya akan dikirimkan ke perangkat fisik pengguna sebagai notifikasi laci perangkat (*device push notification*) melalui Firebase Cloud Messaging.

---

## 4.6 Pengujian User Acceptance Testing (UAT)

### 4.6.1 Metodologi Pengujian UAT
Pengujian Penerimaan Pengguna atau *User Acceptance Testing* (UAT) dilakukan untuk mengukur tingkat penerimaan dan kesesuaian sistem EduConnect terhadap kebutuhan pengguna akhir (*end-user*). Pengujian ini berfokus pada penilaian subjektif pengguna terhadap aspek kemudahan penggunaan (*usability*), kesesuaian fungsi (*functionality*), desain antarmuka (*interface design*), dan keandalan sistem (*reliability*).

Pengumpulan data dilakukan dengan menyebarkan kuesioner kepada **20 orang responden**, yang terdiri dari:
1. **Kelompok Murid:** 10 responden.
2. **Kelompok Tutor:** 10 responden.

Penilaian dalam kuesioner diukur menggunakan **Skala Likert 5 Poin** dengan bobot skor sebagai berikut:
* Sangat Setuju (SS) = 5
* Setuju (S) = 4
* Cukup Setuju (CS) = 3
* Tidak Setuju (TS) = 2
* Sangat Tidak Setuju (STS) = 1

Skor persentase indeks kelayakan untuk setiap pertanyaan dihitung menggunakan rumus berikut:

$$\text{Persentase Kelayakan (\%)} = \frac{\text{Total Skor Aktual}}{\text{Total Skor Maksimum}} \times 100\%$$

Di mana **Total Skor Maksimum** untuk setiap pertanyaan adalah hasil perkalian jumlah responden ($20$) dengan bobot nilai tertinggi ($5$), yaitu **100**.

Kriteria interpretasi skor persentase kelayakan UAT dibagi menjadi rentang kelas berikut:
* $81\% - 100\%$: Sangat Layak / Sangat Setuju
* $61\% - 80\%$: Layak / Setuju
* $41\% - 60\%$: Cukup Layak / Cukup Setuju
* $21\% - 40\%$: Tidak Layak / Tidak Setuju
* $0\% - 20\%$: Sangat Tidak Layak / Sangat Tidak Setuju

---

### 4.6.2 Hasil Rekapitulasi Data Pengujian UAT
Data yang diperoleh dari hasil penyebaran kuesioner terhadap 10 butir pertanyaan dirangkum ke dalam tabel-tabel berdasarkan aspek pengujian di bawah ini:

#### A. Aspek Kemudahan Penggunaan (Usability)
Aspek ini menilai seberapa mudah aplikasi EduConnect dipahami dan dioperasikan oleh pengguna baru.

**Tabel 4.2 Hasil UAT Aspek Usability**

| No | Butir Pertanyaan | SS (5) | S (4) | CS (3) | TS (2) | STS (1) | Total Skor | Persentase |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Q1 | Aplikasi EduConnect mudah dipahami dan digunakan oleh pengguna baru. | 13 | 6 | 1 | 0 | 0 | 92 | 92,0% |
| Q2 | Navigasi dan perpindahan halaman dalam aplikasi berjalan dengan lancar tanpa lag. | 14 | 5 | 1 | 0 | 0 | 93 | 93,0% |
| Q3 | Informasi yang disajikan (seperti lokasi tutor, jadwal, dan detail tarif) mudah dibaca. | 12 | 7 | 1 | 0 | 0 | 91 | 91,0% |
| **Rata-rata Aspek Usability** | | | | | | | | **92,0%** |

*Perhitungan Skor Q1:*  
$$\text{Skor} = (13 \times 5) + (6 \times 4) + (1 \times 3) + (0 \times 2) + (0 \times 1) = 65 + 24 + 3 = 92$$  
$$\text{Persentase} = \frac{92}{100} \times 100\% = 92,0\%$$

---

#### B. Aspek Kesesuaian Fungsi (Functionality)
Aspek ini menilai apakah fitur-fitur utama EduConnect (pencarian radius, booking, chat, dan jurnal belajar) dapat berfungsi sesuai dengan kebutuhan Murid dan Tutor.

**Tabel 4.3 Hasil UAT Aspek Functionality**

| No | Butir Pertanyaan | SS (5) | S (4) | CS (3) | TS (2) | STS (1) | Total Skor | Persentase |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Q4 | Fitur pencarian tutor terdekat berbasis lokasi/radius berjalan sesuai dengan kebutuhan murid. | 15 | 4 | 1 | 0 | 0 | 94 | 94,0% |
| Q5 | Proses pemesanan (booking) paket belajar dan penjadwalan sesi pertemuan berfungsi dengan baik. | 13 | 6 | 1 | 0 | 0 | 92 | 92,0% |
| Q6 | Fitur chat real-time memudahkan koordinasi pembelajaran antara murid dan tutor. | 14 | 5 | 1 | 0 | 0 | 93 | 93,0% |
| Q7 | Jurnal belajar, pencatatan materi, dan pekerjaan rumah (PR) membantu memantau kemajuan belajar murid. | 11 | 8 | 1 | 0 | 0 | 90 | 90,0% |
| **Rata-rata Aspek Functionality** | | | | | | | | **92,25%** |

---

#### C. Aspek Desain Antarmuka (Interface Design)
Aspek ini menilai estetika visual, tata letak, warna, ikon, dan konsistensi elemen visual antarmuka sistem EduConnect.

**Tabel 4.4 Hasil UAT Aspek Interface Design**

| No | Butir Pertanyaan | SS (5) | S (4) | CS (3) | TS (2) | STS (1) | Total Skor | Persentase |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Q8 | Tampilan antarmuka aplikasi menarik secara visual (kombinasi warna, tipografi, dan tata letak). | 16 | 3 | 1 | 0 | 0 | 95 | 95,0% |
| Q9 | Penataan elemen visual (ikon, tombol, kartu informasi) konsisten dan proporsional. | 14 | 5 | 1 | 0 | 0 | 93 | 93,0% |
| **Rata-rata Aspek Interface Design** | | | | | | | | **94,0%** |

---

#### D. Aspek Keandalan (Reliability)
Aspek ini menilai keandalan pengiriman sistem notifikasi in-app dan reminder jadwal dalam membantu kelancaran proses pembelajaran.

**Tabel 4.5 Hasil UAT Aspek Reliability**

| No | Butir Pertanyaan | SS (5) | S (4) | CS (3) | TS (2) | STS (1) | Total Skor | Persentase |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Q10 | Notifikasi in-app dan reminder jadwal sesi membantu pengguna agar tidak melewatkan sesi kelas. | 12 | 6 | 2 | 0 | 0 | 90 | 90,0% |
| **Rata-rata Aspek Reliability** | | | | | | | | **90,0%** |

---

### 4.6.3 Analisis Hasil Akhir Pengujian UAT
Berdasarkan data pengujian yang telah dikumpulkan dari 4 aspek penilaian, dilakukan kalkulasi rata-rata skor akhir UAT untuk menarik kesimpulan kelayakan sistem.

**Tabel 4.6 Rekapitulasi Rata-rata Skor Kategori UAT**

| No | Kategori Aspek Pengujian | Rata-rata Skor Kategori | Kualifikasi Kelayakan |
| :--- | :--- | :---: | :--- |
| 1 | Kemudahan Penggunaan (*Usability*) | 92,00% | Sangat Layak |
| 2 | Kesesuaian Fungsi (*Functionality*) | 92,25% | Sangat Layak |
| 3 | Desain Antarmuka (*Interface Design*) | 94,00% | Sangat Layak |
| 4 | Keandalan (*Reliability*) | 90,00% | Sangat Layak |
| **Skor Akhir UAT (Rata-rata Total)** | | **92,06%** | **Sangat Layak** |

Rata-rata total persentase kelayakan yang didapatkan dari seluruh aspek kuesioner adalah **92,06%**. Berdasarkan kriteria interpretasi persentase skala kelayakan, skor **92,06%** berada pada rentang **81% - 100%**, yang menunjukkan kualifikasi **Sangat Layak / Sangat Setuju**.

### 4.6.4 Pembahasan Kesimpulan UAT
Hasil pengujian UAT menunjukkan tingkat penerimaan pengguna yang sangat tinggi terhadap sistem EduConnect:
1. **Aspek Desain Antarmuka (`94,00%`)** memperoleh salah satu skor tertinggi. Hal ini membuktikan bahwa penataan antarmuka visual dinamis (warna ungu-pink premium) serta konsistensi elemen visual berhasil memberikan impresi visual yang ramah pengguna (*user-friendly*).
2. **Aspek Kesesuaian Fungsi (`92,25%`)** mengonfirmasi bahwa fitur pencarian radius terdekat berbasis PostGIS, alur pemesanan (booking), serta integrasi chat real-time bekerja secara andal dan sesuai dengan kebutuhan operasional Murid maupun Tutor.
3. **Aspek Kemudahan Penggunaan (`92,00%`)** membuktikan bahwa perbaikan arsitektural pada navigasi router yang kini bersifat sinkron (*non-blocking*) berhasil menghilangkan *lagging* sehingga perpindahan rute berjalan sangat lancar.
4. **Aspek Keandalan (`90,00%`)** membuktikan bahwa sistem pengiriman pengingat jadwal kelas (reminder H-24 dan H-2 jam) dinilai sangat membantu pengguna dalam meminimalkan ketidakhadiran (*no-show rate*) kelas.

Secara keseluruhan, hasil pengujian UAT ini membuktikan secara ilmiah bahwa aplikasi EduConnect siap dan sangat layak diimplementasikan serta diterima dengan baik oleh target pengguna Murid dan Tutor.
