import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:educonnect/core/presentation/providers/locale_provider.dart';

final translationsProvider = Provider<AppTranslations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppTranslations(locale.languageCode);
});

class AppTranslations {
  AppTranslations(this.langCode);

  final String langCode;

  bool get isIndonesian => langCode == 'id';

  // Common UI Texts
  String get settings => isIndonesian ? 'Pengaturan' : 'Settings';
  String get profile => isIndonesian ? 'Profil' : 'Profile';
  String get editProfile => isIndonesian ? 'Ubah Profil' : 'Edit Profile';
  String get viewProfile => isIndonesian ? 'Detail Profil' : 'Profile Details';
  String get saveChanges => isIndonesian ? 'Simpan Perubahan' : 'Save Changes';
  String get saving => isIndonesian ? 'Menyimpan...' : 'Saving...';
  String get cancel => isIndonesian ? 'Batal' : 'Cancel';
  String get save => isIndonesian ? 'Simpan' : 'Save';
  String get edit => isIndonesian ? 'Ubah' : 'Edit';
  String get logout => isIndonesian ? 'Keluar' : 'Log Out';
  String get logoutConfirm => isIndonesian ? 'Apakah Anda yakin ingin keluar?' : 'Are you sure you want to log out?';
  String get logoutSub => isIndonesian ? 'Akhiri sesi akun Anda dengan aman.' : 'End your account session securely.';
  String get back => isIndonesian ? 'Kembali' : 'Back';
  String get success => isIndonesian ? 'Berhasil' : 'Success';
  String get failed => isIndonesian ? 'Gagal' : 'Failed';

  // Profile Page Texts
  String get generalSettings => isIndonesian ? 'Pengaturan Umum' : 'General Settings';
  String get otherSettings => isIndonesian ? 'Lainnya' : 'Others';
  String get editProfileSub => isIndonesian ? 'Ubah nama dan foto profil Anda' : 'Change your name and profile picture';
  String get learningJournal => isIndonesian ? 'Jurnal Belajar' : 'Learning Journal';
  String get learningJournalSub => isIndonesian ? 'Lihat progres belajar, materi, dan PR' : 'View study progress, materials, and homework';
  String get paymentHistory => isIndonesian ? 'Riwayat Pembayaran' : 'Payment History';
  String get paymentHistorySub => isIndonesian ? 'Lihat riwayat dan unduh invoice les' : 'View history and download lesson invoices';
  String get learningPref => isIndonesian ? 'Preferensi Belajar' : 'Learning Preferences';
  String get learningPrefSub => isIndonesian ? 'Atur mata pelajaran & batas budget les' : 'Set subjects & lesson budget limits';
  String get logoutSubtext => isIndonesian ? 'Akhiri sesi akun dengan aman' : 'Securely end your account session';

  // Settings Screen Sections
  String get themeSetting => isIndonesian ? 'Tema Aplikasi' : 'App Theme';
  String get themeSettingSub => isIndonesian ? 'Ubah tampilan antarmuka aplikasi' : 'Change application interface style';
  String get themeLight => isIndonesian ? 'Terang' : 'Light';
  String get themeDark => isIndonesian ? 'Gelap' : 'Dark';
  String get themeSystem => isIndonesian ? 'Sistem' : 'System';

  String get languageSetting => isIndonesian ? 'Bahasa' : 'Language';
  String get languageSettingSub => isIndonesian ? 'Pilih bahasa antarmuka' : 'Choose interface language';
  String get selectLanguage => isIndonesian ? 'Pilih Bahasa' : 'Select Language';

  String get notificationSetting => isIndonesian ? 'Notifikasi' : 'Notifications';
  String get notificationSettingSub => isIndonesian ? 'Atur jenis notifikasi yang diterima' : 'Manage types of notifications received';
  String get notifVirtualClass => isIndonesian ? 'Notifikasi Kelas Virtual' : 'Virtual Classroom Alerts';
  String get notifVirtualClassSub => isIndonesian ? 'Dering panggilan melayang sesi online' : 'Ringing overlays for online sessions';
  String get notifChat => isIndonesian ? 'Pemberitahuan Chat' : 'Chat Messaging Notifications';
  String get notifChatSub => isIndonesian ? 'Pemberitahuan pesan masuk instan' : 'Alerts for instant incoming messages';
  String get notifTransaction => isIndonesian ? 'Notifikasi Pembayaran' : 'Booking & Payment Updates';
  String get notifTransactionSub => isIndonesian ? 'Pembaruan invoice dan jadwal les' : 'Updates on invoices and lesson schedules';

