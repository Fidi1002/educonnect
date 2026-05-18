import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/presentation/pages/edit_profile_page.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:educonnect/features/home/presentation/pages/tutor_ebook_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorProfilePage extends ConsumerWidget {
  const TutorProfilePage({super.key});

  static const routeName = 'tutor-profile';
  static const routePath = '/tutor/profile';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myTutorProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: profileAsync.when(
        data: (profile) {
          final currentUser = ref.watch(authStateProvider).value;
          final displayName = profile?.displayName.trim().isNotEmpty == true
              ? profile!.displayName
              : currentUser?.displayName ?? 'Tutor EduConnect';
          final email = currentUser?.email ?? 'tutor@educonnect.com';
          final rating = profile != null && profile.rating > 0
              ? profile.rating.toStringAsFixed(1)
              : 'Baru';
          final photoUrl = profile?.photoUrl ?? currentUser?.photoUrl ?? '';

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF4B176E),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: const Text(
                    'Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient Background
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
                          ),
                        ),
                      ),
                      // Decorative circles
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -20,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      // Profile Info
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: const Color(0xFFF3F0F7),
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isNotEmpty
                                    ? null
                                    : const Icon(
                                        FluentIcons.person_24_regular,
                                        size: 40,
                                        color: Color(0xFF4B176E),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    FluentIcons.star_12_filled,
                                    color: Color(0xFFFFB224),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$rating • $email',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengaturan Akun',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191622),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _ProfileMenuTile(
                              icon: FluentIcons.person_24_regular,
                              iconBgColor: const Color(0xFFE0F2FE),
                              iconColor: const Color(0xFF0369A1),
                              title: 'Akun Umum',
                              subtitle: 'Ubah nama dan foto profil utama',
                              onTap: () => context.pushNamed(EditProfilePage.routeName),
                            ),
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: Color(0xFFF1F5F9),
                            ),
                            _ProfileMenuTile(
                              icon: FluentIcons.briefcase_24_regular,
                              iconBgColor: const Color(0xFFF3E8FF),
                              iconColor: const Color(0xFF7E22CE),
                              title: 'Profil Pengajar',
                              subtitle: 'Perbarui info bio, harga, & mapel',
                              onTap: () => context.pushNamed(
                                TutorProfileFormPage.routeName,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: Color(0xFFF1F5F9),
                            ),
                            _ProfileMenuTile(
                              icon: FluentIcons.calendar_clock_24_regular,
                              iconBgColor: const Color(0xFFFCE7F3),
                              iconColor: const Color(0xFFBE185D),
                              title: 'Atur Ketersediaan Waktu',
                              subtitle: 'Tentukan jadwal kosong untuk mengajar',
                              onTap: () => context.pushNamed(
                                TutorAvailabilityPage.routeName,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: Color(0xFFF1F5F9),
                            ),
                            _ProfileMenuTile(
                              icon: FluentIcons.library_24_regular,
                              iconBgColor: const Color(0xFFE0E7FF),
                              iconColor: const Color(0xFF4338CA),
                              title: 'Koleksi E-Book',
                              subtitle: 'Unggah dan kelola modul belajar',
                              onTap: () => context.pushNamed(
                                TutorEbookPage.routeName,
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 64,
                              color: Color(0xFFF1F5F9),
                            ),
                            _ProfileMenuTile(
                              icon: FluentIcons.sign_out_24_regular,
                              iconBgColor: const Color(0xFFFEF2F2),
                              iconColor: const Color(0xFFB91C1C),
                              title: 'Keluar',
                              subtitle: 'Akhiri sesi akun dengan aman',
                              onTap: () =>
                                  ref.read(authControllerProvider).signOut(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Lainnya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF191622),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Column(
                          children: [
                            _ProfileMenuTile(
                              icon: FluentIcons.headset_24_regular,
                              iconBgColor: Color(0xFFEAF2FF),
                              iconColor: Color(0xFF4B176E),
                              title: 'Bantuan & Support',
                              subtitle: 'Hubungi tim bantuan kami',
                            ),
                            Divider(
                              height: 1,
                              indent: 64,
                              color: Color(0xFFF1F5F9),
                            ),
                            _ProfileMenuTile(
                              icon: FluentIcons.info_24_regular,
                              iconBgColor: Color(0xFFEAF2FF),
                              iconColor: Color(0xFF4B176E),
                              title: 'Tentang Aplikasi',
                              subtitle: 'Versi aplikasi v1.0.0',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat profil...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat profil.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorProfileProvider),
          fullScreen: true,
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBgColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF191622),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6D6380),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              FluentIcons.chevron_right_20_regular,
              color: Color(0xFFC3BCCF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
