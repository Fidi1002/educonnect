import 'dart:io';

import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  static const routeName = 'edit-profile';
  static const routePath = '/profile/edit';

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool _isInitialized = false;
  String _currentPhotoUrl = '';
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) return;
    
    setState(() {
      _selectedImage = File(picked.path);
    });
  }

  Future<void> _onSavePressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final controller = ref.read(authControllerProvider);
      await controller.updateUserProfile(
        displayName: _nameController.text.trim(),
        currentPhotoUrl: _currentPhotoUrl,
        newPhoto: _selectedImage,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isSaving = ref.watch(authLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const AppEmptyState(
              message: 'Gagal memuat profil',
              hint: 'Pastikan Anda sudah login',
              icon: FluentIcons.person_alert_24_regular,
            );
          }

          if (!_isInitialized) {
            _nameController.text = profile.displayName.isNotEmpty 
                ? profile.displayName 
                : 'Pengguna EduConnect';
            _currentPhotoUrl = profile.photoUrl;
            _isInitialized = true;
          }

          ImageProvider<Object>? avatarImage;
          if (_selectedImage != null) {
            avatarImage = FileImage(_selectedImage!);
          } else if (_currentPhotoUrl.isNotEmpty) {
            avatarImage = NetworkImage(_currentPhotoUrl);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: TutorUi.lavender,
                          backgroundImage: avatarImage,
                          child: (_selectedImage == null && _currentPhotoUrl.isEmpty)
                              ? const Icon(
                                  FluentIcons.person_24_regular,
                                  size: 50,
                                  color: TutorUi.ink,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: isSaving ? null : _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: TutorUi.ink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              FluentIcons.camera_24_regular,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Nama Lengkap',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF191622),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !isSaving,
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    filled: true,
                    fillColor: TutorUi.slate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: TutorUi.ink, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama wajib diisi.';
                    }
                    if (value.trim().length < 3) {
                      return 'Nama terlalu pendek.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                FilledButton(
                  onPressed: isSaving ? null : _onSavePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: TutorUi.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat profil...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat profil',
          detail: error.toString(),
          onRetry: () => ref.invalidate(currentUserProfileProvider),
        ),
      ),
    );
  }
}
