import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/availability/presentation/pages/tutor_availability_page.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/chat/application/chat_controller.dart';
import 'package:educonnect/features/chat/presentation/pages/inbox_page.dart';
import 'package:educonnect/features/booking/presentation/pages/tutor_bookings_page.dart';
import 'package:educonnect/features/auth/domain/models/app_user_profile.dart';
import 'package:educonnect/features/tutor/presentation/pages/tutor_profile_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TutorHomePage extends ConsumerWidget {
  const TutorHomePage({super.key});

  static const routeName = 'tutor-home';
  static const routePath = '/tutor/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final pendingCount = ref.watch(
      tutorPendingBookingsProvider.select(
        (value) => value.valueOrNull?.length ?? 0,
      ),
    );
    final unreadChatCount =
        ref.watch(unreadMessagesCountProvider).valueOrNull ?? 0;
    final waitingPaymentCount = ref.watch(tutorAwaitingPaymentCountProvider);
    return profileAsync.when(
      data: (profile) => _TutorHomeScaffold(
        profile: profile,
        pendingCount: pendingCount,
        waitingPaymentCount: waitingPaymentCount,
        unreadChatCount: unreadChatCount,
        onLogout: () => ref.read(authControllerProvider).signOut(),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Terjadi kesalahan: $error'))),
    );
  }
}

class _TutorHomeScaffold extends StatelessWidget {
  const _TutorHomeScaffold({
    required this.profile,
    required this.pendingCount,
    required this.waitingPaymentCount,
    required this.unreadChatCount,
    required this.onLogout,
  });

  final AppUserProfile? profile;
  final int pendingCount;
  final int waitingPaymentCount;
  final int unreadChatCount;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tutorName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Tutor';

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Tutor - $tutorName'),
        actions: [
          _ChatBadgeButton(
            count: unreadChatCount,
            onTap: () => context.pushNamed(InboxPage.routeName),
          ),
          IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Ringkasan Hari Ini',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _StatCard(
            title: 'Permintaan Kelas Baru',
            value: pendingCount.toString(),
            icon: Icons.notifications_active_outlined,
            color: colorScheme.primaryContainer,
          ),
          const SizedBox(height: 10),
          _StatCard(
            title: 'Menunggu Pembayaran',
            value: waitingPaymentCount.toString(),
            icon: Icons.payments_outlined,
            color: colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 10),
          _StatCard(
            title: 'Rating Tutor',
            value: '5.0',
            icon: Icons.star_outline,
            color: colorScheme.tertiaryContainer,
          ),
          const SizedBox(height: 20),
          Text(
            'Aksi Cepat',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => context.pushNamed(TutorProfileFormPage.routeName),
            icon: const Icon(Icons.edit_note),
            label: const Text('Lengkapi Profil Tutor'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(TutorBookingsPage.routeName),
            icon: const Icon(Icons.schedule_send),
            label: const Text('Kelola Booking Murid'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pushNamed(TutorAvailabilityPage.routeName),
            icon: const Icon(Icons.access_time_outlined),
            label: const Text('Atur Jadwal Ketersediaan'),
          ),
        ],
      ),
    );
  }
}

class _ChatBadgeButton extends StatelessWidget {
  const _ChatBadgeButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        if (count > 0)
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
