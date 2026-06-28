import 'dart:io';

import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:educonnect/core/presentation/localization/app_translations.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isInitialized = false;
  bool _isEditing = false; // Toggles between Read-Only and Edit Mode
  String _currentPhotoUrl = '';
  File? _selectedImage;
  String? _selectedSchoolLevel;
  String _preferredTutorGender = 'any';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
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

  Future<void> _onSavePressed(AppTranslations translations) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final controller = ref.read(authControllerProvider);
      final profile = ref.read(currentUserProfileProvider).value;
      await controller.runAuthTask(() async {
        await controller.updateUserProfile(
          displayName: _nameController.text.trim(),
          currentPhotoUrl: _currentPhotoUrl,
          newPhoto: _selectedImage,
          schoolLevel: profile?.role == AppUserRole.student ? _selectedSchoolLevel : null,
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          preferredTutorGender: _preferredTutorGender,
        );
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translations.updateProfileSuccess),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        _isEditing = false;
        _selectedImage = null;
      });
      // Invalidate profile to load fresh details
      ref.invalidate(currentUserProfileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${translations.failed}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final isSaving = ref.watch(authLoadingProvider);
    final translations = ref.watch(translationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (profileAsync.value != null)
            IconButton(
              icon: Icon(_isEditing ? FluentIcons.dismiss_24_regular : FluentIcons.edit_24_regular),
              tooltip: _isEditing ? translations.cancel : translations.editProfileTooltip,
              onPressed: isSaving
                  ? null
                  : () {
                      setState(() {
                        if (_isEditing) {
                          // Cancel: restore initial values and turn off edit mode
                          _isEditing = false;
                          _selectedImage = null;
                          _isInitialized = false;
                        } else {
                          // Edit: turn on edit mode
                          _isEditing = true;
                        }
                      });
                    },
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            return profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return AppEmptyState(
                    message: translations.failed,
                    hint: 'Pastikan Anda sudah login',
                    icon: FluentIcons.person_alert_24_regular,
                  );
                }

                if (!_isInitialized) {
                  _nameController.text = profile.displayName.isNotEmpty 
                      ? profile.displayName 
                      : 'Pengguna EduConnect';
                  _currentPhotoUrl = profile.photoUrl;
                  _selectedSchoolLevel = profile.schoolLevel;
                  _phoneController.text = profile.phoneNumber ?? '';
                  _addressController.text = profile.address ?? '';
                  _preferredTutorGender = profile.preferredTutorGender ?? 'any';
                  _isInitialized = true;
                }

                ImageProvider<Object>? avatarImage;
                if (_selectedImage != null) {
                  avatarImage = FileImage(_selectedImage!);
                } else if (_currentPhotoUrl.isNotEmpty) {
                  avatarImage = NetworkImage(_currentPhotoUrl);
                }

                final formContent = Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    children: [
                      Text(
                        _isEditing ? translations.editProfile : translations.viewProfile,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar Area with overlay camera badge
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
                                boxShadow: isDark ? null : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: (_isEditing && !isSaving) ? _pickImage : null,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: TutorUi.lavender,
                                  backgroundImage: avatarImage,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (_selectedImage == null && _currentPhotoUrl.isEmpty)
                                        const Icon(
                                          FluentIcons.person_24_regular,
                                          size: 50,
                                          color: TutorUi.ink,
                                        ),
                                      if (_isEditing)
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                FluentIcons.camera_24_regular,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Ubah Foto',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // If in Read-Only Mode, display beautiful stylized cards
                      if (!_isEditing) ...[
                        _buildReadOnlyCard(
                          context,
                          translations.fullName,
                          profile.displayName.isNotEmpty ? profile.displayName : 'Pengguna EduConnect',
                          FluentIcons.person_24_regular,
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyCard(
                          context,
                          translations.emailAddress,
                          profile.email,
                          FluentIcons.mail_24_regular,
                        ),
                        const SizedBox(height: 16),
                        _buildReadOnlyCard(
                          context,
                          'Nomor WhatsApp',
                          profile.phoneNumber?.isNotEmpty == true ? profile.phoneNumber! : 'Belum diisi',
                          FluentIcons.phone_24_regular,
                        ),
                        const SizedBox(height: 16),
                        if (profile.role == AppUserRole.student) ...[
                          _buildReadOnlyCard(
                            context,
                            translations.schoolLevel,
                            profile.schoolLevel ?? 'Belum memilih',
                            FluentIcons.book_24_regular,
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyCard(
                            context,
                            'Preferensi Gender Tutor',
                            profile.preferredTutorGender == 'male'
                                ? 'Laki-laki'
                                : profile.preferredTutorGender == 'female'
                                    ? 'Perempuan'
                                    : 'Semua Gender',
                            FluentIcons.people_24_regular,
                          ),
                          const SizedBox(height: 16),
                          _buildReadOnlyCard(
                            context,
                            'Alamat Belajar Utama',
                            profile.address?.isNotEmpty == true ? profile.address! : 'Belum diisi',
                            FluentIcons.location_24_regular,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildReadOnlyCard(
                          context,
                          translations.appRole,
                          profile.role == AppUserRole.student
                              ? translations.appRoleStudent
                              : translations.appRoleTutor,
                          FluentIcons.shield_keyhole_24_regular,
                        ),
                      ] else ...[
                        // If in Edit Mode, display Form Fields
                        Text(
                          translations.fullName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Kolom input nama lengkap Anda',
                          textField: true,
                          child: TextFormField(
                            controller: _nameController,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              hintText: translations.enterFullName,
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
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Nomor WhatsApp / Telepon',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          enabled: !isSaving,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: Icon(FluentIcons.phone_24_regular),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 9) {
                                return 'Nomor telepon tidak valid.';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        if (profile.role == AppUserRole.student) ...[
                          Text(
                            translations.schoolLevel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Custom horizontal segmented cards for school level
                          Row(
                            children: ['SD', 'SMP', 'SMA'].map((level) {
                              final isSelected = _selectedSchoolLevel == level;
                              String label = '';
                              if (level == 'SD') label = 'SD (Dasar)';
                              if (level == 'SMP') label = 'SMP (Menengah)';
                              if (level == 'SMA') label = 'SMA (Atas)';

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF4B176E)
                                          : (isDark ? const Color(0xFF28354E) : Colors.white),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF4B176E)
                                            : (isDark ? const Color(0xFF28354E) : const Color(0xFFE2E8F0)),
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: InkWell(
                                      onTap: isSaving
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedSchoolLevel = level;
                                              });
                                            },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              level == 'SD'
                                                  ? FluentIcons.reading_list_24_regular
                                                  : level == 'SMP'
                                                      ? FluentIcons.book_24_regular
                                                      : FluentIcons.hat_graduation_24_regular,
                                              color: isSelected
                                                  ? Colors.white
                                                  : (isDark ? Colors.white70 : const Color(0xFF4B176E)),
                                              size: 20,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark ? Colors.white70 : const Color(0xFF4A5568)),
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tingkat sekolah digunakan untuk merekomendasikan tutor yang sesuai dengan kurikulum belajar Anda.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Preferensi Gender Tutor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Semua')),
                                  selected: _preferredTutorGender == 'any',
                                  onSelected: isSaving ? null : (selected) {
                                    if (selected) setState(() => _preferredTutorGender = 'any');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Laki-laki')),
                                  selected: _preferredTutorGender == 'male',
                                  onSelected: isSaving ? null : (selected) {
                                    if (selected) setState(() => _preferredTutorGender = 'male');
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Perempuan')),
                                  selected: _preferredTutorGender == 'female',
                                  onSelected: isSaving ? null : (selected) {
                                    if (selected) setState(() => _preferredTutorGender = 'female');
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'Alamat Belajar Utama (Untuk Les Offline)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _addressController,
                            enabled: !isSaving,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan alamat lengkap rumah Anda (Contoh: Jl. Mawar No. 12, Kel. Menteng)',
                              prefixIcon: Icon(FluentIcons.location_24_regular),
                            ),
                          ),
                        ],
                        const SizedBox(height: 40),
                        
                        // Save Button
                        Semantics(
                          label: 'Tombol simpan perubahan profil',
                          button: true,
                          child: FilledButton(
                            onPressed: isSaving ? null : () => _onSavePressed(translations),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSaving) ...[
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Text(
                                  isSaving ? translations.saving : translations.saveChanges,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().slideY(begin: 0.2, duration: 250.ms, curve: Curves.easeOutQuad),
                      ],
                    ],
                  ),
                );

                if (isTablet) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: formContent,
                    ),
                  );
                }
                return formContent;
              },
              loading: () => const AppLoadingState(message: 'Memuat profil...'),
              error: (error, _) => AppErrorState(
                message: translations.failed,
                detail: error.toString(),
                onRetry: () => ref.invalidate(currentUserProfileProvider),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper widget to build premium static Read-Only Cards
  Widget _buildReadOnlyCard(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Theme.of(context).colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.03, curve: Curves.easeOutQuad);
  }
}