  String get securitySetting => isIndonesian ? 'Keamanan Akun' : 'Account Security';
  String get securitySettingSub => isIndonesian ? 'Atur kata sandi dan hapus akun' : 'Manage password and delete account';
  String get changePassword => isIndonesian ? 'Ganti Kata Sandi' : 'Change Password';
  String get deleteAccount => isIndonesian ? 'Hapus Akun Permanen' : 'Delete Account Permanently';
  String get deleteAccountConfirm => isIndonesian ? 'Apakah Anda yakin ingin menghapus akun Anda secara permanen?' : 'Are you sure you want to permanently delete your account?';
  String get deleteAccountSubtext => isIndonesian ? 'Tindakan ini tidak dapat dibatalkan. Seluruh data Anda akan dihapus dari server kami.' : 'This action is irreversible. All of your data will be permanently wiped from our servers.';
  String get deleteAccountVerif => isIndonesian ? 'Ketik "HAPUS" untuk mengonfirmasi' : 'Type "DELETE" to confirm';
  String get deleteAccountHint => isIndonesian ? 'Ketik disini...' : 'Type here...';
  String get deleteAccountSuccess => isIndonesian ? 'Akun Anda berhasil dihapus.' : 'Your account was successfully deleted.';
  String get changePasswordSuccess => isIndonesian ? 'Kata sandi berhasil diperbarui.' : 'Password successfully updated.';
  String get oldPassword => isIndonesian ? 'Kata Sandi Lama' : 'Old Password';
  String get newPassword => isIndonesian ? 'Kata Sandi Baru' : 'New Password';
  String get confirmNewPassword => isIndonesian ? 'Konfirmasi Kata Sandi Baru' : 'Confirm New Password';
  String get newPasswordNotMatch => isIndonesian ? 'Konfirmasi kata sandi tidak cocok.' : 'Confirm password does not match.';
  String get passwordTooShort => isIndonesian ? 'Kata sandi terlalu pendek (minimal 6 karakter).' : 'Password too short (min 6 characters).';

  String get cacheSetting => isIndonesian ? 'Penyimpanan & Cache' : 'Storage & Cache';
  String get cacheSettingSub => isIndonesian ? 'Bersihkan berkas sampah aplikasi' : 'Clear application junk files';
  String get clearCache => isIndonesian ? 'Hapus Cache Aplikasi' : 'Clear App Cache';
  String get cacheSize => isIndonesian ? 'Ukuran Cache Terdeteksi' : 'Detected Cache Size';
  String get clearCacheConfirm => isIndonesian ? 'Hapus Berkas Sementara?' : 'Clear Temporary Files?';
  String get clearCacheSub => isIndonesian ? 'Ini akan menghapus catatan whiteboard yang di-cache dan gambar profil sementara. Data utama Anda tetap aman.' : 'This will remove cached whiteboard notes and temporary profile images. Your core data remains safe.';
  String get clearCacheSuccess => isIndonesian ? 'Cache aplikasi berhasil dibersihkan!' : 'App cache successfully cleared!';

  String get faqSetting => isIndonesian ? 'Tanya Jawab (FAQ)' : 'Frequently Asked Questions (FAQ)';
  String get faqSettingSub => isIndonesian ? 'Pertanyaan yang sering ditanyakan' : 'Frequently asked questions';
  
  String get supportSetting => isIndonesian ? 'Hubungi Dukungan' : 'Help & Support';
  String get supportSettingSub => isIndonesian ? 'Hubungi tim bantuan kami' : 'Contact our support team';
  
  String get aboutApp => isIndonesian ? 'Tentang Aplikasi' : 'About App';
  String get appVersion => isIndonesian ? 'Versi Aplikasi v1.0.0+1' : 'App Version v1.0.0+1';

  // Read-Only Profile Page
  String get fullName => isIndonesian ? 'Nama Lengkap' : 'Full Name';
  String get emailAddress => isIndonesian ? 'Alamat Email' : 'Email Address';
  String get schoolLevel => isIndonesian ? 'Tingkat Sekolah' : 'School Level';
  String get appRole => isIndonesian ? 'Peran Pengguna' : 'User Role';
  String get appRoleStudent => isIndonesian ? 'Murid (Student)' : 'Student';
  String get appRoleTutor => isIndonesian ? 'Tutor (Pengajar)' : 'Tutor';
  String get updateProfileSuccess => isIndonesian ? 'Profil Anda berhasil diperbarui.' : 'Your profile has been successfully updated.';
  String get editProfileTooltip => isIndonesian ? 'Ubah Profil' : 'Edit Profile';
  String get enterFullName => isIndonesian ? 'Masukkan nama lengkap Anda' : 'Enter your full name';
  String get selectSchoolLevel => isIndonesian ? 'Pilih tingkat sekolah Anda' : 'Select your school level';
  String get chooseFromSD => isIndonesian ? 'SD (Sekolah Dasar)' : 'Elementary School (SD)';
  String get chooseFromSMP => isIndonesian ? 'SMP (Sekolah Menengah Pertama)' : 'Junior High School (SMP)';
  String get chooseFromSMA => isIndonesian ? 'SMA (Sekolah Menengah Atas)' : 'Senior High School (SMA)';

