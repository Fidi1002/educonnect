# PowerShell script using Word COM Object to create the study guide.
$docxPath = "d:\apk_edu\Materi_Persiapan_Sidang_EduConnect.docx"

Write-Host "Membuka Microsoft Word..."
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()

Write-Host "Mengatur format halaman (A4, Left/Right/Top/Bottom)..."
$doc.PageSetup.PaperSize = 7 # wdPaperA4
$doc.PageSetup.TopMargin = $word.CentimetersToPoints(2.54)
$doc.PageSetup.BottomMargin = $word.CentimetersToPoints(2.54)
$doc.PageSetup.LeftMargin = $word.CentimetersToPoints(2.54)
$doc.PageSetup.RightMargin = $word.CentimetersToPoints(2.54)

$selection = $word.Selection
$selection.Font.Name = "Calibri"
$selection.Font.Size = 11
$selection.ParagraphFormat.LineSpacingRule = 5 # 1.5 spacing
$selection.ParagraphFormat.Alignment = 3 # Justify
$selection.ParagraphFormat.SpaceAfter = 6

function Add-Heading {
    param([string]$text, [int]$level)
    $selection.TypeParagraph()
    $selection.ParagraphFormat.KeepWithNext = $true
    if ($level -eq 1) {
        $selection.Font.Bold = $true
        $selection.Font.Size = 16
        $selection.Font.ColorIndex = 13 # Violet/Purple equivalent or dark blue
        $selection.ParagraphFormat.SpaceBefore = 18
        $selection.ParagraphFormat.SpaceAfter = 8
        $selection.ParagraphFormat.Alignment = 0 # Left
    } elseif ($level -eq 2) {
        $selection.Font.Bold = $true
        $selection.Font.Size = 13
        $selection.Font.ColorIndex = 0 # Auto/Black
        $selection.ParagraphFormat.SpaceBefore = 12
        $selection.ParagraphFormat.SpaceAfter = 6
        $selection.ParagraphFormat.Alignment = 0
    }
    $selection.TypeText($text)
    # Reset
    $selection.TypeParagraph()
    $selection.Font.Bold = $false
    $selection.Font.Size = 11
    $selection.Font.ColorIndex = 0
    $selection.ParagraphFormat.SpaceBefore = 0
    $selection.ParagraphFormat.SpaceAfter = 6
    $selection.ParagraphFormat.Alignment = 3 # Justify
    $selection.ParagraphFormat.KeepWithNext = $false
}

function Add-Body {
    param([string]$text, [boolean]$bold = $false)
    $selection.Font.Bold = $bold
    $selection.TypeText($text)
    $selection.TypeParagraph()
    $selection.Font.Bold = $false
}

function Add-Bullet {
    param([string]$text, [string]$label)
    $selection.ParagraphFormat.LeftIndent = $word.CentimetersToPoints(0.6)
    $selection.Font.Bold = $true
    $selection.TypeText($label + ": ")
    $selection.Font.Bold = $false
    $selection.TypeText($text)
    $selection.TypeParagraph()
    $selection.ParagraphFormat.LeftIndent = 0
}

# --- COVER / TITLE ---
$selection.ParagraphFormat.Alignment = 1 # Center
$selection.Font.Bold = $true
$selection.Font.Size = 20
$selection.TypeText("PANDUAN BELAJAR & PERSIAPAN SIDANG SKRIPSI`n")
$selection.Font.Size = 16
$selection.TypeText("SISTEM EDUCONNECT`n")
$selection.Font.Size = 12
$selection.Font.Bold = $false
$selection.TypeText("Aplikasi Pencarian Tutor Terdekat Berbasis Lokasi (Flutter + Supabase)`n")
$selection.TypeParagraph()
$selection.ParagraphFormat.Alignment = 3 # Justified

# A. Analisis dan Perancangan Sistem
Add-Heading "A. Analisis dan Perancangan Sistem" 1

