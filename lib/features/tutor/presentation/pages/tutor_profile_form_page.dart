import 'dart:io';

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

  final List<String> _subjects = <String>[];
  bool _isInitialized = false;
  String _photoUrl = '';
  File? _selectedImage;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _subjectInputController.dispose();
    _priceController.dispose();
    _experienceYearsController.dispose();
    _experienceDescriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myTutorProfileProvider);
    final currentUser = ref.watch(authStateProvider).value;
    final isSaving = ref.watch(tutorProfileLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Tutor'),
        actions: [
          IconButton(
            tooltip: 'Nonaktifkan profil',
            onPressed: isSaving ? null : _onDeactivatePressed,
            icon: const Icon(Icons.visibility_off_outlined),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (currentUser == null) {
            return const Center(child: Text('User belum login.'));
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
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: avatarImage,
                        child: (_selectedImage == null && _photoUrl.isEmpty)
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: IconButton.filled(
                          onPressed: isSaving ? null : _pickImage,
                          icon: const Icon(Icons.camera_alt),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subjectInputController,
                        decoration: const InputDecoration(
                          labelText: 'Tambah mapel',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _addSubject,
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _subjects.map((item) {
                    return Chip(
                      label: Text(item),
                      onDeleted: () {
                        setState(() {
                          _subjects.remove(item);
                        });
                      },
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
                    labelText: 'Deskripsi pengalaman',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi pengalaman wajib diisi.';
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
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    _latitude != null && _longitude != null
                        ? 'Lokasi GPS tersimpan (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                        : 'Gunakan lokasi saat ini',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isSaving ? null : _onSavePressed,
                  child: Text(isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat data: $error')),
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

  void _addSubject() {
    final text = _subjectInputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    if (_subjects.contains(text)) {
      _subjectInputController.clear();
      return;
    }
    setState(() {
      _subjects.add(text);
      _subjectInputController.clear();
    });
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
        isActive: true,
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
        'Gagal mengambil lokasi. Pastikan izin lokasi aktif. (${error.toString()})',
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
      _showMessage('Profil tutor berhasil dinonaktifkan.');
    } on Exception catch (error) {
      _showMessage(
        'Gagal menonaktifkan profil. Coba beberapa saat lagi. (${error.toString()})',
      );
    }
  }

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('network') || raw.contains('socket')) {
      return 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
    }
    if (raw.contains('storage') || raw.contains('bucket')) {
      return 'Upload foto gagal. Pastikan file valid lalu coba lagi.';
    }
    if (raw.contains('permission') || raw.contains('not allowed')) {
      return 'Akses ditolak oleh server. Cek policy Supabase untuk profil tutor.';
    }
    return 'Gagal menyimpan profil tutor. Coba lagi. (${error.toString()})';
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
