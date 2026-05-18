# Thesis Architecture and Testing Narrative

Dokumen ini berisi narasi teknis yang dapat dijadikan bahan adaptasi untuk skripsi, khususnya pada bagian arsitektur sistem dan pengujian sistem.

## Narasi Arsitektur Sistem

Arsitektur aplikasi EduConnect dirancang menggunakan pendekatan modular berbasis fitur pada sisi Flutter dan pendekatan backend-as-a-service pada sisi server dengan Supabase. Pemisahan ini dilakukan agar aplikasi mudah dikembangkan, dipelihara, dan diuji secara bertahap seiring bertambahnya kompleksitas fitur.

Pada sisi klien, aplikasi dibangun menggunakan Flutter sehingga satu basis kode dapat digunakan untuk pengembangan lintas platform. Struktur kode disusun dengan pola feature-first, di mana setiap fitur utama seperti autentikasi, home, booking, chat, notifikasi, availability, dan profil tutor memiliki pemisahan ke dalam layer presentasi, aplikasi, domain, dan data. Layer presentasi bertanggung jawab terhadap tampilan dan interaksi pengguna, layer aplikasi mengelola state serta alur logika melalui Riverpod, layer domain menyimpan model dan aturan status yang digunakan lintas fitur, sedangkan layer data menangani komunikasi dengan backend Supabase.

Routing aplikasi menggunakan go_router. Pola ini dipilih agar navigasi dapat dibedakan secara jelas berdasarkan role pengguna. Setelah login, pengguna akan diarahkan ke shell route sesuai role. Murid memiliki alur utama berupa beranda, kelas, e-book, dan profil, sedangkan tutor memiliki alur dashboard, murid aktif, kalender, booking, availability, dan profil. Dengan pendekatan ini, logika akses halaman menjadi lebih terkontrol dan sesuai dengan kebutuhan masing-masing peran.

Pada sisi backend, Supabase digunakan sebagai pusat autentikasi, basis data, storage, dan realtime. Pendekatan ini memungkinkan integrasi data berlangsung secara terpusat, termasuk untuk role pengguna, profil tutor, data booking, sesi belajar, percakapan, notifikasi, dan jurnal belajar. Supabase dipilih karena mendukung PostgreSQL secara penuh, memiliki mekanisme Row Level Security, serta menyediakan kemampuan realtime yang sesuai untuk kebutuhan chat dan notifikasi in-app.

Arsitektur data EduConnect dirancang untuk mendukung alur operasional belajar yang cukup kompleks. Tabel users menyimpan identitas dasar pengguna, tabel tutor_profiles menyimpan informasi profesional tutor, sedangkan availability_slots menyimpan slot ketersediaan tutor. Ketika murid membuat pemesanan, data utama disimpan pada tabel bookings. Dari booking tersebut, sistem akan membentuk booking_sessions sebagai representasi setiap sesi belajar pada paket yang dipilih. Pendekatan ini penting karena proses pembelajaran dalam aplikasi tidak berhenti pada satu transaksi, melainkan berjalan sebagai rangkaian sesi yang memiliki status masing-masing, seperti scheduled, in_progress, confirmed, disputed, atau cancelled.

Di samping itu, sistem juga memiliki messages untuk komunikasi murid dan tutor, app_notifications untuk notifikasi in-app, session_change_requests untuk pengelolaan reschedule atau pembatalan, serta session_learning_records untuk pencatatan materi, PR, dan perkembangan belajar. Dengan struktur tersebut, aplikasi tidak hanya berfungsi sebagai media pencarian tutor, tetapi juga sebagai sistem operasional pembelajaran yang mencatat interaksi dan histori belajar secara berkelanjutan.

Salah satu kekuatan arsitektur EduConnect terletak pada penempatan business rules di dua sisi, yaitu sisi klien dan sisi database. Pada sisi klien, validasi dilakukan untuk meningkatkan pengalaman pengguna, misalnya dengan menonaktifkan tombol pada kondisi tertentu, menampilkan pesan error yang lebih ramah, dan mengatur loading state. Namun, validasi utama tetap dijaga di database melalui aturan dan fungsi Supabase agar integritas data tetap terjaga walaupun ada percobaan manipulasi dari luar UI. Pendekatan ini penting pada fitur booking dan session lifecycle, karena transisi status seperti approval booking, payment, mark done, confirmation, dispute, reschedule, dan cancel harus tunduk pada aturan yang ketat.

Untuk kebutuhan komunikasi dan notifikasi, sistem menggunakan pendekatan bertingkat. Pesan chat disimpan pada tabel messages, kemudian event penting membentuk app_notifications untuk kebutuhan notifikasi in-app. Selanjutnya, arsitektur push notification disiapkan melalui push_delivery_queue dan registrasi user_push_tokens. Dengan pola ini, aplikasi dapat berkembang dari sekadar notifikasi realtime dalam aplikasi menuju notifikasi push pada level perangkat tanpa harus mengubah keseluruhan arsitektur utama.