Add-Heading "1. Analisis Kebutuhan (Requirement Analysis)" 2
Add-Bullet "Proses menganalisis, mendokumentasikan, dan memvalidasi kebutuhan pengguna serta batasan sistem yang akan dikembangkan agar sistem tepat guna." "Definisi"
Add-Bullet "Memastikan sistem EduConnect memiliki batasan operasional yang jelas antara Murid (pencari tutor, booking, chat) dan Tutor (manajemen jadwal, review PR)." "Mengapa Penting"
Add-Bullet "Menyusun spesifikasi kebutuhan perangkat lunak (SRS) yang membagi fungsionalitas berdasarkan hak akses user." "Penerapan di Sistem"
Add-Bullet "Menjadi acuan dasar pembuatan use case diagram, alur database, serta halaman antarmuka pengguna." "Hubungan Komponen"
Add-Bullet "Bagaimana Anda memvalidasi bahwa radius pencarian yang Anda batasi (1-20 km) sudah cukup untuk murid?" "Pertanyaan Sidang"
Add-Bullet "Berdasarkan analisis mobilitas lokal, radius 1-5 km ditargetkan untuk efisiensi biaya transportasi tutor/murid (les tatap muka), sedangkan 10-20 km adalah batas maksimal wajar perjalanan darat perkotaan." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

Add-Heading "2. User Requirement" 2
Add-Bullet "Pernyataan tentang layanan apa yang diharapkan disediakan oleh sistem dan batasan-batasan operasional dari sudut pandang user." "Definisi"
Add-Bullet "Sangat penting karena EduConnect mendefinisikan alur onboarding yang berbeda sejak awal antara peran Murid (Student) dan Tutor." "Mengapa Penting"
Add-Bullet "Pengguna yang baru mendaftar wajib memilih peran pada halaman Role Onboarding sebelum dapat menggunakan fitur utama." "Penerapan di Sistem"
Add-Bullet "Memengaruhi logic filter otorisasi navigasi rute di Flutter (GoRouter) dan RLS di PostgreSQL." "Hubungan Komponen"
Add-Bullet "Mengapa setelah memilih peran, user dipaksa logout dahulu?" "Pertanyaan Sidang"
Add-Bullet "Untuk me-refresh token session JWT Supabase secara bersih. Ketika user login kembali, klaim role yang baru tersimpan di database akan tersemat ke dalam JWT, sehingga sistem navigasi GoRouter memuat halaman utama sesuai role dengan aman." "Jawaban Ideal"
Add-Bullet "Sangat Disarankan" "Prioritas"

Add-Heading "3. Functional & Non-Functional Requirement" 2
Add-Bullet "Functional: Fungsi atau layanan spesifik yang wajib disediakan sistem. Non-Functional: Batasan kualitas, keamanan, keandalan, dan performa dari layanan tersebut." "Definisi"
Add-Bullet "Mengendalikan keberhasilan teknis sistem, seperti query spasial pencarian radius (Functional) dan keamanan RLS database (Non-Functional)." "Mengapa Penting"
Add-Bullet "Functional: Fitur booking paket belajar 1-6 bulan. Non-Functional: Waktu respon query di bawah 2 detik dan pencegahan manipulasi status booking." "Penerapan di Sistem"
Add-Bullet "Diterjemahkan langsung menjadi backend trigger/RPC di database, dan state controller di Flutter." "Hubungan Komponen"
Add-Bullet "Berikan contoh non-functional requirement keamanan di sistem Anda!" "Pertanyaan Sidang"
Add-Bullet "Semua akses data ke tabel inti wajib melewati kebijakan Row Level Security (RLS) di PostgreSQL Supabase, memastikan user hanya bisa memodifikasi datanya sendiri." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

