# REKOMENDASI KODE PROGRAM UNTUK DITULIS DI SKRIPSI
## Dokumen Panduan Potongan Kode Utama (Flutter & PostgreSQL)

Dalam penulisan skripsi teknik/komputer (terutama pada **BAB IV bagian Implementasi Kode**), sangat disarankan untuk menyertakan potongan kode (*code snippets*) kunci yang merepresentasikan solusi dari masalah utama sistem. 

Berikut adalah 3 potongan kode utama dari proyek **EduConnect** yang sangat berharga untuk dicantumkan di skripsi Anda beserta analisis akademisnya.

---

### 1. SISTEM PROTEKSI ROUTING & ROLE-BASED GUARDS (FLUTTER)
*   **Lokasi File**: `lib/app/routes/app_router.dart`
*   **Fokus Bahasan Skripsi**: Aspek keamanan navigasi klien dan pembagian hak akses halaman berdasarkan *role* pengguna (`student` atau `tutor`) menggunakan framework `go_router`.

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshNotifier = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    initialLocation: AuthPage.routePath,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final user = authRepository.currentUser;

      final isAuthRoute = location == AuthPage.routePath;
      final isRoleRoute = location == RoleOnboardingPage.routePath;
      final isStudentRoute = location.startsWith('/student');
      final isTutorRoute = location.startsWith('/tutor');

      // 1. Jika user belum login, paksa ke halaman Autentikasi
      if (user == null) {
        return isAuthRoute ? null : AuthPage.routePath;
      }

      final profileAsync = ref.read(currentUserProfileProvider);
      
      // Jika profil sedang loading, tahan di halaman saat ini
      if (profileAsync.isLoading) {
        return null;
      }

      final profile = profileAsync.valueOrNull;
      final role = profile?.role ?? AppUserRole.unknown;
      
      // 2. Jika role belum ditentukan, paksa masuk ke halaman pemilihan role
      if (role == AppUserRole.unknown) {
        return isRoleRoute ? null : RoleOnboardingPage.routePath;
      }

      // 3. Proteksi Akses: Murid tidak boleh mengakses halaman Tutor
      if (role == AppUserRole.student) {
        if (isTutorRoute || isAuthRoute || isRoleRoute) {
          return StudentHomePage.routePath;
        }
        return null;
      }

      // 4. Proteksi Akses: Tutor tidak boleh mengakses halaman Murid
      if (role == AppUserRole.tutor) {
        if (isStudentRoute || isAuthRoute || isRoleRoute) {
          return TutorHomePage.routePath;
        }
        return null;
      }

      return AuthPage.routePath;
    },
    routes: [
      // ... Konfigurasi ShellRoute Murid dan Tutor ...
    ]
  );
});
```

*   **Analisis Deskriptif Skripsi**:
    > "Potongan kode di atas menunjukkan implementasi dari fungsi `redirect` pada `GoRouter` yang bertindak sebagai *middleware* atau *route guard*. Fungsi ini membaca kondisi autentikasi aktif dari `authRepository` serta profil peran dari `currentUserProfileProvider`. Keamanannya terbagi menjadi tiga lapis: perlindungan tamu (belum masuk), pengalihan pengguna tanpa peran ke halaman *onboarding*, dan pemisahan navigasi secara ketat antara ruang kerja murid (`/student`) dan tutor (`/tutor`). Hal ini menjamin pengguna tidak dapat mengakses antarmuka yang bukan haknya hanya dengan memanipulasi tautan navigasi."

---

### 2. TRIGGER VALIDASI LIFECYCLE SESI DI DATABASE (POSTGRESQL / SQL)
*   **Bahasan Skripsi**: Aspek integritas data dan keamanan transaksi backend. Menjelaskan bagaimana database menolak perubahan status ilegal demi keaslian data meskipun ada *bypass* dari client.
*   **Konsep Kode**: Trigger function PostgreSQL yang mengecek transisi status sesi secara ketat.

```sql
CREATE OR REPLACE FUNCTION validate_session_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- Mencegah perubahan jika status baru sama dengan status lama
    IF OLD.status = NEW.status THEN
        RETURN NEW;
    END IF;

    -- Aturan 1: Sesi hanya bisa dimulai (in_progress) jika berstatus scheduled
    IF NEW.status = 'in_progress' AND OLD.status != 'scheduled' THEN
        RAISE EXCEPTION 'Sesi tidak dapat dimulai karena status saat ini bukan scheduled';
    END IF;

    -- Aturan 2: Sesi hanya bisa diselesaikan (done_pending_confirmation) oleh tutor jika berstatus in_progress
    IF NEW.status = 'done_pending_confirmation' AND OLD.status != 'in_progress' THEN
        RAISE EXCEPTION 'Sesi tidak dapat diselesaikan karena sesi belum berjalan (in_progress)';
    END IF;

    -- Aturan 3: Hanya murid yang boleh mengubah done_pending_confirmation menjadi confirmed
    IF NEW.status = 'confirmed' AND OLD.status != 'done_pending_confirmation' THEN
        RAISE EXCEPTION 'Konfirmasi penyelesaian sesi hanya dapat dilakukan setelah sesi ditandai selesai oleh tutor';
    END IF;

    -- Aturan 4: Jika status confirmed, catat waktu konfirmasi kehadiran otomatis
    IF NEW.status = 'confirmed' THEN
        NEW.student_presence_confirmed_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Menerapkan trigger pada tabel booking_sessions
