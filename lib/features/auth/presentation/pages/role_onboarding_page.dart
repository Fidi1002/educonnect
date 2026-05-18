import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:educonnect/features/auth/presentation/pages/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      await ref.read(authControllerProvider).signOut();
      if (!mounted) {
        return;
      }
      context.go(AuthPage.routePath);
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
            ? const LinearGradient(
                colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected ? null : const Color(0xFFF0F4FF),
        border: Border.all(
          color: selected ? Colors.transparent : const Color(0xFFC9D8F2),
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
                    color: selected ? Colors.white : const Color(0xFF4B176E),
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
                              : const Color(0xFF4B176E),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: selected
                              ? Colors.white70
                              : const Color(0xFF667085),
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
