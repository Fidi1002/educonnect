import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'dart:io';

import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/domain/models/tutor_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TutorProfileFormPage extends ConsumerStatefulWidget {
  const TutorProfileFormPage({super.key});

  static const routeName = 'tutor-profile-form';
  static const routePath = '/tutor/profile/edit';

  @override
  ConsumerState<TutorProfileFormPage> createState() =>
      _TutorProfileFormPageState();
}

class _TutorProfileFormPageState extends ConsumerState<TutorProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _experienceDescriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxStudentCapacityController = TextEditingController();

  final _ktpNameController = TextEditingController();
  final _nikController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthDateController = TextEditingController();

  // New Controllers for Redesign
  final _bankNameController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _introVideoUrlController = TextEditingController();

  // Stepper State
  int _currentStep = 0;
  final int _totalSteps = 4;

  final List<String> _subjects = <String>[];
  final List<String> _teachingLevels = <String>[];
  final List<String> _languages = <String>[];
  
  bool _isInitialized = false;
  String _photoUrl = '';
  File? _selectedImage;
  double? _latitude;
  double? _longitude;
  String _geohash = '';

  String _verificationStatus = 'none';
  String? _identityCardUrl;
  String? _certificateUrl;
  String? _rejectionReason;

  File? _selectedKtpFile;
  File? _selectedCertificateFile;

  DateTime? _birthDate;
  List<Map<String, dynamic>> _experienceCv = [];

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _priceController.dispose();
    _experienceYearsController.dispose();
    _experienceDescriptionController.dispose();
    _locationController.dispose();
    _maxStudentCapacityController.dispose();
    _ktpNameController.dispose();
    _nikController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _introVideoUrlController.dispose();
    super.dispose();
  }

  double _calculateCompletenessScore() {
    double score = 100.0;
    
    // Validasi 1: Dokumen Dasar
    if (_selectedKtpFile == null && (_identityCardUrl == null || _identityCardUrl!.isEmpty)) {
      score -= 40.0;
    }
    if (_selectedCertificateFile == null && (_certificateUrl == null || _certificateUrl!.isEmpty)) {
      score -= 30.0;
    }

    // Validasi 2: NIK
    final nikVal = _nikController.text.trim();
    if (nikVal.isEmpty) {
      score -= 30.0;
    } else if (nikVal.length != 16) {
      score -= 20.0;
    }

    // Validasi 3: Nama KTP
    final ktpNameVal = _ktpNameController.text.trim();
    final nameVal = _nameController.text.trim();
    if (ktpNameVal.isEmpty) {
      score -= 15.0;
    } else if (ktpNameVal.toLowerCase() != nameVal.toLowerCase()) {
      score -= 5.0;
    }

    // Validasi 4: Tempat & Tanggal Lahir
    if (_birthPlaceController.text.trim().isEmpty) {
      score -= 10.0;
    }
    if (_birthDate == null) {
      score -= 15.0;
    } else {
      final age = DateTime.now().year - _birthDate!.year;
      if (age < 18) {
        score -= 30.0;
      }
    }

    // Validasi 5: CV
    if (_experienceCv.isEmpty) {
      score -= 15.0;
    }

    return score < 0 ? 0 : score;
  }

  void _syncInitialData(
    TutorProfile? profile,
    String fallbackName,
    String fallbackPhoto,
  ) {
    if (_isInitialized) {
      return;
    }

    final existing = profile ?? TutorProfile.empty('');
    _nameController.text = existing.displayName.isNotEmpty
        ? existing.displayName
        : fallbackName;
    _bioController.text = existing.bio;
    _subjects
      ..clear()
      ..addAll(existing.subjects);
    _priceController.text = existing.pricePerHour > 0
        ? existing.pricePerHour.toString()
        : '';
    _experienceYearsController.text = existing.experienceYears > 0
        ? existing.experienceYears.toString()
        : '';
    _experienceDescriptionController.text = existing.experienceDescription;
    _locationController.text = existing.locationLabel;
    _photoUrl = existing.photoUrl.isNotEmpty
        ? existing.photoUrl
        : fallbackPhoto;
    _latitude = existing.latitude;
    _longitude = existing.longitude;
    _geohash = existing.geohash;
    _maxStudentCapacityController.text = existing.maxStudentCapacity.toString();

    _verificationStatus = existing.verificationStatus;
    _identityCardUrl = existing.identityCardUrl;
    _certificateUrl = existing.certificateUrl;
    _rejectionReason = existing.rejectionReason;

    _ktpNameController.text = existing.ktpName ?? '';
    _nikController.text = existing.nik ?? '';
    _birthPlaceController.text = existing.birthPlace ?? '';
    _birthDate = existing.birthDate;
    if (_birthDate != null) {
      _birthDateController.text =
          "${_birthDate!.day.toString().padLeft(2, '0')}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.year}";
    } else {
      _birthDateController.text = '';
    }
    _experienceCv = existing.experienceCv != null
        ? List<Map<String, dynamic>>.from(existing.experienceCv!)
        : [];
    _teachingLevels
      ..clear()
      ..addAll(existing.teachingLevels);

    // Sync new fields
    _bankNameController.text = existing.bankName ?? '';
    _bankAccountNumberController.text = existing.bankAccountNumber ?? '';
    _introVideoUrlController.text = existing.introductionVideoUrl ?? '';
    _languages
      ..clear()
      ..addAll(existing.languages.isEmpty ? ['Bahasa Indonesia'] : existing.languages);

    _isInitialized = true;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedImage = File(picked.path);
    });
  }

  Future<void> _pickKtp() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _selectedKtpFile = File(picked.path);
    });
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      _selectedCertificateFile = File(picked.path);
    });
  }

  void _showAddExperienceDialog() {
    final instansiCtrl = TextEditingController();
    final peranCtrl = TextEditingController();
    final periodeCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
          title: Text(
            'Tambah Pengalaman CV',
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF191622)),
          ),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: instansiCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Institusi / Instansi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: peranCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Peran / Posisi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: periodeCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Periode (misal: 2022 - 2024)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: deskripsiCtrl,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi Singkat',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (dialogFormKey.currentState?.validate() ?? false) {
                  setState(() {
                    _experienceCv.add({
                      'institution': instansiCtrl.text.trim(),
                      'role': peranCtrl.text.trim(),
                      'period': periodeCtrl.text.trim(),
                      'description': deskripsiCtrl.text.trim(),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _showMapPickerDialog() {
    double initialLat = _latitude ?? -6.2000;
    double initialLng = _longitude ?? 106.8166;
    LatLng selectedPosition = LatLng(initialLat, initialLng);
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('selected_tutor_loc'),
        position: selectedPosition,
        draggable: true,
      )
    };

    showDialog<void>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
          title: Text(
            'Geser Marker ke Lokasi Mengajar',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: selectedPosition,
                  zoom: 14,
                ),
                markers: markers,
                onTap: (LatLng tapped) {
                  selectedPosition = tapped;
                  (context as Element).markNeedsBuild();
                },
                onCameraMove: (CameraPosition position) {
                  selectedPosition = position.target;
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _latitude = selectedPosition.latitude;
                  _longitude = selectedPosition.longitude;
                  _locationController.text = 'Lokasi disematkan di Peta';
                });
                Navigator.pop(context);
              },
              child: const Text('Pilih Lokasi Ini'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSavePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_subjects.isEmpty) {
      _showMessage('Minimal pilih 1 mata pelajaran.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showMessage('Lokasi tutor wajib diisi untuk fitur pencarian terdekat.');
      return;
    }

    final user = ref.read(authStateProvider).value;
    if (user == null) {
      _showMessage('User belum login.');
      return;
    }

    try {
      final controller = ref.read(tutorProfileControllerProvider);
      final existing = ref.read(myTutorProfileProvider).valueOrNull;
      var photoUrl = _photoUrl;
      if (_selectedImage != null) {
        photoUrl = await controller.uploadPhoto(_selectedImage!);
      }

      var identityCardUrl = _identityCardUrl;
      var certificateUrl = _certificateUrl;
      var verificationStatus = _verificationStatus;

      if (_selectedKtpFile != null) {
        identityCardUrl = await controller.uploadDocument(_selectedKtpFile!, 'ktp');
        verificationStatus = 'pending';
      }
      if (_selectedCertificateFile != null) {
        certificateUrl = await controller.uploadDocument(_selectedCertificateFile!, 'certificate');
        verificationStatus = 'pending';
      }

      if (verificationStatus == 'none' && (identityCardUrl != null || certificateUrl != null)) {
        verificationStatus = 'pending';
      }

      final completenessScore = _calculateCompletenessScore();
      if (completenessScore >= 85) {
        verificationStatus = 'approved';
      }

      final profile = TutorProfile(
        uid: user.uid,
        displayName: _nameController.text.trim(),
        photoUrl: photoUrl,
        bio: _bioController.text.trim(),
        subjects: _subjects,
        pricePerHour: num.parse(_priceController.text.trim()),
        experienceYears: int.parse(_experienceYearsController.text.trim()),
        experienceDescription: _experienceDescriptionController.text.trim(),
        locationLabel: _locationController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        geohash: existing?.geohash ?? _geohash,
        rating: existing?.rating ?? 0,
        totalReviews: existing?.totalReviews ?? 0,
        consistencyScore: existing?.consistencyScore ?? 0,
        isActive: verificationStatus == 'approved',
        verificationStatus: verificationStatus,
        identityCardUrl: identityCardUrl,
        certificateUrl: certificateUrl,
        rejectionReason: verificationStatus == 'rejected' ? _rejectionReason : null,
        maxStudentCapacity: int.tryParse(_maxStudentCapacityController.text.trim()) ?? 2,
        ktpName: _ktpNameController.text.trim().isEmpty ? null : _ktpNameController.text.trim(),
        nik: _nikController.text.trim().isEmpty ? null : _nikController.text.trim(),
        birthPlace: _birthPlaceController.text.trim().isEmpty ? null : _birthPlaceController.text.trim(),
        birthDate: _birthDate,
        experienceCv: _experienceCv,
        teachingLevels: _teachingLevels,
        bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim().isEmpty ? null : _bankAccountNumberController.text.trim(),
        languages: _languages.isEmpty ? ['Bahasa Indonesia'] : _languages,
        introductionVideoUrl: _introVideoUrlController.text.trim().isEmpty ? null : _introVideoUrlController.text.trim(),
      );

      await controller.saveProfile(profile);
      if (!mounted) {
        return;
      }
      _showMessage('Profil tutor berhasil disimpan.');
    } on Exception catch (error) {
      _showMessage(_friendlyErrorMessage(error));
    }
  }

  Future<void> _onUseCurrentLocationPressed() async {
    try {
      final position = await ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      if (!mounted) {
        return;
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text = 'Lokasi terdeteksi GPS';
      });
      _showMessage('Lokasi berhasil diambil dari GPS.');
    } on Exception catch (error) {
      _showMessage(
        'Gagal mengambil lokasi. Pastikan izin lokasi aktif lalu coba lagi. ${error.toString()}',
      );
    }
  }

  Future<void> _onDeactivatePressed() async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131926) : Colors.white,
          title: Text('Nonaktifkan Profil?', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          content: Text(
            'Profil tutor akan disembunyikan dari daftar pencarian murid.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nonaktifkan'),
            ),
          ],
        );
      },
    );

    if (confirmation != true) {
      return;
    }

    try {
      await ref.read(tutorProfileControllerProvider).deactivateMyProfile();
      _showMessage('Profil tutor berhasil dinonaktifkan dari pencarian.');
    } on Exception catch (error) {
      _showMessage(
        'Gagal menonaktifkan profil. Coba lagi beberapa saat lagi. ${error.toString()}',
      );
    }
  }

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('network') || raw.contains('socket')) {
      return 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
    }
    if (raw.contains('storage') || raw.contains('bucket')) {
      return 'Upload berkas gagal. Pastikan file valid lalu coba lagi.';
    }
    if (raw.contains('permission') || raw.contains('not allowed')) {
      return 'Akses ditolak oleh server. Cek policy Supabase untuk profil tutor.';
    }
    return 'Gagal menyimpan profil tutor. Coba lagi sebentar lagi. ${error.toString()}';
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildStepIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isActive = index == _currentStep;
          Color indicatorColor = isDark ? const Color(0xFF1B2336) : const Color(0xFFF1F5F9);
          if (isCompleted || isActive) {
            indicatorColor = const Color(0xFF4B176E);
          }
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: indicatorColor,
                  child: isCompleted
                      ? const Icon(FluentIcons.checkmark_12_filled, color: Colors.white, size: 14)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCompleted || isActive ? Colors.white : Colors.grey,
                          ),
                        ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompleted
                              ? [const Color(0xFF4B176E), const Color(0xFF4B176E)]
                              : isActive
                                  ? [const Color(0xFF4B176E), isDark ? const Color(0xFF1B2336) : const Color(0xFFF1F5F9)]
                                  : [isDark ? const Color(0xFF1B2336) : const Color(0xFFF1F5F9), isDark ? const Color(0xFF1B2336) : const Color(0xFFF1F5F9)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompletenessScoreCard(bool isDark) {
    final score = _calculateCompletenessScore();
    Color scoreColor = const Color(0xFFDC2626);
    if (score >= 85) {
      scoreColor = const Color(0xFF16A34A);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimasi AI Trust Score',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : const Color(0xFF4B176E)),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: scoreColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: isDark ? const Color(0xFF131926) : const Color(0xFFF1F5F9),
              color: scoreColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score < 85
                ? '⚠️ Skor Anda ${score.toStringAsFixed(0)}%. Lengkapi profil & unggah dokumen legal untuk mencapai minimal 85%.'
                : '🎉 Lolos Kurasi AI! Akun Anda akan langsung aktif setelah profil disimpan.',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusBanner() {
    Color bannerColor;
    IconData icon;
    String title;
    String description;

    switch (_verificationStatus) {
      case 'approved':
        bannerColor = const Color(0xFF16A34A);
        icon = FluentIcons.checkmark_circle_24_regular;
        title = 'Terverifikasi Resmi';
        description = 'Profil Anda telah disetujui! Akun Anda kini aktif secara publik di peta geospasial & pencarian murid.';
        break;
      case 'rejected':
        bannerColor = const Color(0xFFDC2626);
        icon = FluentIcons.dismiss_circle_24_regular;
        title = 'Verifikasi Profil Ditolak';
        description = 'Alasan penolakan: "${_rejectionReason ?? 'Dokumen kurang lengkap'}"\nSilakan perbaiki dokumen di bawah ini.';
        break;
      case 'pending':
        bannerColor = const Color(0xFFD97706);
        icon = FluentIcons.clock_24_regular;
        title = 'Menunggu Verifikasi Admin';
        description = 'Profil Anda sedang diperiksa oleh tim kurasi admin. Profil disembunyikan sementara dari pencarian murid.';
        break;
      case 'none':
      default:
        bannerColor = const Color(0xFF4B176E);
        icon = FluentIcons.warning_24_regular;
        title = 'Kurasi Profil Wajib';
        description = 'Unggah dokumen identitas & bukti sertifikasi pengajar untuk mengajukan kurasi kelayakan sebelum akun dipublikasikan.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: bannerColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: bannerColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: bannerColor.withValues(alpha: 0.8), fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step, bool isDark) {
    switch (step) {
      case 0:
        return _buildStep0(isDark);
      case 1:
        return _buildStep1(isDark);
      case 2:
        return _buildStep2(isDark);
      case 3:
        return _buildStep3(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Profil Dasar & Keuangan
  Widget _buildStep0(bool isDark) {
    ImageProvider<Object>? avatarImage;
    if (_selectedImage != null) {
      avatarImage = FileImage(_selectedImage!);
    } else if (_photoUrl.isNotEmpty) {
      avatarImage = NetworkImage(_photoUrl);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: isDark ? const Color(0xFF1B2336) : const Color(0xFFEAF2FF),
                backgroundImage: avatarImage,
                child: (_selectedImage == null && _photoUrl.isEmpty)
                    ? Icon(
                        FluentIcons.person_24_regular,
                        size: 40,
                        color: isDark ? Colors.white54 : Colors.grey,
                      )
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF4B176E)),
                  onPressed: _pickImage,
                  icon: const Icon(FluentIcons.camera_24_regular, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap Tutor',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Nama wajib diisi.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Bio Singkat',
            border: OutlineInputBorder(),
            hintText: 'Perkenalkan diri Anda kepada calon murid...',
          ),
          validator: (value) => value == null || value.trim().length < 20 ? 'Bio minimal 20 karakter.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _maxStudentCapacityController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Kapasitas Murid Aktif Maksimal',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final cap = int.tryParse(value ?? '');
            return cap == null || cap <= 0 ? 'Wajib berupa angka > 0.' : null;
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Rekening Bank (Untuk Pencairan Dana)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _bankNameController.text.isEmpty ? null : _bankNameController.text,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          dropdownColor: isDark ? const Color(0xFF131926) : Colors.white,
          decoration: const InputDecoration(
            labelText: 'Pilih Bank',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'Bank Central Asia (BCA)', child: Text('Bank Central Asia (BCA)')),
            DropdownMenuItem(value: 'Bank Mandiri', child: Text('Bank Mandiri')),
            DropdownMenuItem(value: 'Bank Rakyat Indonesia (BRI)', child: Text('Bank Rakyat Indonesia (BRI)')),
            DropdownMenuItem(value: 'Bank Negara Indonesia (BNI)', child: Text('Bank Negara Indonesia (BNI)')),
            DropdownMenuItem(value: 'Bank Syariah Indonesia (BSI)', child: Text('Bank Syariah Indonesia (BSI)')),
          ],
          onChanged: (val) => setState(() => _bankNameController.text = val ?? ''),
          validator: (v) => v == null || v.isEmpty ? 'Pilih bank pencairan Anda.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _bankAccountNumberController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Nomor Rekening',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Nomor rekening wajib diisi.' : null,
        ),
      ],
    );
  }

  // Step 1: Preferensi Mengajar, Bahasa, & Tarif
  Widget _buildStep1(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mata Pelajaran yang Diajar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: const [
            'Matematika', 'Fisika', 'Kimia', 'Biologi',
            'Bahasa Inggris', 'Bahasa Indonesia', 'IPA', 'IPS', 'Informatika'
          ].map((subject) {
            final isSelected = _subjects.contains(subject);
            return FilterChip(
              label: Text(subject),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _subjects.add(subject);
                  } else {
                    _subjects.remove(subject);
                  }
                });
              },
              selectedColor: const Color(0xFF4B176E).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF4B176E),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4B176E) : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Tingkat Sekolah Sasaran',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: const ['SD', 'SMP', 'SMA'].map((level) {
            final isSelected = _teachingLevels.contains(level);
            return FilterChip(
              label: Text(level),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _teachingLevels.add(level);
                  } else {
                    _teachingLevels.remove(level);
                  }
                });
              },
              selectedColor: const Color(0xFF4B176E).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF4B176E),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4B176E) : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Bahasa Pengantar Mengajar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: const ['Bahasa Indonesia', 'Bahasa Inggris', 'Bahasa Mandarin', 'Bahasa Jepang'].map((lang) {
            final isSelected = _languages.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _languages.add(lang);
                  } else {
                    _languages.remove(lang);
                  }
                });
              },
              selectedColor: const Color(0xFF4B176E).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF4B176E),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4B176E) : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Tarif Mengajar Per Jam (Rp)',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            final number = num.tryParse(value ?? '');
            return number == null || number <= 0 ? 'Tarif harus lebih dari 0.' : null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _introVideoUrlController,
          keyboardType: TextInputType.url,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Link Video Perkenalan (Youtube/Drive)',
            border: OutlineInputBorder(),
            hintText: 'https://...',
          ),
        ),
      ],
    );
  }

  // Step 2: Legalitas & KTP (Kurasi AI)
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompletenessScoreCard(isDark),
        const SizedBox(height: 12),
        TextFormField(
          controller: _ktpNameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Nama Lengkap sesuai KTP',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) => value == null || value.trim().isEmpty ? 'Nama sesuai KTP wajib diisi.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nikController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Nomor NIK KTP (16 Digit)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'NIK KTP wajib diisi.';
            if (value.trim().length != 16) return 'NIK harus terdiri dari 16 digit.';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _birthPlaceController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Tempat Lahir',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) => value == null || value.trim().isEmpty ? 'Tempat lahir wajib diisi.' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _birthDateController,
                readOnly: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Tanggal Lahir',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(FluentIcons.calendar_24_regular),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _birthDate = picked;
                      _birthDateController.text =
                          "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
                    });
                  }
                },
                validator: (value) => _birthDate == null ? 'Wajib diisi.' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Unggah Dokumen Verifikasi',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _pickKtp,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2336) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.contact_card_24_regular, color: Color(0xFF4B176E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedKtpFile != null
                        ? "Terpilih: ${_selectedKtpFile!.path.split('/').last}"
                        : (_identityCardUrl != null && _identityCardUrl!.isNotEmpty)
                            ? "Foto KTP Terunggah"
                            : "Unggah Foto KTP Anda...",
                    style: TextStyle(
                      fontSize: 13,
                      color: (_selectedKtpFile != null || _identityCardUrl != null)
                          ? (isDark ? Colors.white : const Color(0xFF191622))
                          : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_identityCardUrl != null)
                  const Icon(FluentIcons.checkmark_12_filled, color: Color(0xFF16A34A), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickCertificate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2336) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.document_24_regular, color: Color(0xFF4B176E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCertificateFile != null
                        ? "Terpilih: ${_selectedCertificateFile!.path.split('/').last}"
                        : (_certificateUrl != null && _certificateUrl!.isNotEmpty)
                            ? "Sertifikat Pendidik Terunggah"
                            : "Unggah Sertifikat Bukti Keahlian...",
                    style: TextStyle(
                      fontSize: 13,
                      color: (_selectedCertificateFile != null || _certificateUrl != null)
                          ? (isDark ? Colors.white : const Color(0xFF191622))
                          : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_certificateUrl != null)
                  const Icon(FluentIcons.checkmark_12_filled, color: Color(0xFF16A34A), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Step 3: Pengalaman & Lokasi Mengajar (CV & Maps)
  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _experienceYearsController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Total Pengalaman (Tahun)',
            border: OutlineInputBorder(),
          ),
          validator: (value) => int.tryParse(value ?? '') == null ? 'Wajib diisi berupa angka.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _experienceDescriptionController,
          maxLines: 2,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Deskripsi Singkat Portofolio',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Deskripsi CV wajib diisi.' : null,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat CV Pengajaran',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
            ),
            TextButton.icon(
              onPressed: _showAddExperienceDialog,
              icon: const Icon(FluentIcons.add_16_regular),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_experienceCv.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              'Belum ada riwayat CV pengajaran.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _experienceCv.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _experienceCv[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(FluentIcons.briefcase_24_regular, color: Color(0xFF4B176E), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['role'] ?? '',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF191622)),
                        ),
                        Text(
                          "${item['institution']} (${item['period']})",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4B176E), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _experienceCv.removeAt(index)),
                    icon: const Icon(FluentIcons.delete_24_regular, color: Color(0xFFDC2626), size: 20),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 20),
        Text(
          'Lokasi & Koordinat GPS Mengajar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4B176E)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: const InputDecoration(
            labelText: 'Deskripsi Alamat Mengajar',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Alamat wajib diisi.' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _onUseCurrentLocationPressed,
                icon: const Icon(FluentIcons.my_location_24_regular),
                label: const Text('GPS HP'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showMapPickerDialog,
                icon: const Icon(FluentIcons.map_24_regular),
                label: Text(
                  _latitude != null && _longitude != null ? 'Peta (Tersimpan)' : 'Buka Peta',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myTutorProfileProvider);
    final currentUser = ref.watch(authStateProvider).value;
    final isSaving = ref.watch(tutorProfileLoadingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131926) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Kelola Profil Tutor'),
        actions: [
          IconButton(
            tooltip: 'Sembunyikan Profil',
            onPressed: isSaving ? null : _onDeactivatePressed,
            icon: const Icon(FluentIcons.eye_off_24_regular),
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            if (currentUser == null) {
              return const AppEmptyState(
                message: 'User belum login.',
                hint: 'Silakan login kembali untuk mengelola profil tutor.',
                icon: FluentIcons.lock_closed_24_regular,
                fullScreen: true,
              );
            }

            _syncInitialData(
              profile,
              currentUser.displayName,
              currentUser.photoUrl,
            );

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildStepIndicator(isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVerificationStatusBanner(),
                          const SizedBox(height: 8),
                          _buildStepContent(_currentStep, isDark),
                          const SizedBox(height: 100), // Spacing for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const AppLoadingState(message: 'Memuat profil tutor...'),
          error: (error, _) => AppErrorState(
            message: 'Gagal memuat data profil tutor.',
            detail: error.toString(),
            onRetry: () => ref.invalidate(myTutorProfileProvider),
            fullScreen: true,
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2336).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Sebelumnya'),
              )
            else
              const SizedBox.shrink(),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () {
                      if (_currentStep < _totalSteps - 1) {
                        setState(() => _currentStep++);
                      } else {
                        _onSavePressed();
                      }
                    },
              child: Text(
                _currentStep < _totalSteps - 1 ? 'Selanjutnya' : (isSaving ? 'Menyimpan...' : 'Simpan Profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