CREATE TRIGGER trigger_validate_session_status
BEFORE UPDATE ON public.booking_sessions
FOR EACH ROW
EXECUTE FUNCTION validate_session_status_transition();
```

*   **Analisis Deskriptif Skripsi**:
    > "Untuk menjaga integritas siklus belajar, sistem menerapkan *business rules* di sisi database menggunakan PostgreSQL Trigger. Prosedur `validate_session_status_transition()` akan dieksekusi sebelum ada aksi penyuntingan (`BEFORE UPDATE`) pada tabel `booking_sessions`. Prosedur ini mengontrol secara mutlak bahwa perubahan status sesi (seperti `scheduled` -> `in_progress` -> `done_pending_confirmation` -> `confirmed`) berjalan linear dan sah secara logika. Upaya perubahan status di luar alur resmi akan dibatalkan langsung oleh database server melalui pernyataan `RAISE EXCEPTION`."

---

### 3. AUTOMATIC NOTIFICATION GENERATION VIA TRIGGER REPLICATION (SQL)
*   **Bahasan Skripsi**: Implementasi asinkronus dan otomatisasi sistem notifikasi in-app ketika ada aktivitas chat baru.
*   **Konsep Kode**: Trigger penulisan otomatis dari tabel pesan ke tabel notifikasi.

```sql
CREATE OR REPLACE FUNCTION notify_chat_message_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Masukkan rekaman notifikasi secara otomatis ke tabel app_notifications
    INSERT INTO public.app_notifications (
        user_uid,       -- Penerima notifikasi (lawan bicara)
        actor_uid,      -- Pelaku (pengirim pesan)
        category,       -- Kategori notifikasi
        target_type,    -- Jenis target (chat)
        target_id,      -- ID target referensi (booking_id)
        is_read         -- Status baca default
    ) VALUES (
        NEW.receiver_uid,
        NEW.sender_uid,
        'chat_message',
        'booking',
        NEW.booking_id::text,
        FALSE
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Menerapkan trigger pada tabel messages
CREATE TRIGGER trigger_notify_chat_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION notify_chat_message_insert();
```

*   **Analisis Deskriptif Skripsi**:
    > "Sistem notifikasi pesan chat EduConnect dirancang secara reaktif memanfaatkan pemicu basis data (`AFTER INSERT TRIGGER`). Begitu pesan chat baru tersimpan ke dalam tabel `messages`, sistem secara otomatis menginisiasi pembuatan data notifikasi pada tabel `app_notifications` untuk penerima pesan. Pendekatan ini memindahkan beban proses pembentukan notifikasi dari aplikasi Flutter ke PostgreSQL, sehingga menghemat daya komputasi perangkat mobile pengguna dan memastikan pengiriman notifikasi berlangsung secara konsisten."

---

### PANDUAN PENULISAN DI SKRIPSI Anda:
1.  **Format Penulisan**: Sajikan potongan kode di atas dalam blok kode ber-monospaced (font Consolas / Courier New ukuran 9-10 pt) dengan spasi 1.0 agar rapi.
2.  **Keterangan Gambar/Kode**: Berikan penomoran resmi di atas atau bawah kode, contoh: **Kode 4.1 Logika Perutean Berbasis Peran** atau **Gambar 4.2 Prosedur Validasi Status Sesi**.
3.  **Hubungkan dengan Uji Coba**: Tautkan kode ini ke hasil pengujian Black Box & Negative Testing. Misal: *Trigger pada Kode 4.2 telah teruji keandalannya pada Pengujian Negatif Kasus Uji 2 (Tabel 4.2) yang menolak aksi manipulasi status.*
