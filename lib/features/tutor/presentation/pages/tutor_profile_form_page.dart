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
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _subjectInputController = TextEditingController();
  final _priceController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _experienceDescriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxStudentCapacityController = TextEditingController();

  final _ktpNameController = TextEditingController();
  final _nikController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthDateController = TextEditingController();

  final List<String> _subjects = <String>[];
  final List<String> _teachingLevels = <String>[];
  bool _isInitialized = false;
  String _photoUrl = '';
  File? _selectedImage;
  double? _latitude;
  double? _longitude;

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
    _subjectInputController.dispose();
    _priceController.dispose();
    _experienceYearsController.dispose();
    _experienceDescriptionController.dispose();
    _locationController.dispose();
    _maxStudentCapacityController.dispose();
    _ktpNameController.dispose();
    _nikController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
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

  Widget _buildVerificationStatusBanner() {
    Color bannerColor;
    IconData icon;
    String title;
    String description;

    switch (_verificationStatus) {
      case 'pending':
        bannerColor = const Color(0xFFD97706);
        icon = FluentIcons.clock_24_regular;
        title = 'Menunggu Verifikasi Admin';
        description = 'Profil Anda sedang diperiksa oleh tim kurasi admin. Saat ini profil Anda tersembunyi dari peta & daftar pencarian murid.';
        break;
      case 'rejected':
        bannerColor = const Color(0xFFDC2626);
        icon = FluentIcons.dismiss_circle_24_regular;
        title = 'Verifikasi Profil Ditolak';
        description = 'Alasan penolakan: "${_rejectionReason ?? 'Dokumen kurang lengkap atau buram'}"\nSilakan perbaiki dokumen di bawah ini dan ajukan ulang.';
        break;
      case 'approved':
        bannerColor = const Color(0xFF16A34A);
        icon = FluentIcons.checkmark_circle_24_regular;
        title = 'Terverifikasi Resmi';
        description = 'Profil Anda telah disetujui! Akun Anda kini aktif secara publik di peta geospasial & pencarian murid.';
        break;
      case 'none':
      default:
        bannerColor = const Color(0xFF4B176E);
        icon = FluentIcons.warning_24_regular;
        title = 'Kurasi Profil Wajib';
        description = 'Unggah dokumen identitas & bukti sertifikasi pengajar di bawah untuk mengajukan kurasi kelayakan sebelum akun Anda dipublikasikan.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: bannerColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: bannerColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessScoreCard() {
    final score = _calculateCompletenessScore();
    Color scoreColor = const Color(0xFFDC2626);
    if (score >= 85) {
      scoreColor = const Color(0xFF16A34A);
    } else if (score >= 60) {
      scoreColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi AI Trust Score',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4B176E)),
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
              backgroundColor: const Color(0xFFF1F5F9),
              color: scoreColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            score < 85
                ? '⚠️ Skor Anda ${score.toStringAsFixed(0)}%. Lengkapi data diri & unggah KTP/Sertifikat agar mencapai minimal 85% untuk auto-aktif.'
                : '🎉 Lolos Kurasi AI! Akun Anda akan langsung aktif secara publik setelah profil disimpan.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationUploadSection() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dokumen Penunjang Kurasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B176E),
            ),
          ),
          const SizedBox(height: 12),
          
          const Text(
            '1. Foto Kartu Tanda Penduduk (KTP)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191622)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickKtp,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              : "Pilih Foto KTP Anda...",
                      style: TextStyle(
                        fontSize: 12,
                        color: (_selectedKtpFile != null || _identityCardUrl != null)
                            ? const Color(0xFF191622)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_identityCardUrl != null && _identityCardUrl!.isNotEmpty)
                    const Icon(FluentIcons.checkmark_12_filled, color: Color(0xFF16A34A), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            '2. Sertifikat Pendidik / Bukti Keahlian',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF191622)),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickCertificate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              : "Pilih Sertifikat Pendidik Anda...",
                      style: TextStyle(
                        fontSize: 12,
                        color: (_selectedCertificateFile != null || _certificateUrl != null)
                            ? const Color(0xFF191622)
                            : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_certificateUrl != null && _certificateUrl!.isNotEmpty)
                    const Icon(FluentIcons.checkmark_12_filled, color: Color(0xFF16A34A), size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myTutorProfileProvider);
    final currentUser = ref.watch(authStateProvider).value;
    final isSaving = ref.watch(tutorProfileLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          IconButton(
            tooltip: 'Nonaktifkan profil',
            onPressed: isSaving ? null : _onDeactivatePressed,
            icon: const Icon(FluentIcons.eye_off_24_regular),
          ),
        ],
      ),
      body: profileAsync.when(
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
          ImageProvider<Object>? avatarImage;
          if (_selectedImage != null) {
            avatarImage = FileImage(_selectedImage!);
          } else if (_photoUrl.isNotEmpty) {
            avatarImage = NetworkImage(_photoUrl);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVerificationStatusBanner(),
                _buildCompletenessScoreCard(),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFEAF2FF),
                        backgroundImage: avatarImage,
                        child: (_selectedImage == null && _photoUrl.isEmpty)
                            ? const Icon(
                                FluentIcons.person_24_regular,
                                size: 40,
                              )
                            : null,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: IconButton.filled(
                          onPressed: isSaving ? null : _pickImage,
                          icon: const Icon(FluentIcons.camera_24_regular),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama tutor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 20) {
                      return 'Bio minimal 20 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mata Pelajaran yang Diajar (Master Data)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B176E),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: const [
                    'Matematika',
                    'Fisika',
                    'Kimia',
                    'Biologi',
                    'Bahasa Inggris',
                    'Bahasa Indonesia',
                    'IPA',
                    'IPS',
                    'Informatika',
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
                        color: isSelected ? const Color(0xFF4B176E) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tingkat Sekolah yang Diajar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B176E),
                  ),
                ),
                const SizedBox(height: 6),
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
                        color: isSelected ? const Color(0xFF4B176E) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga per jam (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final number = num.tryParse(value ?? '');
                    if (number == null || number <= 0) {
                      return 'Harga harus lebih dari 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceYearsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pengalaman (tahun)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final years = int.tryParse(value ?? '');
                    if (years == null || years < 0) {
                      return 'Pengalaman tidak valid.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _experienceDescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi pengalaman singkat',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value == null || value.trim().isEmpty) && _experienceCv.isEmpty) {
                      return 'Deskripsi pengalaman atau riwayat CV wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi mengajar',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : _onUseCurrentLocationPressed,
                  icon: const Icon(FluentIcons.location_24_regular),
                  label: Text(
                    _latitude != null && _longitude != null
                        ? 'Lokasi GPS tersimpan (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                        : 'Gunakan lokasi saat ini',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _maxStudentCapacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kapasitas maksimal murid aktif',
                    border: OutlineInputBorder(),
                    helperText: 'Jumlah maksimal murid aktif yang dapat memesan kelas Anda secara bersamaan.',
                  ),
                  validator: (value) {
                    final capacity = int.tryParse(value ?? '');
                    if (capacity == null || capacity <= 0) {
                      return 'Kapasitas wajib lebih besar dari 0.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Identitas KTP & Tanggal Lahir (Kurasi AI)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B176E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ktpNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap sesuai KTP',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama sesuai KTP wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nomor NIK KTP (16 Digit)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'NIK KTP wajib diisi.';
                          }
                          if (value.trim().length != 16) {
                            return 'NIK harus terdiri dari 16 digit.';
                          }
                          if (int.tryParse(value.trim()) == null) {
                            return 'NIK harus berupa angka.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _birthPlaceController,
                              decoration: const InputDecoration(
                                labelText: 'Tempat Lahir',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Tempat lahir wajib diisi.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _birthDateController,
                              readOnly: true,
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
                              validator: (value) {
                                if (_birthDate == null) {
                                  return 'Wajib diisi.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Riwayat CV Pengajaran',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B176E),
                            ),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Belum ada riwayat pengajaran. Tambahkan minimal 1 riwayat.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                                  child: Icon(
                                    FluentIcons.briefcase_24_regular,
                                    color: Color(0xFF4B176E),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['role'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF191622),
                                        ),
                                      ),
                                      Text(
                                        "${item['institution']} (${item['period']})",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF4B176E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item['description'],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    setState(() {
                                      _experienceCv.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(
                                    FluentIcons.delete_24_regular,
                                    color: Color(0xFFDC2626),
                                    size: 20,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                _buildVerificationUploadSection(),

                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isSaving ? null : _onSavePressed,
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan Profil'),
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
    );
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
        return AlertDialog(
          title: const Text('Tambah Pengalaman CV'),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: instansiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Institusi / Instansi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: peranCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Peran / Posisi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: periodeCtrl,
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
        geohash: existing?.geohash ?? '',
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
        return AlertDialog(
          title: const Text('Nonaktifkan Profil?'),
          content: const Text(
            'Profil tutor akan disembunyikan dari daftar pencarian murid.',
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
}
