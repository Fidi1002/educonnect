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

  bool _isInitialized = false;
  bool _isEditing = false; // Toggles between Read-Only and Edit Mode
  String _currentPhotoUrl = '';
  File? _selectedImage;
  String? _selectedSchoolLevel;

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

  Future<void> _onSavePressed(AppTranslations translations) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      final controller = ref.read(authControllerProvider);
      final profile = ref.read(currentUserProfileProvider).value;
      await controller.updateUserProfile(
        displayName: _nameController.text.trim(),
        currentPhotoUrl: _currentPhotoUrl,
        newPhoto: _selectedImage,
        schoolLevel: profile?.role == AppUserRole.student ? _selectedSchoolLevel : null,
      );
      
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
                      // Avatar Area with dynamic camera badge
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
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Semantics(
                                  label: 'Pilih foto profil baru dari galeri',
                                  button: true,
                                  child: GestureDetector(
                                    onTap: isSaving ? null : _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        FluentIcons.camera_24_regular,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ).animate().scale(delay: 100.ms, duration: 200.ms),
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
                        if (profile.role == AppUserRole.student) ...[
                          _buildReadOnlyCard(
                            context,
                            translations.schoolLevel,
                            profile.schoolLevel ?? 'SD / SMP / SMA',
                            FluentIcons.book_24_regular,
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
                        // If in Edit Mode, display TextFormFields
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
                        if (profile.role == AppUserRole.student) ...[
                          const SizedBox(height: 24),
                          Text(
                            translations.schoolLevel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Pilihan tingkat sekolah',
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSchoolLevel,
                              decoration: const InputDecoration(),
                              items: [
                                DropdownMenuItem(
                                  value: 'SD',
                                  child: Text(translations.chooseFromSD),
                                ),
                                DropdownMenuItem(
                                  value: 'SMP',
                                  child: Text(translations.chooseFromSMP),
                                ),
                                DropdownMenuItem(
                                  value: 'SMA',
                                  child: Text(translations.chooseFromSMA),
                                ),
                              ],
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedSchoolLevel = value;
                                      });
                                    },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Tingkat sekolah wajib dipilih.';
                                }
                                return null;
                              },
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
