import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  static const routeName = 'student-profile';
  static const routePath = '/student/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    const brandColor = Color(0xFF4B176E);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          final displayName = profile?.displayName.trim().isNotEmpty == true
              ? profile!.displayName
              : 'Pengguna EduConnect';
          final username = profile?.email.split('@').first ?? 'educonnect_user';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brandColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      backgroundImage: (profile?.photoUrl.isNotEmpty ?? false)
                          ? NetworkImage(profile!.photoUrl)
                          : null,
                      child: (profile?.photoUrl.isNotEmpty ?? false)
                          ? null
                          : const Icon(Icons.person, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    _ProfileMenuTile(
                      icon: Icons.person_outline,
                      title: 'My Account',
                      subtitle: 'Make changes to your account',
                      trailing: const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                      onTap: () {},
                    ),
                    _ProfileMenuTile(
                      icon: Icons.history,
                      title: 'Your Activity',
                      subtitle: 'Manage your activity',
                      onTap: () {},
                    ),
                    _ProfileMenuTile(
                      icon: Icons.logout,
                      title: 'Log out',
                      subtitle: 'Further secure your account for safety',
                      onTap: () => ref.read(authControllerProvider).signOut(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'More',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: const [
                    _ProfileMenuTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Help & Support',
                      subtitle: '',
                    ),
                    _ProfileMenuTile(
                      icon: Icons.favorite_border,
                      title: 'About App',
                      subtitle: '',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Gagal memuat profil: $error')),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: const Color(0xFFF1EDFA),
        child: Icon(icon, size: 16, color: const Color(0xFF4B176E)),
      ),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: Colors.black45),
    );
  }
}