Secara keseluruhan, arsitektur EduConnect dirancang dengan prinsip keterpisahan tanggung jawab, konsistensi alur data, dan kesiapan pengembangan bertahap. Struktur ini mendukung kebutuhan aplikasi yang tidak hanya menampilkan data, tetapi juga mengelola interaksi operasional antara murid dan tutor secara berkelanjutan.

## Narasi Pengujian Sistem

Pengujian sistem pada EduConnect dilakukan untuk memastikan bahwa setiap fitur utama dapat berjalan sesuai kebutuhan fungsional dan bahwa hubungan antarfitur tidak menimbulkan inkonsistensi data. Pendekatan pengujian yang digunakan menggabungkan pengujian manual end-to-end, pengujian black box pada fitur utama, dan regression checking pada alur status yang sensitif seperti booking dan sesi belajar.

Pengujian black box difokuskan pada interaksi pengguna terhadap sistem tanpa menilai detail implementasi internal kode. Pada tahap ini, penguji memperlakukan aplikasi sebagai sebuah sistem utuh, lalu memberikan input tertentu untuk melihat apakah keluaran yang dihasilkan sesuai dengan yang diharapkan. Pendekatan ini sesuai untuk kebutuhan laporan akademik karena dapat menunjukkan bahwa sistem telah diuji dari sisi fungsional pengguna.

Skenario pengujian disusun berdasarkan alur inti aplikasi. Pertama, pengujian dilakukan pada fitur autentikasi dan role untuk memastikan pengguna dapat login, registrasi, memilih role, dan diarahkan ke halaman yang sesuai. Kedua, pengujian dilanjutkan pada fitur pencarian tutor, termasuk pengujian radius lokasi, filter mapel, harga, rating, dan pembukaan halaman detail tutor. Ketiga, pengujian dilakukan pada alur booking, mulai dari pembuatan booking oleh murid, persetujuan oleh tutor, pembayaran dummy, hingga aktivasi sesi belajar.

Pengujian berikutnya berfokus pada lifecycle sesi belajar. Pada tahap ini, diuji apakah tutor dapat memulai dan menyelesaikan sesi, apakah murid dapat mengonfirmasi sesi, serta apakah sistem dapat menangani skenario khusus seperti dispute, no-show, reschedule, dan pembatalan. Pengujian pada tahap ini sangat penting karena fitur inilah yang menjadi inti operasional EduConnect. Kesalahan pada transisi status dapat berdampak langsung pada keakuratan riwayat belajar, konsistensi notifikasi, dan penilaian tutor.

Selain itu, pengujian dilakukan pada fitur komunikasi dan notifikasi. Penguji memastikan bahwa pesan dapat dikirim antara murid dan tutor dalam konteks booking yang aktif, unread count dapat berubah sesuai kondisi baca, notifikasi in-app dapat muncul untuk event penting, dan deep-link dari notifikasi dapat membuka halaman target yang sesuai. Pada tahap lebih lanjut, arsitektur reminder backend dan push queue juga diperiksa untuk memastikan bahwa fondasi notifikasi tidak lagi hanya bergantung pada halaman Flutter yang sedang aktif.

Pengujian learning journal dilakukan untuk memastikan tutor dapat mengisi materi dan PR, murid dapat melihat hasil pencatatan tersebut, dan progres PR dapat berubah sesuai tindakan submit maupun review. Dengan adanya pengujian ini, aplikasi dapat dibuktikan bukan hanya berfungsi sebagai media pemesanan tutor, tetapi juga sebagai media monitoring pembelajaran.

Di luar skenario happy path, pengujian negatif juga menjadi bagian penting. Sistem diuji terhadap aksi yang seharusnya ditolak, seperti pengguna yang mencoba melakukan transisi status tanpa otorisasi atau dalam urutan yang tidak valid. Pengujian ini menunjukkan bahwa backend tidak hanya menerima input dari UI, tetapi juga menjaga aturan sistem secara mandiri. Dengan demikian, hasil pengujian tidak hanya menunjukkan bahwa fitur dapat berjalan, tetapi juga bahwa sistem cukup tangguh untuk menolak penggunaan yang tidak sesuai aturan.

Hasil pengujian secara umum menunjukkan bahwa fitur utama aplikasi telah dapat berjalan sesuai tujuan pengembangan. Namun, sebagaimana lazim pada pengembangan sistem berbasis realtime dan mobile/web hybrid, stabilitas juga dipengaruhi oleh kondisi koneksi, cache browser, dan kualitas environment testing. Oleh karena itu, dokumentasi pengujian akhir perlu dilengkapi dengan skenario, hasil, dan bukti visual agar dapat menjadi pendukung yang kuat pada proses evaluasi maupun sidang skripsi.

## Cara Memakai Dokumen Ini

Dokumen ini dapat dipakai sebagai bahan dasar untuk:
- subbab arsitektur sistem
- subbab implementasi teknis
- subbab pengujian sistem
- penjelasan presentasi saat sidang

Disarankan untuk tetap menyesuaikan gaya bahasa dengan pedoman kampus dan menghubungkannya dengan diagram, tabel pengujian, dan screenshot hasil implementasi.