Add-Heading "4. Use Case Diagram" 2
Add-Bullet "Diagram yang memodelkan interaksi antara aktor (pengguna) dengan sistem untuk menunjukkan fungsionalitas yang disediakan." "Definisi"
Add-Bullet "Menggambarkan batas hak akses pengguna (Murid vs Tutor) secara visual." "Mengapa Penting"
Add-Bullet "Use case 'Mencari Tutor' dikaitkan dengan aktor Murid; use case 'Atur Availability' dikaitkan dengan Tutor; use case 'Kirim Pesan Chat' dikaitkan keduanya." "Penerapan di Sistem"
Add-Bullet "Menjadi panduan pembuatan menu navigasi UI dan otorisasi API." "Hubungan Komponen"
Add-Bullet "Apakah Murid bisa mengakses use case milik Tutor?" "Pertanyaan Sidang"
Add-Bullet "Tidak. Sistem melakukan pengecekan role di sisi client via GoRouter dan di sisi server via RLS Policy database." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

Add-Heading "5. Entity Relationship Diagram (ERD)" 2
Add-Bullet "Diagram yang menggambarkan struktur basis data logis, entitas, atribut, dan relasi di antaranya." "Definisi"
Add-Bullet "Sebagai blueprint database relasional EduConnect yang mengelola relasi user, tutor, booking, transaksi, dan chat." "Mengapa Penting"
Add-Bullet "Tabel users berelasi One-to-One dengan tutors, dan One-to-Many dengan bookings. Tabel bookings berelasi One-to-Many dengan booking_sessions." "Penerapan di Sistem"
Add-Bullet "Diterjemahkan langsung menjadi skema tabel DDL SQL di Supabase." "Hubungan Komponen"
Add-Bullet "Mengapa data profil tutor dipisah dari tabel users?" "Pertanyaan Sidang"
Add-Bullet "Untuk memenuhi prinsip normalisasi data (1NF/2NF) dan efisiensi query. Kolom spesifik tutor seperti tarif, bio, subjek, dan PostGIS location point hanya dibuat jika user mendaftar sebagai tutor, menjaga data user biasa (murid) tetap ramping." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# B. Pengembangan Perangkat Lunak
Add-Heading "B. Pengembangan Perangkat Lunak" 1

Add-Heading "1. SDLC - Iterative/Agile Development" 2
Add-Bullet "Metodologi pengembangan perangkat lunak yang memecah proses menjadi beberapa iterasi/milestone berulang untuk meningkatkan dan mengevaluasi sistem secara berkala." "Definisi"
Add-Bullet "Mempermudah penanganan bug logika kompleks (seperti integrasi Google Maps dan FCM push notification) secara bertahap." "Mengapa Penting"
Add-Bullet "Pengembangan dibagi per Milestone (Milestone 1: Auth, Milestone 2: Nearby Location, Milestone 3: Sesi & Chat, dst.)." "Penerapan di Sistem"
Add-Bullet "Mengontrol jadwal commit Git dan perilisan modul fitur." "Hubungan Komponen"
Add-Bullet "Mengapa menggunakan Iterative Development ketimbang Waterfall?" "Pertanyaan Sidang"
Add-Bullet "Karena proyek ini mengintegrasikan layanan eksternal (Google Maps API & Push Notification). Dengan pendekatan iteratif, setiap modul yang selesai langsung diuji secara dinamis, sehingga bug integrasi terdeteksi lebih cepat daripada menunggu seluruh sistem selesai." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

