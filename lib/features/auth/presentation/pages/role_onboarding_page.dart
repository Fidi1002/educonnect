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
              icon: Icons.school_outlined,
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
          content: Text('Gagal simpan role. Coba lagi. (${error.toString()})'),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