  // FAQ List
  List<Map<String, String>> get faqList => isIndonesian
      ? [
          {
            'q': 'Bagaimana cara memulai sesi belajar online (Kelas Virtual)?',
            'a': 'Tutor akan memulai kelas dengan menekan tombol "Mulai Sesi" pada jadwal les. Murid akan menerima dering panggilan melayang secara real-time di layar mereka. Tekan "Terima" untuk masuk langsung ke ruang kelas virtual dan mengaktifkan papan tulis kolaboratif.'
          },
          {
            'q': 'Bagaimana cara kerja Papan Tulis Kolaboratif (Whiteboard)?',
            'a': 'Whiteboard menyinkronkan goresan kuas, warna, ketebalan pena, dan tombol hapus/undo secara real-time antara tutor dan murid menggunakan jaringan Supabase Broadcast. Anda juga dapat menekan "Ekspor PDF" untuk mengunduh seluruh coretan papan tulis beserta ringkasan materi pelajaran langsung ke penyimpanan lokal.'
          },
          {
            'q': 'Apa itu fitur GPS Geofencing Verifikasi Lokasi?',
            'a': 'Untuk sesi les offline (tatap muka), aplikasi mengukur koordinat GPS tutor dan murid menggunakan layanan lokasi ponsel. Kehadiran fisik akan diverifikasi secara otomatis apabila jarak perangkat di bawah 100 meter dari lokasi target les. Tersedia juga Mode Demo demi kemudahan pengetesan.'
          },
          {
            'q': 'Bagaimana cara mengirimkan dan mengoreksi PR?',
            'a': 'Murid dapat melampirkan foto PR (melalui Galeri atau Kamera) di menu Jurnal Belajar. Tutor dapat melihat foto PR tersebut dan menekan tombol "Koreksi Gambar" untuk mencoret-coret visual, menandai bagian yang salah, memberikan nilai, dan menyimpannya kembali agar murid dapat melihat hasilnya secara instan.'
          },
          {
            'q': 'Apakah aplikasi ini membebankan memori ponsel?',
            'a': 'File coretan kelas dan lampiran PR disimpan di penyimpanan sementara. Anda dapat membebaskan memori ponsel kapan saja secara aman dengan menekan menu "Hapus Cache Aplikasi" di halaman Pengaturan ini.'
          }
        ]
      : [
          {
            'q': 'How do I start an online learning session (Virtual Classroom)?',
            'a': 'Tutors initiate the session by tapping "Start Session" in their bookings panel. Students instantly receive a ringing call overlay. Tapping "Accept" redirects the student directly to the virtual classroom with dynamic whiteboard drawing sync.'
          },
          {
            'q': 'How does the Collaborative Whiteboard drawing sync work?',
            'a': 'The interactive whiteboard coordinates, brush colors, widths, clear, and undo commands are synced instantly using direct client-to-client Supabase Broadcast channels. Tapping "Export PDF" compiles the whiteboard drawing alongside study metadata to a landscape PDF in local storage.'
          },
          {
            'q': 'What is the GPS Geofencing Location Verification feature?',
            'a': 'For offline (face-to-face) bookings, the app accesses both tutor and student GPS coordinates. Physical presence is automatically verified only if devices are within a 100-meter radius of the designated tutoring address. Developer Demo Mode is available for remote testing.'
          },
          {
            'q': 'How do I submit and correct homework assignments?',
            'a': 'Students can upload homework photos (via Gallery or Camera) from the Learning Journal. Tutors can view the image, click "Correct Image", draw annotations (like red circles or ticks) on top of the student\'s submission, and save it for side-by-side rendering.'
          },
          {
            'q': 'Does this app consume significant local phone storage?',
            'a': 'Temporary whiteboard sheets and homework attachments occupy cache directories over time. Tapping "Clear App Cache" under Settings instantly clears accumulated temporary files safely without losing core user data.'
          }
        ];
}