Add-Heading "2. Version Control (Git & GitHub)" 2
Add-Bullet "Sistem yang melacak riwayat perubahan file kode program sehingga pengembang dapat berkolaborasi dan melakukan rollback jika terjadi error." "Definisi"
Add-Bullet "Mencegah kehilangan kode sumber yang stabil saat melakukan modifikasi besar-besaran." "Mengapa Penting"
Add-Bullet "Penggunaan branching Git lokal, push ke GitHub, dan pelacakan riwayat migrasi SQL di folder supabase/migrations/." "Penerapan di Sistem"
Add-Bullet "Penyimpanan pusat dari seluruh source code proyek." "Hubungan Komponen"
Add-Bullet "Apa kegunaan file .gitignore pada proyek Flutter Anda?" "Pertanyaan Sidang"
Add-Bullet "Untuk mengecualikan file konfigurasi lokal perangkat, file build sementara, dan file kredensial sensitif (seperti local.properties atau service account JSON) agar tidak ter-upload ke repositori publik GitHub demi keamanan." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# C. Arsitektur Sistem
Add-Heading "C. Arsitektur Sistem" 1

Add-Heading "1. Three-Tier Architecture (Client-Server)" 2
Add-Bullet "Arsitektur perangkat lunak yang membagi sistem menjadi tiga lapisan logis utama: Presentation Layer, Application/Business Logic Layer, dan Data Layer." "Definisi"
Add-Bullet "Memastikan aplikasi mobile (client) tidak dibebani oleh proses kalkulasi database yang berat." "Mengapa Penting"
Add-Bullet "Presentation: Flutter Client. Application: Supabase Edge Functions & API. Data Layer: PostgreSQL database." "Penerapan di Sistem"
Add-Bullet "Membentuk topologi jaringan komunikasi HTTP dan WebSockets pada aplikasi." "Hubungan Komponen"
Add-Bullet "Di manakah letak enkripsi dan proteksi data pada arsitektur Three-Tier Anda?" "Pertanyaan Sidang"
Add-Bullet "Enkripsi data dalam transit menggunakan protokol HTTPS/WSS. Di tingkat Data Layer, data dilindungi oleh Row Level Security (RLS) PostgreSQL, dan di tingkat Application Layer menggunakan token JWT (JSON Web Token) sebagai verifikasi identitas." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

Add-Heading "2. Clean Architecture di Flutter" 2
Add-Bullet "Pendekatan struktur folder dan kode yang memisahkan tanggung jawab (Separation of Concerns) berdasarkan modul fitur, di mana di dalam tiap fitur dibagi menjadi layer UI, Controller, Domain, dan Data." "Definisi"
Add-Bullet "Membuat kode program rapi, mudah dibaca oleh developer lain, dan mudah di-maintain." "Mengapa Penting"
Add-Bullet "Struktur folder lib/features/auth/, lib/features/discovery/, dll. Di dalamnya terdapat subfolder presentation/ (UI), application/ (State Controller), domain/ (Model), dan data/ (Repository)." "Penerapan di Sistem"
Add-Bullet "Mengatur dependency flow di dalam kode Flutter, di mana UI memanggil Controller, Controller memanggil Repository, dan Repository mengakses Supabase Client." "Hubungan Komponen"
Add-Bullet "Apa fungsi layer Repository pada Clean Architecture?" "Pertanyaan Sidang"
Add-Bullet "Repository bertindak sebagai mediator yang menjembatani logika bisnis dengan sumber data eksternal (Supabase SDK). Layer ini mengabstraksi pemanggilan API sehingga jika di masa depan database/API diganti, kita tidak perlu merombak UI atau Controller." "Jawaban Ideal"
Add-Bullet "Sangat Disarankan" "Prioritas"

Add-Heading "3. State Management (Riverpod)" 2
Add-Bullet "Mekanisme mengelola dan memperbarui data UI secara reaktif di seluruh halaman widget Flutter." "Definisi"
Add-Bullet "Menjaga keandalan data real-time chat, sisa saldo wallet, dan status sesi agar sinkron di seluruh widget." "Mengapa Penting"
Add-Bullet "Menggunakan package flutter_riverpod dengan provider global seperti authControllerProvider untuk injeksi dependency repositori ke controller." "Penerapan di Sistem"
Add-Bullet "Menghubungkan visual widget dengan logika bisnis secara modular tanpa kebocoran memori." "Hubungan Komponen"
Add-Bullet "Mengapa memilih Riverpod ketimbang Provider biasa atau setState?" "Pertanyaan Sidang"
Add-Bullet "Riverpod aman dari kesalahan runtime context, tidak bergantung pada widget tree Flutter untuk dependency lookup, dan mendukung validasi compile-time. Jauh lebih andal dibanding setState yang hanya bersifat lokal." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# D. Basis Data
Add-Heading "D. Basis Data (Database)" 1

