import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/features/tutor/application/tutor_profile_controller.dart';
import 'package:educonnect/features/wallet/application/wallet_controller.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TutorStatsPage extends ConsumerWidget {
  const TutorStatsPage({super.key});

  static const routeName = 'tutor-stats';
  static const routePath = '/tutor/stats';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tutorProfileAsync = ref.watch(myTutorProfileProvider);
    final statsAsync = ref.watch(tutorStatsProvider);
    final walletAsync = ref.watch(walletBalanceProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Statistik & Analitik',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: const Color(0xFF4B176E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: tutorProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const AppErrorState(
              message: 'Profil tutor tidak ditemukan.',
              fullScreen: true,
            );
          }

          return statsAsync.when(
            data: (stats) {
              final wallet = walletAsync.valueOrNull;
              final availableBalance = wallet?.availableBalance ?? 0;
              final pendingBalance = wallet?.pendingBalance ?? 0;
              final totalEarned = wallet?.totalEarned ?? 0;

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myTutorProfileProvider);
                  ref.invalidate(tutorStatsProvider);
                  ref.invalidate(walletBalanceProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Earnings Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PENDAPATAN TUTOR',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saldo Aktif',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currencyFormat.format(availableBalance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pendapatan Bulan Ini',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    currencyFormat.format(stats.monthlyEarnings),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Akumulasi: ${currencyFormat.format(totalEarned)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Pending: ${currencyFormat.format(pendingBalance)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _StatMetricCard(
                          title: 'Jam Mengajar',
                          value: '${stats.totalHoursTaught.toStringAsFixed(1)} Jam',
                          icon: FluentIcons.timer_24_regular,
                          color: const Color(0xFF0284C7),
                        ),
                        _StatMetricCard(
                          title: 'Sesi Selesai',
                          value: '${stats.completedSessionsCount} Sesi',
                          icon: FluentIcons.checkmark_circle_24_regular,
                          color: const Color(0xFF10B981),
                        ),
                        _StatMetricCard(
                          title: 'Murid Aktif',
                          value: '${stats.activeStudentsCount} Murid',
                          icon: FluentIcons.people_24_regular,
                          color: const Color(0xFF8B5CF6),
                        ),
                        _StatMetricCard(
                          title: 'Rating Tutor',
                          value: profile.rating > 0
                              ? '${profile.rating.toStringAsFixed(1)} / 5.0'
                              : 'Baru',
                          icon: FluentIcons.star_24_regular,
                          color: const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Consistency card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Skor Konsistensi Mengajar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                '${profile.consistencyScore.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4B176E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: profile.consistencyScore / 100.0,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4B176E),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Skor ini didasarkan pada ketepatan waktu Anda memulai kelas dan kehadiran Anda dalam mengajar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weekly Chart Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Distribusi Sesi Les Mingguan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Frekuensi total kelas pengajaran yang telah dikonfirmasi per hari.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _WeeklyBarChart(counts: stats.weekdaySessionCounts),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () =>
                const AppLoadingState(message: 'Memuat data statistik...'),
            error: (error, _) => AppErrorState(
              message: 'Gagal memuat statistik tutor.',
              detail: error.toString(),
              onRetry: () => ref.invalidate(tutorStatsProvider),
              fullScreen: true,
            ),
          );
        },
        loading: () => const AppLoadingState(message: 'Memuat profil tutor...'),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat profil tutor.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorProfileProvider),
          fullScreen: true,
        ),
      ),
    );
  }
}

class _StatMetricCard extends StatelessWidget {
  const _StatMetricCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.fold<int>(0, (max, val) => val > max ? val : max);
    final divisor = maxCount == 0 ? 1 : maxCount;
    final weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final count = counts[index];
        final pct = count / divisor;
        final barHeight = pct * 100.0; // max 100 pixels

        return Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: count > 0 ? const Color(0xFF4B176E) : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 22,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                width: 22,
                height: barHeight > 4.0 ? barHeight : 4.0, // min height 4px if count > 0
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFF1377), Color(0xFF4B176E)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              weekdays[index],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        );
      }),
    );
  }
}
