import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleOnboardingPage extends ConsumerStatefulWidget {
  const RoleOnboardingPage({super.key});

  static const routeName = 'role-onboarding';
  static const routePath = '/onboarding-role';

  @override
  ConsumerState<RoleOnboardingPage> createState() => _RoleOnboardingPageState();
}

class _RoleOnboardingPageState extends ConsumerState<RoleOnboardingPage> {
  AppUserRole? _selectedRole;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Peran Akun')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _RoleOptionCard(
              title: 'Saya Murid',
              subtitle: 'Cari tutor terdekat dan booking kelas dengan mudah.',
              icon: FluentIcons.hat_graduation_24_regular,
              selected: _selectedRole == AppUserRole.student,
              onTap: () {
                setState(() {
                  _selectedRole = AppUserRole.student;
                });
              },
            ),
            const SizedBox(height: 12),
            _RoleOptionCard(
              title: 'Saya Tutor',
              subtitle: 'Buat profil mengajar dan terima booking dari murid.',
              icon: Icons.cast_for_education_outlined,
              selected: _selectedRole == AppUserRole.tutor,
              onTap: () {
                setState(() {
                  _selectedRole = AppUserRole.tutor;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_selectedRole == null || _isSaving)
                    ? null
                    : _saveRole,
                child: Text(_isSaving ? 'Menyimpan...' : 'Lanjutkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRole() async {
    if (_selectedRole == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(authControllerProvider).setRole(_selectedRole!);
      // GoRouter will automatically redirect the user to the correct dashboard
      // reactively based on the user's updated profile.
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan peran akun. Coba lagi sebentar lagi. ${error.toString()}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: selected
            ? LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected ? Colors.transparent : Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white24 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: selected ? Colors.white : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: selected
                              ? Colors.white70
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