Add-Heading "1. Normalisasi Database (3NF)" 2
Add-Bullet "Proses mendesain skema database relasional untuk meminimalkan duplikasi data (redundansi) dan mencegah anomali insert, update, dan delete." "Definisi"
Add-Bullet "Mencegah data jadwal availability tutor atau transaksi pembayaran bulanan terduplikasi secara tidak konsisten." "Mengapa Penting"
Add-Bullet "Pemisahan entitas: users (auth dasar), tutors (profil spesifik les), tutor_availability (slot jam), dan bookings (transaksi/kontrak paket)." "Penerapan di Sistem"
Add-Bullet "Relasi tabel dihubungkan melalui Foreign Key dan dijamin integritasnya oleh database constraint." "Hubungan Komponen"
Add-Bullet "Mengapa tabel tutor_availability dipisah dari tabel tutors?" "Pertanyaan Sidang"
Add-Bullet "Karena satu tutor dapat memiliki banyak slot availability (One-to-Many). Memisahkannya ke tabel tersendiri mematuhi aturan normalisasi 1NF/2NF dan mempermudah query JOIN pencarian jadwal dibanding menyimpan array di dalam kolom tutor." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# E. Backend dan API
Add-Heading "E. Backend dan API" 1

Add-Heading "1. REST API & HTTP Request/Response" 2
Add-Bullet "Protokol komunikasi standar client-server menggunakan metode HTTP (GET, POST, PATCH, DELETE) untuk manipulasi data." "Definisi"
Add-Bullet "Sebagai jembatan utama pengiriman dan pengambilan data aplikasi mobile." "Mengapa Penting"
Add-Bullet "Flutter memanggil REST API Supabase (melalui client SDK) untuk operasi CRUD." "Penerapan di Sistem"
Add-Bullet "Menghubungkan database PostgreSQL Supabase dengan UI Flutter." "Hubungan Komponen"
Add-Bullet "Jelaskan perbedaan fungsi HTTP Method POST, GET, dan PATCH!" "Pertanyaan Sidang"
Add-Bullet "POST digunakan untuk membuat record baru (seperti membuat booking baru), GET digunakan untuk membaca data (seperti menampilkan profil tutor), dan PATCH digunakan untuk memperbarui data sebagian (seperti mengubah nama profil)." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# F. Frontend/Mobile Development
Add-Heading "F. Frontend/Mobile Development" 1

Add-Heading "1. UI/UX & Responsive Design" 2
Add-Bullet "UI: Desain visual antarmuka. UX: Kenyamanan interaksi. Responsive Design: Menyesuaikan tata letak pada berbagai ukuran layar ponsel." "Definisi"
Add-Bullet "Menentukan daya tarik visual (wow-factor) dan kemudahan pencarian tutor terdekat." "Mengapa Penting"
Add-Bullet "Penggunaan tema warna gradien ungu-pink, font modern, transisi visual smooth, serta layout dinamis dengan CustomScrollView dan SliverAppBar." "Penerapan di Sistem"
Add-Bullet "Tampilan langsung yang dihadapi pengguna di perangkat fisik ponsel." "Hubungan Komponen"
Add-Bullet "Bagaimana Anda menjamin konsistensi tata letak visual di berbagai ukuran layar Android?" "Pertanyaan Sidang"
Add-Bullet "Kami menggunakan widget layout bawaan Flutter seperti LayoutBuilder, MediaQuery untuk dimensi proporsional, serta widget fleksibel seperti ListView, Grid, dan Sliver agar konten dapat mengalir menyesuaikan ukuran layar tanpa terjadi error overflow." "Jawaban Ideal"
Add-Bullet "Wajib Dikuasai" "Prioritas"

