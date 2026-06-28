# -*- coding: utf-8 -*-
import docx
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT

def build_prep_doc():
    doc = Document()

    # Style Settings
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Calibri'
    font.size = Pt(11)

    # Title
    title = doc.add_heading('PANDUAN BELAJAR & PERSIAPAN SIDANG SKRIPSI\nEDUCONNECT', 0)
    title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    
    doc.add_paragraph(
        "Dokumen panduan komprehensif ini dirancang khusus untuk membantu mahasiswa menguasai konsep, "
        "arsitektur, basis data, keamanan, frontend, backend, pengujian, serta persiapan tanya jawab teknis "
        "untuk aplikasi EduConnect (Pencarian Tutor Terdekat berbasis Flutter & Supabase).\n"
    )

    # ----------------------------------------------------
    # A. Analisis dan Perancangan Sistem
    # ----------------------------------------------------
    doc.add_heading('A. Analisis dan Perancangan Sistem', level=1)
    
    materi_a = [
        {
            "nama": "Analisis Kebutuhan (Requirement Analysis)",
            "def": "Proses menganalisis, mendokumentasikan, dan memvalidasi kebutuhan pengguna serta batasan sistem yang akan dikembangkan agar sistem tepat guna.",
            "imp": "Memastikan sistem EduConnect memiliki batasan operasional yang jelas antara Murid (pencari tutor, booking, chat) dan Tutor (manajemen jadwal, review PR).",
            "penerapan": "Menyusun spesifikasi kebutuhan perangkat lunak (SRS) yang membagi fungsionalitas berdasarkan hak akses user.",
            "relasi": "Menjadi acuan dasar pembuatan use case diagram, alur database, serta halaman antarmuka pengguna.",
            "tanya": "Bagaimana Anda memvalidasi bahwa radius pencarian yang Anda batasi (1-20 km) sudah cukup untuk murid?",
            "jawab": "Berdasarkan analisis mobilitas lokal, radius 1-5 km ditargetkan untuk efisiensi biaya transportasi tutor/murid (les tatap muka), sedangkan 10-20 km adalah batas maksimal wajar perjalanan darat perkotaan.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "User Requirement",
            "def": "Pernyataan tentang layanan apa yang diharapkan disediakan oleh sistem dan batasan-batasan operasional dari sudut pandang user.",
            "imp": "Sangat penting karena EduConnect mendefinisikan alur onboarding yang berbeda sejak awal antara peran Murid (Student) dan Tutor.",
            "penerapan": "Pengguna yang baru mendaftar wajib memilih peran pada halaman Role Onboarding sebelum dapat menggunakan fitur utama.",
            "relasi": "Memengaruhi logic filter otorisasi navigasi rute di Flutter (GoRouter) dan RLS di PostgreSQL.",
            "tanya": "Mengapa setelah memilih peran, user dipaksa logout dahulu?",
            "jawab": "Untuk me-refresh token session JWT Supabase secara bersih. Ketika user login kembali, klaim role yang baru tersimpan di database akan tersemat ke dalam JWT, sehingga sistem navigasi GoRouter memuat halaman utama sesuai role dengan aman.",
            "prioritas": "Sangat Disarankan"
        },
        {
            "nama": "Functional & Non-Functional Requirement",
            "def": "Functional: Fungsi atau layanan spesifik yang wajib disediakan sistem. Non-Functional: Batasan kualitas, keamanan, keandalan, dan performa dari layanan tersebut.",
            "imp": "Mengendalikan keberhasilan teknis sistem, seperti query spasial pencarian radius (Functional) dan keamanan RLS database (Non-Functional).",
            "penerapan": "Functional: Fitur booking paket belajar 1-6 bulan. Non-Functional: Waktu respon query di bawah 2 detik dan pencegahan manipulasi status booking.",
            "relasi": "Diterjemahkan langsung menjadi backend trigger/RPC di database, dan state controller di Flutter.",
            "tanya": "Berikan contoh non-functional requirement keamanan di sistem Anda!",
            "jawab": "Semua akses data ke tabel inti wajib melewati kebijakan Row Level Security (RLS) di PostgreSQL Supabase, memastikan user hanya bisa memodifikasi datanya sendiri.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "Use Case Diagram",
            "def": "Diagram yang memodelkan interaksi antara aktor (pengguna) dengan sistem untuk menunjukkan fungsionalitas yang disediakan.",
            "imp": "Menggambarkan batas hak akses pengguna (Murid vs Tutor) secara visual.",
            "penerapan": "Use case 'Mencari Tutor' dikaitkan dengan aktor Murid; use case 'Atur Availability' dikaitkan dengan Tutor; use case 'Kirim Pesan Chat' dikaitkan keduanya.",
            "relasi": "Menjadi panduan pembuatan menu navigasi UI dan otorisasi API.",
            "tanya": "Apakah Murid bisa mengakses use case milik Tutor?",
            "jawab": "Tidak. Sistem melakukan pengecekan role di sisi client via GoRouter dan di sisi server via RLS Policy database.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "Entity Relationship Diagram (ERD)",
            "def": "Diagram yang menggambarkan struktur basis data logis, entitas, atribut, dan relasi di antaranya.",
            "imp": "Sebagai blueprint database relasional EduConnect yang mengelola relasi user, tutor, booking, transaksi, dan chat.",
            "penerapan": "Tabel `users` berelasi One-to-One dengan `tutors`, dan One-to-Many dengan `bookings`. Tabel `bookings` berelasi One-to-Many dengan `booking_sessions`.",
            "relasi": "Diterjemahkan langsung menjadi skema tabel DDL SQL di Supabase.",
            "tanya": "Mengapa data profil tutor dipisah dari tabel users?",
            "jawab": "Untuk memenuhi prinsip normalisasi data (1NF/2NF) dan efisiensi query. Kolom spesifik tutor seperti tarif, bio, subjek, dan PostGIS location point hanya dibuat jika user mendaftar sebagai tutor, menjaga data user biasa (murid) tetap ramping.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_a:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # B. Pengembangan Perangkat Lunak
    # ----------------------------------------------------
    doc.add_heading('B. Pengembangan Perangkat Lunak', level=1)
    
    materi_b = [
        {
            "nama": "Software Development Life Cycle (SDLC) - Iterative/Agile Development",
            "def": "Metodologi pengembangan perangkat lunak yang memecah proses menjadi beberapa iterasi/milestone berulang untuk meningkatkan dan mengevaluasi sistem secara berkala.",
            "imp": "Mempermudah penanganan bug logika kompleks (seperti integrasi Google Maps dan FCM push notification) secara bertahap.",
            "penerapan": "Pengembangan dibagi per Milestone (Milestone 1: Auth, Milestone 2: Nearby Location, Milestone 3: Sesi & Chat, dst.).",
            "relasi": "Mengontrol jadwal commit Git dan perilisan modul fitur.",
            "tanya": "Mengapa menggunakan Iterative Development ketimbang Waterfall?",
            "jawab": "Karena proyek ini mengintegrasikan layanan eksternal (Google Maps API & Push Notification). Dengan pendekatan iteratif, setiap modul yang selesai langsung diuji secara dinamis, sehingga bug integrasi terdeteksi lebih cepat daripada menunggu seluruh sistem selesai.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "Version Control (Git & GitHub)",
            "def": "Sistem yang melacak riwayat perubahan file kode program sehingga pengembang dapat berkolaborasi dan melakukan rollback jika terjadi error.",
            "imp": "Mencegah kehilangan kode sumber yang stabil saat melakukan modifikasi besar-besaran.",
            "penerapan": "Penggunaan branching Git lokal, push ke GitHub, dan pelacakan riwayat migrasi SQL di folder `supabase/migrations/`.",
            "relasi": "Penyimpanan pusat dari seluruh source code proyek.",
            "tanya": "Apa kegunaan file .gitignore pada proyek Flutter Anda?",
            "jawab": "Untuk mengecualikan file konfigurasi lokal perangkat, file build sementara, dan file kredensial sensitif (seperti local.properties atau service account JSON) agar tidak ter-upload ke repositori publik GitHub demi keamanan.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_b:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # C. Arsitektur Sistem
    # ----------------------------------------------------
    doc.add_heading('C. Arsitektur Sistem', level=1)
    
    materi_c = [
        {
            "nama": "Three-Tier Architecture (Client-Server)",
            "def": "Arsitektur perangkat lunak yang membagi sistem menjadi tiga lapisan logis utama: Presentation Layer, Application/Business Logic Layer, dan Data Layer.",
            "imp": "Memastikan aplikasi mobile (client) tidak dibebani oleh proses kalkulasi database yang berat.",
            "penerapan": "Presentation: Flutter Client. Application: Supabase Edge Functions & API. Data Layer: PostgreSQL database.",
            "relasi": "Membentuk topologi jaringan komunikasi HTTP dan WebSockets pada aplikasi.",
            "tanya": "Di manakah letak enkripsi dan proteksi data pada arsitektur Three-Tier Anda?",
            "jawab": "Enkripsi data dalam transit menggunakan protokol HTTPS/WSS. Di tingkat Data Layer, data dilindungi oleh Row Level Security (RLS) PostgreSQL, dan di tingkat Application Layer menggunakan token JWT (JSON Web Token) sebagai verifikasi identitas.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "Clean Architecture & Feature-First Structure di Flutter",
            "def": "Pendekatan struktur folder dan kode yang memisahkan tanggung jawab (Separation of Concerns) berdasarkan modul fitur, di mana di dalam tiap fitur dibagi menjadi layer UI, Controller, Domain, dan Data.",
            "imp": "Membuat kode program rapi, mudah dibaca oleh developer lain, dan mudah di-maintain.",
            "penerapan": "Struktur folder `lib/features/auth/`, `lib/features/discovery/`, dll. Di dalamnya terdapat subfolder `presentation/` (UI), `application/` (State Controller), `domain/` (Model), dan `data/` (Repository).",
            "relasi": "Mengatur dependency flow di dalam kode Flutter, di mana UI memanggil Controller, Controller memanggil Repository, dan Repository mengakses Supabase Client.",
            "tanya": "Apa fungsi layer Repository pada Clean Architecture?",
            "jawab": "Repository bertindak sebagai mediator yang menjembatani logika bisnis dengan sumber data eksternal (Supabase SDK). Layer ini mengabstraksi pemanggilan API sehingga jika di masa depan database/API diganti, kita tidak perlu merombak UI atau Controller.",
            "prioritas": "Sangat Disarankan"
        },
        {
            "nama": "State Management & Dependency Injection (Riverpod)",
            "def": "State Management: Mekanisme mengelola dan memperbarui data UI secara reaktif. Dependency Injection: Pola menyuplai instansiasi objek dependensi dari luar kelas yang membutuhkannya.",
            "imp": "Menjaga keandalan data real-time chat, sisa saldo wallet, dan status sesi agar sinkron di seluruh widget.",
            "penerapan": "Menggunakan package `flutter_riverpod` dengan provider global seperti `authControllerProvider` untuk injeksi dependency repositori ke controller.",
            "relasi": "Menghubungkan visual widget dengan logika bisnis secara modular tanpa kebocoran memori.",
            "tanya": "Mengapa memilih Riverpod ketimbang Provider biasa atau setState?",
            "jawab": "Riverpod aman dari kesalahan runtime context, tidak bergantung pada widget tree Flutter untuk dependency lookup, dan mendukung validasi compile-time. Jauh lebih andal dibanding `setState` yang hanya bersifat lokal.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_c:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # D. Basis Data
    # ----------------------------------------------------
    doc.add_heading('D. Basis Data (Database)', level=1)
    
    materi_d = [
        {
            "nama": "Normalisasi Database (3NF)",
            "def": "Proses mendesain skema database relasional untuk meminimalkan duplikasi data (redundansi) dan mencegah anomali insert, update, dan delete.",
            "imp": "Mencegah data jadwal availability tutor atau transaksi pembayaran bulanan terduplikasi secara tidak konsisten.",
            "penerapan": "Pemisahan entitas: `users` (auth dasar), `tutors` (profil spesifik les), `tutor_availability` (slot jam), dan `bookings` (transaksi/kontrak paket).",
            "relasi": "Relasi tabel dihubungkan melalui Foreign Key dan dijamin integritasnya oleh database constraint.",
            "tanya": "Mengapa tabel tutor_availability dipisah dari tabel tutors?",
            "jawab": "Karena satu tutor dapat memiliki banyak slot availability (One-to-Many). Memisahkannya ke tabel tersendiri mematuhi aturan normalisasi 1NF/2NF dan mempermudah query JOIN pencarian jadwal dibanding menyimpan array di dalam kolom tutor.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "PostGIS Spasial & GiST Indexing",
            "def": "PostGIS: Ekstensi spasial PostgreSQL untuk mendukung query koordinat geografis. GiST: Indeks basis data spasial untuk mempercepat pencarian data berbasis koordinat (Point/Polygon).",
            "imp": "Sebagai pondasi ilmiah fitur 'Pencarian Tutor Terdekat' berdasarkan radius jarak GPS.",
            "penerapan": "Kolom `location` bertipe `geography(Point, 4326)` di tabel `tutors` diberi indeks GiST. Pencarian menggunakan fungsi `ST_DWithin` dalam radius 1/5/10/20 km lewat RPC database `get_nearby_tutors`.",
            "relasi": "Berhubungan langsung dengan sensor GPS perangkat mobile (via Geolocator) dan marker peta Google Maps.",
            "tanya": "Bagaimana cara kerja pencarian radius terdekat di database Anda?",
            "jawab": "Flutter mengirimkan koordinat latitude-longitude murid beserta radius ke RPC `get_nearby_tutors`. Di database, PostGIS memanfaatkan indeks GiST untuk menyaring baris tutor yang jaraknya $\le$ radius masukan menggunakan fungsi `ST_DWithin` secara instan tanpa melakukan full table scan.",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "Database Triggers & Integritas Status",
            "def": "Trigger: Prosedur tersimpan yang otomatis dieksekusi oleh database sebagai respon terhadap event tertentu (INSERT/UPDATE/DELETE).",
            "imp": "Mengamankan aturan bisnis krusial agar tidak bisa dimanipulasi oleh celah keamanan API di sisi client.",
            "penerapan": "Trigger `validate_package_booking` memvalidasi ketersediaan jadwal tutor, bentrok dengan murid lain, dan batasan maksimal 2 murid aktif per tutor sebelum data booking disimpan.",
            "relasi": "Mengeblok data tidak valid langsung pada RDBMS sebelum data tersebut menyebar ke tabel transaksi atau sesi.",
            "tanya": "Bagaimana jika ada hacker memanipulasi aplikasi client untuk mengubah status booking menjadi paid tanpa bayar?",
            "jawab": "Tidak bisa, karena database dilindungi trigger transisi status. Trigger mendeteksi perubahan status dan akan menolak modifikasi ilegal jika transaksi terkait di tabel `transactions` tidak berstatus lunas (paid). Database adalah source of truth terakhir.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_d:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # E. Backend dan API
    # ----------------------------------------------------
    doc.add_heading('E. Backend dan API', level=1)
    
    materi_e = [
        {
            "nama": "REST API & HTTP Request/Response",
            "def": "Protokol komunikasi standar client-server menggunakan metode HTTP (GET, POST, PUT, DELETE) untuk manipulasi data.",
            "imp": "Sebagai jembatan utama pengiriman dan pengambilan data aplikasi mobile.",
            "penerapan": "Flutter memanggil REST API Supabase (melalui client SDK) untuk operasi CRUD.",
            "relasi": "Menghubungkan database PostgreSQL Supabase dengan UI Flutter.",
            "tanya": "Jelaskan perbedaan fungsi HTTP Method POST, GET, dan PATCH!",
            "jawab": "POST digunakan untuk membuat record baru (seperti membuat booking baru), GET digunakan untuk membaca data (seperti menampilkan profil tutor), dan PATCH digunakan untuk memperbarui data sebagian (seperti mengubah nama profil).",
            "prioritas": "Wajib Dikuasai"
        },
        {
            "nama": "API Security: JWT, RLS & OAuth 2.0",
            "def": "Sistem pengamanan antarmuka API menggunakan JSON Web Token (JWT) untuk autentikasi sesi, Row Level Security (RLS) untuk otorisasi akses baris database, dan OAuth 2.0 untuk integrasi pihak ketiga.",
            "imp": "Menjaga keamanan data privat user agar tidak dapat diakses atau di-hack oleh user lain.",
            "penerapan": "Setiap request Flutter menyertakan token JWT Supabase. Database mengevaluasi JWT tersebut di RLS Policy (contoh: `auth.uid() = user_uid`) untuk mengizinkan atau menolak akses query.",
            "relasi": "Melindungi Data Layer dari akses ilegal melalui Application Layer.",
            "tanya": "Apa itu Row Level Security (RLS) di PostgreSQL?",
            "jawab": "RLS adalah fitur keamanan database PostgreSQL yang memungkinkan administrator menyaring data yang boleh diakses/diubah oleh pengguna tertentu di tingkat baris tabel (*row-by-row basis*) berdasarkan parameter sesi seperti token JWT user.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_e:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # F. Frontend/Mobile Development
    # ----------------------------------------------------
    doc.add_heading('F. Frontend/Mobile Development', level=1)
    
    materi_f = [
        {
            "nama": "UI/UX & Responsive Design",
            "def": "UI: Desain visual antarmuka sistem. UX: Tingkat kenyamanan dan kemudahan pengguna saat berinteraksi dengan sistem. Responsive Design: Desain tata letak yang mampu menyesuaikan berbagai ukuran layar perangkat.",
            "imp": "Menentukan daya tarik visual (wow-factor) dan kemudahan pencarian tutor terdekat.",
            "penerapan": "Penggunaan tema warna gradien ungu-pink, font modern, transisi visual smooth, serta layout dinamis dengan `CustomScrollView` dan `SliverAppBar`.",
            "relasi": "Tampilan langsung yang dihadapi pengguna di perangkat fisik ponsel.",
            "tanya": "Bagaimana Anda menjamin konsistensi tata letak visual di berbagai ukuran layar Android?",
            "jawab": "Kami menggunakan widget layout bawaan Flutter seperti `LayoutBuilder`, `MediaQuery` untuk dimensi proporsional, serta widget fleksibel seperti `ListView`, `Grid`, dan `Sliver` agar konten dapat mengalir menyesuaikan ukuran layar tanpa terjadi error overflow.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_f:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # G. Pengujian Sistem
    # ----------------------------------------------------
    doc.add_heading('G. Pengujian Sistem', level=1)
    
    materi_g = [
        {
            "nama": "Black Box Testing & User Acceptance Testing (UAT)",
            "def": "Black Box: Pengujian fungsionalitas aplikasi tanpa melihat kode program internal. UAT: Pengujian yang melibatkan pengguna asli (Murid & Tutor) untuk menilai kelayakan fungsional sistem.",
            "imp": "Membuktikan secara ilmiah bahwa aplikasi EduConnect siap diimplementasikan dan diterima baik oleh pengguna.",
            "penerapan": "Pengujian Black Box terhadap skenario booking & chat. Pengujian UAT disebarkan kepada 20 responden (10 murid, 10 tutor) menggunakan Skala Likert 5 Poin dengan 4 aspek pengujian (Usability, Functionality, Interface Design, Reliability).",
            "relasi": "Validasi akhir sebelum aplikasi dinyatakan layak dirilis ke tahap produksi.",
            "tanya": "Berapa persen tingkat kelayakan UAT sistem Anda dan bagaimana kesimpulannya?",
            "jawab": "Tingkat kelayakan UAT EduConnect mencapai rata-rata total 92,06%. Menurut rentang kriteria kelayakan Skala Likert, skor ini berada di atas 81%, sehingga disimpulkan bahwa aplikasi EduConnect berkualifikasi 'Sangat Layak' untuk diimplementasikan.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_g:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # H. Keamanan Sistem
    # ----------------------------------------------------
    doc.add_heading('H. Keamanan Sistem', level=1)
    
    materi_h = [
        {
            "nama": "Input Validation & Sanitization (XSS & SQL Injection Prevention)",
            "def": "Input Validation: Menyaring input pengguna agar sesuai kriteria tipe data. Sanitization: Membersihkan karakter berbahaya (seperti tanda petik tunggal atau tag script HTML) untuk mencegah injeksi database dan cross-site scripting.",
            "imp": "Mencegah peretas merusak skema database atau menyusupkan script jahat lewat kolom chat.",
            "penerapan": "Penerapan validasi Form di Flutter (`validator` callback) untuk mengecek panjang password dan email. Supabase otomatis mencegah SQL Injection dengan PostgREST parameterized query.",
            "relasi": "Pelindung gerbang utama antara input UI pengguna dengan API backend.",
            "tanya": "Bagaimana sistem Anda mencegah serangan XSS di kolom chat?",
            "jawab": "Flutter secara default merender teks chat sebagai objek Text murni (bukan widget WebView atau HTML parser). Akibatnya, script HTML/JavaScript apa pun yang dikirimkan peretas akan ditampilkan sebagai string teks biasa di layar penerima tanpa dieksekusi oleh sistem.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_h:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # I. Infrastruktur dan Deployment
    # ----------------------------------------------------
    doc.add_heading('I. Infrastruktur dan Deployment', level=1)
    
    materi_i = [
        {
            "nama": "Push Notification Pipeline & Edge Functions",
            "def": "Push Notification Pipeline: Rangkaian pengiriman pesan notifikasi dari database ke server Firebase Cloud Messaging (FCM) hingga sampai di ponsel. Edge Functions: Layanan runtime serverless berlatensi rendah untuk mengeksekusi script backend tanpa server tetap.",
            "imp": "Mengirim pengingat sesi H-24 dan H-2 jam secara otomatis dan andal ke ponsel pengguna tanpa membebani HP client.",
            "penerapan": "Database trigger memasukkan antrean ke `push_delivery_queue`. Edge Function Deno `dispatch-push` membaca antrean tersebut, mengambil token OAuth 2.0 FCM, dan menembakkannya ke API FCM HTTP v1 untuk dikirim ke perangkat.",
            "relasi": "Menghubungkan basis data, serverless worker, Firebase cloud, dan perangkat fisik mobile.",
            "tanya": "Mengapa reminder H-24 dan H-2 jam tidak dipicu langsung dari siklus halaman aplikasi Flutter?",
            "jawab": "Karena jika dipicu dari client, notifikasi tidak akan terkirim jika aplikasi dalam keadaan tertutup (*terminate state*) atau ponsel mati. Memindahkan pemicuan ke Edge Functions/Cron database menjamin reminder terkirim tepat waktu secara independen tanpa bergantung pada status aplikasi client.",
            "prioritas": "Wajib Dikuasai"
        }
    ]

    for m in materi_i:
        doc.add_heading(m['nama'], level=2)
        doc.add_paragraph(f"1. Definisi: {m['def']}")
        doc.add_paragraph(f"2. Mengapa Penting: {m['imp']}")
        doc.add_paragraph(f"3. Penerapan di Sistem: {m['penerapan']}")
        doc.add_paragraph(f"4. Hubungan Komponen: {m['relasi']}")
        doc.add_paragraph(f"5. Pertanyaan Sidang: \"{m['tanya']}\"")
        p_jawab = doc.add_paragraph()
        r_jawab = p_jawab.add_run(f"   Jawaban Ideal: {m['jawab']}")
        r_jawab.bold = True
        doc.add_paragraph(f"6. Prioritas: {m['prioritas']}\n")

    # ----------------------------------------------------
    # K. Tabel Persiapan Sidang
    # ----------------------------------------------------
    doc.add_heading('K. Persiapan Sidang: Risiko Kompetensi', level=1)
    doc.add_paragraph("Tabel pemetaan materi krusial beserta risiko kegagalan sidang jika tidak dikuasai:")

    table = doc.add_table(rows=1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.style = 'Table Grid'
    hdr_cells = table.rows[0].cells
    hdr_cells[0].text = 'Materi'
    hdr_cells[1].text = 'Tingkat Penguasaan'
    hdr_cells[2].text = 'Risiko Jika Tidak Menguasai'

    risiko_data = [
        ("Row Level Security (RLS) Supabase", "Sangat Tinggi (Wajib)", "Aplikasi dicap tidak aman karena peretas bisa mencuri/mengubah data user lain lewat endpoint API."),
        ("PostGIS (GiST Indexing Spasial)", "Sangat Tinggi (Wajib)", "Anda gagal menjelaskan metode pencarian radius terdekat dan dituduh melakukan plagiat template kode."),
        ("Database Triggers & Integritas Status", "Tinggi (Sangat Disarankan)", "Sistem dianggap rentan terhadap manipulasi transaksi ilegal karena validasi status hanya diletakkan di sisi client."),
        ("Riverpod State Management", "Tinggi (Sangat Disarankan)", "Gagal menjelaskan alur pemindahan data asinkron dari API ke widget UI, dinilai kurang paham konsep OOP/reaktif."),
        ("Metodologi UAT & Skala Likert", "Tinggi (Wajib)", "Hasil presentasi pengujian dianggap fiktif / karangan karena tidak bisa menjelaskan dasar kalkulasi statistiknya.")
    ]

    for materi, tingkat, risiko in risiko_data:
        row_cells = table.add_row().cells
        row_cells[0].text = materi
        row_cells[1].text = tingkat
        row_cells[2].text = risiko

    doc.add_paragraph("\n")

    # ----------------------------------------------------
    # L. Ringkasan Akhir & Roadmap Belajar
    # ----------------------------------------------------
    doc.add_heading('L. Ringkasan Akhir & Roadmap Belajar', level=1)
    
    doc.add_heading('1. 10 Pertanyaan Menjebak yang Sering Muncul', level=2)
    menjebak_data = [
        "Bagaimana jika dua murid memesan slot jadwal tutor yang sama di detik yang sama? (Race Condition)",
        "Apa perbedaan koordinat sistem bumi bulat (SRID 4326) dengan sistem peta Google Maps (SRID 3857)?",
        "Mengapa file credentials Firebase service account JSON tidak boleh dimasukkan ke dalam file build APK?",
        "Di manakah filter pencarian radius diproses, di aplikasi mobile Flutter atau di server database Supabase?",
        "Berapa lama token akses JWT Supabase bertahan dan bagaimana ia diperbarui tanpa memaksa user login kembali?",
        "Apa yang terjadi jika koneksi internet terputus di tengah pengiriman pesan chat real-time?",
        "Mengapa Anda tidak menggunakan database NoSQL seperti Firebase Firestore untuk sistem booking ini?",
        "Bagaimana cara mengamankan bucket storage 'tutor-photos' di Supabase agar tidak ada user yang menghapus foto tutor lain?",
        "Bagaimana Anda membuktikan bahwa pengisian kuisioner UAT dilakukan secara valid dan tidak dimanipulasi?",
        "Mengapa trigger database dinilai lebih aman untuk validasi aturan bisnis daripada controller di Flutter?"
    ]
    for q in menjebak_data:
        doc.add_paragraph(f"- {q}")

    doc.add_heading('2. Roadmap Belajar Menuju Hari-H Sidang (Estimasi 4 Minggu)', level=2)
    doc.add_paragraph("1. Minggu 1: Fokus penguasaan database relasional, query SQL, manipulasi PostGIS, dan aturan RLS (12 Jam Belajar).")
    doc.add_paragraph("2. Minggu 2: Pelajari arsitektur Flutter (Clean Architecture), Dependency Injection, dan alur State Riverpod (12 Jam Belajar).")
    doc.add_paragraph("3. Minggu 3: Kuasai alur pengiriman push notification FCM, konfigurasi Edge Functions, dan trigger status DB (14 Jam Belajar).")
    doc.add_paragraph("4. Minggu 4: Review dokumen bab 4-5, kuasai kalkulasi data UAT, dan simulasi tanya jawab mental sidang (10 Jam Belajar).")

    # Save
    filepath = "d:/apk_edu/Materi_Persiapan_Sidang_EduConnect.docx"
    doc.save(filepath)
    print(f"File DOCX berhasil dibuat di: {filepath}")

if __name__ == '__main__':
    build_prep_doc()