# K. Persiapan Sidang: Risiko Kompetensi
Add-Heading "K. Persiapan Sidang: Risiko Kompetensi" 1
Add-Body "Tabel pemetaan materi krusial beserta risiko kegagalan sidang jika tidak dikuasai:"

$table = $doc.Tables.Add($selection.Range, 6, 3)
$table.Style = "Table Grid"

$headers = @("Materi", "Tingkat Penguasaan", "Risiko Jika Tidak Menguasai")
for ($c = 1; $c -le 3; $c++) {
    $cell = $table.Cell(1, $c)
    $cell.Shading.BackgroundPatternColor = 7214859 # Deep Purple #4B176E
    $cell.Range.Text = $headers[$c-1]
    $cell.Range.Font.Bold = $true
    $cell.Range.Font.ColorIndex = 9 # White
    $cell.Range.Paragraphs.Item(1).Format.Alignment = 1
}

$rdata = @(
    @("Row Level Security (RLS) Supabase", "Sangat Tinggi (Wajib)", "Aplikasi dicap tidak aman karena peretas bisa mencuri/mengubah data user lain lewat endpoint API."),
    @("PostGIS (GiST Indexing Spasial)", "Sangat Tinggi (Wajib)", "Anda gagal menjelaskan metode pencarian radius terdekat dan dituduh melakukan plagiat template kode."),
    @("Database Triggers & Integritas Status", "Tinggi (Sangat Disarankan)", "Sistem dianggap rentan terhadap manipulasi transaksi ilegal karena validasi status hanya diletakkan di sisi client."),
    @("Riverpod State Management", "Tinggi (Sangat Disarankan)", "Gagal menjelaskan alur pemindahan data asinkron dari API ke widget UI, dinilai kurang paham konsep OOP/reaktif."),
    @("Metodologi UAT & Skala Likert", "Tinggi (Wajib)", "Hasil presentasi pengujian dianggap fiktif / karangan karena tidak bisa menjelaskan dasar kalkulasi statistiknya.")
)

for ($r = 2; $r -le 6; $r++) {
    for ($c = 1; $c -le 3; $c++) {
        $cell = $table.Cell($r, $c)
        $cell.Range.Text = $rdata[$r-2][$c-1]
    }
}

$selection.EndOf(6)
$selection.TypeParagraph()

# L. Ringkasan Akhir
Add-Heading "L. Ringkasan Akhir & Roadmap Belajar" 1

Add-Heading "1. 10 Pertanyaan Menjebak yang Sering Muncul" 2
$menjebak = @(
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
)
foreach ($q in $menjebak) {
    $selection.TypeText("- " + $q)
    $selection.TypeParagraph()
}

Add-Heading "2. Roadmap Belajar Menuju Hari-H Sidang" 2
Add-Body "Minggu 1: Fokus penguasaan database relasional, query SQL, manipulasi PostGIS, dan aturan RLS (12 Jam Belajar)."
Add-Body "Minggu 2: Pelajari arsitektur Flutter (Clean Architecture), Dependency Injection, dan alur State Riverpod (12 Jam Belajar)."
Add-Body "Minggu 3: Kuasai alur pengiriman push notification FCM, konfigurasi Edge Functions, dan trigger status DB (14 Jam Belajar)."
Add-Body "Minggu 4: Review dokumen bab 4-5, kuasai kalkulasi data UAT, dan simulasi tanya jawab mental sidang (10 Jam Belajar)."

Write-Host "Menyimpan file Word ke: $docxPath"
$doc.SaveAs([ref]$docxPath)
$doc.Close()
$word.Quit()

Write-Host "File Word sukses dibuat!"
