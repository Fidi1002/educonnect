import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:educonnect/core/presentation/widgets/app_feedback_state.dart';
import 'package:educonnect/core/utils/calendar_sync_helper.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_item.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:educonnect/features/booking/domain/models/session_change_request.dart';
import 'package:educonnect/features/booking/domain/models/session_learning_record.dart';
import 'package:educonnect/features/chat/presentation/pages/chat_page.dart';
import 'package:educonnect/features/tutor/presentation/widgets/tutor_ui.dart';
import 'package:educonnect/features/booking/presentation/pages/virtual_classroom_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

enum _TutorBookingQuickFilter {
  all,
  needsAttention,
  awaitingPayment,
  active,
  completed,
}

class TutorBookingsPage extends ConsumerStatefulWidget {
  const TutorBookingsPage({super.key});

  static const routeName = 'tutor-bookings';
  static const routePath = '/tutor/bookings';

  @override
  ConsumerState<TutorBookingsPage> createState() => _TutorBookingsPageState();
}

class _TutorBookingsPageState extends ConsumerState<TutorBookingsPage> {
  final Map<String, GlobalKey> _sessionAnchorKeys = <String, GlobalKey>{};
  final TextEditingController _searchController = TextEditingController();
  String? _lastAutoScrolledSessionId;
  _TutorBookingQuickFilter _quickFilter = _TutorBookingQuickFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);
    final isLoading = ref.watch(bookingLoadingProvider);
    final query = GoRouterState.of(context).uri.queryParameters;
    final focusedBookingId = query['bookingId'];
    final focusedSessionId = query['sessionId'];
    final focusedSessionKey = focusedSessionId == null
        ? null
        : _sessionAnchorKeys.putIfAbsent(
            focusedSessionId,
            () => GlobalKey(debugLabel: 'session-$focusedSessionId'),
          );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: bookingsAsync.when(
        data: (items) {
          final now = DateTime.now();
          final requests =
              items
                  .where((item) => item.status == BookingStatus.pending)
                  .where(_matchesQuickFilter)
                  .where(_matchesSearch)
                  .toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(requests, focusedBookingId);
          final active =
              items
                  .where((item) => isTutorActiveBooking(item, now: now))
                  .where(_matchesQuickFilter)
                  .where(_matchesSearch)
                  .toList()
                ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));
          _bringFocusedBookingToFront(active, focusedBookingId);
          final history =
              items
                  .where((item) => isTutorHistoryBooking(item, now: now))
                  .where(_matchesQuickFilter)
                  .where(_matchesSearch)
                  .toList()
                ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));
          _bringFocusedBookingToFront(history, focusedBookingId);
          final initialTab = active.any((item) => item.id == focusedBookingId)
              ? 1
              : history.any((item) => item.id == focusedBookingId)
              ? 2
              : 0;

          _scheduleAutoScrollToSession(
            focusedSessionId: focusedSessionId,
            focusedSessionKey: focusedSessionKey,
          );

          return DefaultTabController(
            length: 3,
            initialIndex: initialTab,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Booking Murid',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF4B176E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Cari murid atau mapel...',
                              hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                              prefixIcon: Icon(FluentIcons.search_24_regular, color: isDark ? Colors.white60 : Colors.black54),
                              suffixIcon: _searchController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: Icon(
                                        FluentIcons.dismiss_24_regular,
                                        color: isDark ? Colors.white70 : Colors.black54,
                                      ),
                                    ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1B2336) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: isDark ? const BorderSide(color: Color(0xFF28354E)) : BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: isDark ? const BorderSide(color: Color(0xFF28354E)) : BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: isDark ? const Color(0xFFFF1377) : const Color(0xFF7B2CBF)),
                              ),
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChipButton(
                              label: 'Semua',
                              selected:
                                  _quickFilter == _TutorBookingQuickFilter.all,
                              onTap: () => setState(
                                () =>
                                    _quickFilter = _TutorBookingQuickFilter.all,
                              ),
                            ),
                            _FilterChipButton(
                              label: 'Butuh Aksi',
                              selected:
                                  _quickFilter ==
                                  _TutorBookingQuickFilter.needsAttention,
                              onTap: () => setState(
                                () => _quickFilter =
                                    _TutorBookingQuickFilter.needsAttention,
                              ),
                            ),
                            _FilterChipButton(
                              label: 'Menunggu Bayar',
                              selected:
                                  _quickFilter ==
                                  _TutorBookingQuickFilter.awaitingPayment,
                              onTap: () => setState(
                                () => _quickFilter =
                                    _TutorBookingQuickFilter.awaitingPayment,
                              ),
                            ),
                            _FilterChipButton(
                              label: 'Aktif',
                              selected:
                                  _quickFilter ==
                                  _TutorBookingQuickFilter.active,
                              onTap: () => setState(
                                () => _quickFilter =
                                    _TutorBookingQuickFilter.active,
                              ),
                            ),
                            _FilterChipButton(
                              label: 'Selesai',
                              selected:
                                  _quickFilter ==
                                  _TutorBookingQuickFilter.completed,
                              onTap: () => setState(
                                () => _quickFilter =
                                    _TutorBookingQuickFilter.completed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return TabBar(
                      isScrollable: true,
                      labelColor: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                      unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF756E81),
                      indicatorColor: isDark ? const Color(0xFFFF1377) : const Color(0xFF4B176E),
                      tabs: const [
                        Tab(text: 'Permintaan'),
                        Tab(text: 'Jadwal Aktif'),
                        Tab(text: 'Riwayat'),
                      ],
                    );
                  }
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TutorBookingList(
                        items: requests,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada permintaan booking baru.',
                        onRespond: _handleRespond,
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _TutorBookingList(
                        items: active,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada booking aktif saat ini.',
                        onRespond: _handleRespond,
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                      _TutorBookingList(
                        items: history,
                        isLoading: isLoading,
                        emptyMessage: 'Belum ada riwayat kelas.',
                        onRespond: _handleRespond,
                        focusedSessionId: focusedSessionId,
                        focusedSessionKey: focusedSessionKey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const AppLoadingState(
          message: 'Memuat booking murid...',
          fullScreen: false,
        ),
        error: (error, _) => AppErrorState(
          message: 'Gagal memuat booking murid.',
          detail: error.toString(),
          onRetry: () => ref.invalidate(myTutorBookingsProvider),
        ),
      ),
    );
  }

  void _scheduleAutoScrollToSession({
    required String? focusedSessionId,
    required GlobalKey? focusedSessionKey,
  }) {
    if (focusedSessionId == null ||
        focusedSessionId.isEmpty ||
        focusedSessionKey == null) {
      return;
    }
    if (_lastAutoScrolledSessionId == focusedSessionId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = focusedSessionKey.currentContext;
      if (ctx == null || !mounted) {
        return;
      }
      _lastAutoScrolledSessionId = focusedSessionId;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _bringFocusedBookingToFront(List<BookingItem> items, String? bookingId) {
    if (bookingId == null || bookingId.isEmpty || items.isEmpty) {
      return;
    }
    final index = items.indexWhere((item) => item.id == bookingId);
    if (index <= 0) {
      return;
    }
    final focused = items.removeAt(index);
    items.insert(0, focused);
  }

  bool _matchesSearch(BookingItem item) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final haystacks = <String>[
      item.subject,
      item.studentName,
      item.tutorName,
      item.message,
    ];
    return haystacks.any((value) => value.toLowerCase().contains(query));
  }

  bool _matchesQuickFilter(BookingItem item) {
    switch (_quickFilter) {
      case _TutorBookingQuickFilter.all:
        return true;
      case _TutorBookingQuickFilter.needsAttention:
        return item.status == BookingStatus.pending ||
            item.status == BookingStatus.awaitingPayment;
      case _TutorBookingQuickFilter.awaitingPayment:
        return item.status == BookingStatus.awaitingPayment;
      case _TutorBookingQuickFilter.active:
        return item.status == BookingStatus.paid;
      case _TutorBookingQuickFilter.completed:
        return item.status == BookingStatus.completed;
    }
  }

  Future<void> _handleRespond({
    required String bookingId,
    required BookingStatus status,
    required String successMessage,
  }) async {
    try {
      await ref
          .read(bookingControllerProvider)
          .respondBooking(bookingId: bookingId, status: status);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui status booking. Coba lagi sebentar lagi. ${error.toString()}',
          ),
        ),
      );
    }
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _TutorBookingList extends ConsumerStatefulWidget {
  const _TutorBookingList({
    required this.items,
    required this.isLoading,
    required this.emptyMessage,
    required this.onRespond,
    required this.focusedSessionId,
    required this.focusedSessionKey,
  });

  final List<BookingItem> items;
  final bool isLoading;
  final String emptyMessage;
  final String? focusedSessionId;
  final GlobalKey? focusedSessionKey;
  final Future<void> Function({
    required String bookingId,
    required BookingStatus status,
    required String successMessage,
  })
  onRespond;

  @override
  ConsumerState<_TutorBookingList> createState() => _TutorBookingListState();
}

class _TutorBookingListState extends ConsumerState<_TutorBookingList> {
  final Set<String> _clearedBookingFilters = {};
  final Set<String> _expandedPastSessions = {};

  SessionChangeRequest? _findPendingRequest(
    String sessionId,
    List<SessionChangeRequest> requests,
  ) {
    for (final request in requests) {
      if (request.sessionId == sessionId && request.isPending) {
        return request;
      }
    }
    return null;
  }

  void _showDisputeSupportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 10),
              Text(
                'Mediasi Sesi Belajar',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sesi ini sedang berada dalam status perselisihan (Disputed). Tim EduConnect akan melakukan peninjauan laporan kehadiran dan aktivitas belajar.',
                style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF475569)),
              ),
              SizedBox(height: 16),
              Text(
                'Hubungi Dukungan CS Resmi:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_android, size: 16, color: Color(0xFF4B176E)),
                  SizedBox(width: 8),
                  Text('WhatsApp: 0812-3456-7890', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Color(0xFF4B176E)),
                  SizedBox(width: 8),
                  Text('Email: support@educonnect.com', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelRequestDialog({
    required BuildContext context,
    required WidgetRef ref,
    required BookingSession session,
  }) async {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final timeDiff = session.sessionStart.difference(DateTime.now());
    final isEarlyCancel = timeDiff.inHours >= 12;

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajukan Pembatalan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEarlyCancel 
                    ? (isDark ? const Color(0xFF0C2A1C) : const Color(0xFFE8F5E9))
                    : (isDark ? const Color(0xFF2E1C0C) : const Color(0xFFFFF3E0)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isEarlyCancel 
                      ? (isDark ? const Color(0xFF1E5235) : Colors.green.shade200)
                      : (isDark ? const Color(0xFF5E3C1C) : Colors.orange.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEarlyCancel ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                    color: isEarlyCancel ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEarlyCancel ? 'Pembatalan Awal (Bebas Biaya)' : 'Pembatalan Terlambat',
                          style: TextStyle(
                            color: isEarlyCancel 
                                ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                                : (isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEarlyCancel 
                              ? 'Pembatalan dilakukan >= 12 jam sebelum kelas.'
                              : 'Pembatalan dilakukan < 12 jam sebelum kelas.',
                          style: TextStyle(
                            color: isEarlyCancel 
                                ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
                                : (isDark ? Colors.orange.shade400 : Colors.orange.shade700),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (submit != true) {
      reasonController.dispose();
      return;
    }
    await ref
        .read(bookingControllerProvider)
        .requestSessionCancel(
          sessionId: session.id,
          reason: reasonController.text,
        );
    reasonController.dispose();
  }

  Future<void> _showRescheduleRequestDialog({
    required BuildContext context,
    required WidgetRef ref,
    required BookingSession session,
    required int durationMinutes,
  }) async {
    final reasonController = TextEditingController();
    DateTime? selectedDateTime;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final timeDiff = session.sessionStart.difference(DateTime.now());
    final isTooLate = timeDiff.inHours < 6;

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Consumer(
              builder: (context, ref, child) {
                final countAsync = ref.watch(rescheduleCountProvider(session.bookingId));
                final count = countAsync.valueOrNull ?? 0;
                final isLimitReached = count >= 2;
                final cannotReschedule = isTooLate || isLimitReached;

                return AlertDialog(
                  title: const Text('Ajukan Reschedule'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Peringatan Batas Waktu 6 Jam
                      if (isTooLate) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A0C0C) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF521E1E) : Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reschedule tidak diperbolehkan kurang dari 6 jam sebelum sesi dimulai.',
                                  style: TextStyle(
                                    color: isDark ? Colors.red.shade300 : Colors.red.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Kuota Reschedule
                        countAsync.when(
                          data: (countVal) {
                            final remaining = (2 - countVal).clamp(0, 2);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: remaining == 0 
                                    ? (isDark ? const Color(0xFF2A0C0C) : const Color(0xFFFFEBEE))
                                    : (isDark ? const Color(0xFF2E260C) : const Color(0xFFFFFDE7)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: remaining == 0 
                                      ? (isDark ? const Color(0xFF521E1E) : Colors.red.shade200)
                                      : (isDark ? const Color(0xFF52451E) : Colors.amber.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    remaining == 0 ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                                    color: remaining == 0 ? Colors.red : Colors.amber.shade800,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      remaining == 0
                                          ? 'Batas reschedule bulan ini habis (Maks 2x/30 hari).'
                                          : 'Sisa kuota reschedule bulan ini: $remaining kali.',
                                      style: TextStyle(
                                        color: remaining == 0 
                                            ? (isDark ? Colors.red.shade300 : Colors.red.shade800)
                                            : (isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: LinearProgressIndicator(),
                          ),
                          error: (error, stack) => const SizedBox.shrink(),
                        ),
                      ],

                      OutlinedButton.icon(
                        onPressed: cannotReschedule ? null : () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 120)),
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                          );
                          if (date == null || !context.mounted) {
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 16, minute: 0),
                          );
                          if (time == null || !context.mounted) {
                            return;
                          }
                          setState(() {
                            selectedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        },
                        icon: const Icon(FluentIcons.clock_24_regular),
                        label: Text(
                          selectedDateTime == null
                              ? 'Pilih jadwal baru'
                              : '${selectedDateTime!.day}/${selectedDateTime!.month}/${selectedDateTime!.year} '
                                    '${selectedDateTime!.hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alasan',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !cannotReschedule,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: (selectedDateTime == null || cannotReschedule)
                          ? null
                          : () => Navigator.pop(context, true),
                      child: const Text('Kirim'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (submit != true || selectedDateTime == null) {
      reasonController.dispose();
      return;
    }
    try {
      await ref
          .read(bookingControllerProvider)
          .requestSessionReschedule(
            sessionId: session.id,
            proposedStart: selectedDateTime!,
            proposedEnd: selectedDateTime!.add(
              Duration(minutes: durationMinutes),
            ),
            reason: reasonController.text,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan reschedule berhasil dikirim.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final errorMsg = e.toString().replaceAll('PostgrestException:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan reschedule: $errorMsg'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      reasonController.dispose();
    }
  }

  SessionLearningRecord? _findLearningRecord(
    String sessionId,
    List<SessionLearningRecord> records,
  ) {
    for (final record in records) {
      if (record.sessionId == sessionId) {
        return record;
      }
    }
    return null;
  }

  List<BookingSession> _selectDisplayedSessions(
    List<BookingSession> sessions,
    String? targetSessionId,
  ) {
    if (targetSessionId != null && targetSessionId.isNotEmpty) {
      return sessions.where((s) => s.id == targetSessionId).toList();
    }
    return sessions.take(3).toList(growable: false);
  }

  Future<void> _showLearningRecordDialog({
    required BuildContext context,
    required WidgetRef ref,
    required BookingItem booking,
    required String sessionId,
    SessionLearningRecord? existing,
  }) async {
    final summaryController = TextEditingController(
      text: existing?.materialSummary ?? '',
    );
    final notesController = TextEditingController(
      text: existing?.materialNotes ?? '',
    );
    final homeworkTitleController = TextEditingController(
      text: existing?.homeworkTitle ?? '',
    );
    final homeworkDescController = TextEditingController(
      text: existing?.homeworkDescription ?? '',
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final submit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2336) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Materi & PR Sesi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: summaryController,
                decoration: InputDecoration(
                  labelText: 'Ringkasan materi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Catatan tutor',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: homeworkTitleController,
                decoration: InputDecoration(
                  labelText: 'Judul PR (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: homeworkDescController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Deskripsi PR (opsional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (submit != true) {
      summaryController.dispose();
      notesController.dispose();
      homeworkTitleController.dispose();
      homeworkDescController.dispose();
      return;
    }

    await ref
        .read(bookingControllerProvider)
        .saveTutorLearningRecord(
          bookingId: booking.id,
          sessionId: sessionId,
          studentUid: booking.studentUid,
          materialSummary: summaryController.text,
          materialNotes: notesController.text,
          homeworkTitle: homeworkTitleController.text,
          homeworkDescription: homeworkDescController.text,
        );
    summaryController.dispose();
    notesController.dispose();
    homeworkTitleController.dispose();
    homeworkDescController.dispose();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Materi dan PR berhasil disimpan untuk sesi ini.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final isLoading = widget.isLoading;
    final onRespond = widget.onRespond;
    if (items.isEmpty) {
      return AppEmptyState(
        message: widget.emptyMessage,
        hint:
            'Saat ada aktivitas booking dari murid, detail pengelolaannya akan muncul di sini.',
        icon: FluentIcons.hat_graduation_24_regular,
      );
    }

    final pendingCount = items
        .where((item) => item.status == BookingStatus.pending)
        .length;
    final waitingPaymentCount = items
        .where((item) => item.status == BookingStatus.awaitingPayment)
        .length;
    final activeCount = items
        .where((item) => item.status == BookingStatus.paid)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TutorActionSummaryCard(
          totalCount: items.length,
          pendingCount: pendingCount,
          waitingPaymentCount: waitingPaymentCount,
          activeCount: activeCount,
        ),
        const SizedBox(height: 12),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final sessionsAsync = ref.watch(bookingSessionsProvider(item.id));
          final requestsAsync = ref.watch(
            sessionChangeRequestsProvider(item.id),
          );
          final learningAsync = ref.watch(
            sessionLearningRecordsProvider(item.id),
          );
          final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
          final profileAsync = ref.watch(userProfileProvider(item.studentUid));
          final realName = profileAsync.valueOrNull?.displayName;
          final String displayStudentName;
          if (realName != null && realName.isNotEmpty && realName != 'Murid') {
            displayStudentName = realName;
          } else if (item.studentName.isNotEmpty &&
              item.studentName != 'Murid') {
            displayStudentName = item.studentName;
          } else {
            displayStudentName = profileAsync.isLoading
                ? 'Memuat profil...'
                : 'Murid Baru';
          }

          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2336) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
                boxShadow: const [TutorUi.mediumShadow],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF7B2CBF).withValues(alpha: 0.15) : const Color(0xFFF2E8FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          FluentIcons.book_24_regular,
                          color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF7B2CBF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.subject,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              displayStudentName,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF655C74),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TutorStatusBadge.booking(status: item.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          title: 'Paket',
                          value:
                              '${item.packageMonths} bln • ${item.sessionsPerWeek}x/mgg',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          title: 'Durasi',
                          value: '${item.durationMinutes} mnt/sesi',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    title: 'Periode',
                    value:
                        '${item.packageStartDate.day}/${item.packageStartDate.month}/${item.packageStartDate.year} - ${item.packageEndDate.day}/${item.packageEndDate.month}/${item.packageEndDate.year}',
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    title: item.meetingType == 'online' ? 'Metode' : 'Lokasi Pertemuan',
                    value: item.meetingType == 'online'
                        ? 'Online (Ruang Kelas Virtual)'
                        : item.meetingLocation,
                  ),
                  if (item.weeklySchedule.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      title: 'Jadwal Rutin',
                      value: item.weeklySchedule
                          .map(
                            (slot) => '${slot.weekdayLabel} ${slot.timeLabel}',
                          )
                          .join(' • '),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                          title: 'Biaya',
                          value: 'Rp ${item.totalAmount}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile(
                          title: 'Mulai',
                          value:
                              '${item.sessionStart.day}/${item.sessionStart.month}/${item.sessionStart.year} ${item.sessionStart.hour.toString().padLeft(2, '0')}:${item.sessionStart.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ],
                  ),
                  if (item.message.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan Murid',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFFB923C) : const Color(0xFF9A4D00),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF7A3D00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Divider(color: isDark ? const Color(0xFF28354E) : const Color(0xFFE9E3F2)),
                  const SizedBox(height: 16),
                  Text(
                    'Riwayat Pertemuan',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  sessionsAsync.when(
                    data: (sessions) {
                      if (sessions.isEmpty) {
                        return const AppEmptyState(
                          message: 'Belum ada sesi terjadwal.',
                          hint:
                              'Sesi akan muncul setelah booking aktif dan jadwal paket terbentuk.',
                          icon: Icons.event_busy_outlined,
                          fullScreen: false,
                        );
                      }
                      Widget buildSessionCard(BookingSession session) {
                        final isFocusedSession =
                            widget.focusedSessionId != null &&
                            widget.focusedSessionId!.isNotEmpty &&
                            session.id == widget.focusedSessionId;
                        final request = _findPendingRequest(
                          session.id,
                          requestsAsync.valueOrNull ?? const [],
                        );
                        final learningRecord = _findLearningRecord(
                          session.id,
                          learningAsync.valueOrNull ?? const [],
                        );
                        final canStartSession =
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionStart.difference(DateTime.now()).inMinutes <= 10 &&
                            session.sessionEnd.isAfter(DateTime.now());
                        final canMarkDone =
                            (session.status == BookingSessionStatus.scheduled ||
                                session.status == BookingSessionStatus.inProgress) &&
                            session.sessionEnd.isBefore(DateTime.now());
                        final canMarkStudentNoShow =
                            (session.status == BookingSessionStatus.scheduled ||
                                session.status == BookingSessionStatus.inProgress) &&
                            session.sessionEnd.isBefore(DateTime.now());
                        final canRequestChange =
                            request == null &&
                            session.status == BookingSessionStatus.scheduled &&
                            session.sessionStart.isAfter(DateTime.now());
                        return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            key: isFocusedSession ? widget.focusedSessionKey : null,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isFocusedSession
                                  ? (isDark ? const Color(0xFF3B1E54) : const Color(0xFFF8F0FF))
                                  : (isDark ? const Color(0xFF090D16) : Theme.of(context).colorScheme.surfaceContainerHigh),
                              border: isFocusedSession
                                  ? Border.all(
                                      color: isDark ? const Color(0xFFBD68FF) : const Color(0xFF7B2CBF),
                                      width: 1.4,
                                    )
                                  : (isDark ? Border.all(color: const Color(0xFF28354E)) : null),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (canMarkDone) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          size: 16,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Waktu sesi telah berakhir. Harap lakukan validasi kehadiran agar dapat mengisi materi/PR.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                Row(
                                   crossAxisAlignment: CrossAxisAlignment.center,
                                   children: [
                                     Expanded(
                                       child: Text(
                                         '${session.sessionStart.day}/${session.sessionStart.month} '
                                         '${session.sessionStart.hour.toString().padLeft(2, '0')}:${session.sessionStart.minute.toString().padLeft(2, '0')}'
                                         ' - ${session.sessionEnd.hour.toString().padLeft(2, '0')}:${session.sessionEnd.minute.toString().padLeft(2, '0')}',
                                         style: TextStyle(
                                           fontWeight: FontWeight.w700,
                                           color: isDark ? Colors.white : Colors.black87,
                                         ),
                                       ),
                                     ),
                                     if (session.status == BookingSessionStatus.scheduled) ...[
                                       IconButton(
                                         constraints: const BoxConstraints(),
                                         padding: EdgeInsets.zero,
                                         icon: const Icon(
                                           FluentIcons.calendar_add_20_regular,
                                           color: Color(0xFFFF1377),
                                           size: 20,
                                         ),
                                         tooltip: 'Tambah ke Google Calendar',
                                         onPressed: () {
                                           CalendarSyncHelper.addToGoogleCalendar(
                                             title: 'Sesi Ajar ${item.subject} - Murid: ${item.studentName}',
                                             startTime: session.sessionStart,
                                             endTime: session.sessionEnd,
                                             description: 'Sesi mengajar EduConnect mata pelajaran ${item.subject} untuk murid ${item.studentName}. Catatan: ${item.message}',
                                             location: 'Online Classroom - EduConnect',
                                           );
                                         },
                                       ),
                                       const SizedBox(width: 8),
                                     ],
                                     TutorStatusBadge.session(
                                       status: session.status,
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 4),
                                 if (item.meetingType == 'online' &&
                                     (session.status == BookingSessionStatus.inProgress ||
                                      session.status == BookingSessionStatus.donePendingConfirmation)) ...[
                                   const SizedBox(height: 8),
                                   SizedBox(
                                     width: double.infinity,
                                     child: FilledButton.icon(
                                       onPressed: () {
                                         Navigator.push(
                                           context,
                                           MaterialPageRoute(
                                             builder: (_) => VirtualClassroomPage(
                                               subject: item.subject,
                                               partnerName: displayStudentName,
                                             ),
                                           ),
                                         );
                                       },
                                       icon: const Icon(Icons.class_outlined, size: 16),
                                       label: const Text(
                                         'Masuk Ruang Kelas',
                                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                       ),
                                       style: FilledButton.styleFrom(
                                         backgroundColor: const Color(0xFF4B176E),
                                         padding: const EdgeInsets.symmetric(vertical: 8),
                                         shape: RoundedRectangleBorder(
                                           borderRadius: BorderRadius.circular(8),
                                         ),
                                       ),
                                     ),
                                   ),
                                 ] else if (item.meetingType == 'offline') ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Color(0xFFE11D48)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Tatap Muka: ${item.meetingLocation}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    _GpsGeofencingWidget(locationName: item.meetingLocation),
                                  ],
                                Builder(
                                  builder: (context) {
                                    if (learningRecord == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (learningRecord.materialSummary
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              'Materi: ${learningRecord.materialSummary}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          if (learningRecord.materialNotes
                                              .trim()
                                              .isNotEmpty)
                                            Text(
                                              'Catatan: ${learningRecord.materialNotes}',
                                            ),
                                          if (learningRecord.hasHomework) ...[
                                            Text(
                                              'PR: ${learningRecord.homeworkTitle}',
                                            ),
                                            Text(
                                              'Status PR: ${learningRecord.homeworkStatus.label}',
                                            ),
                                            if (learningRecord.studentSubmission.trim().isNotEmpty) ...[
                                              Builder(
                                                builder: (context) {
                                                  final submission = learningRecord.studentSubmission;
                                                  final hasOriginalImage = submission.startsWith('[IMAGE]:');
                                                  String? originalImagePath;
                                                  String? correctedImagePath;
                                                  String actualText = submission;

                                                  if (hasOriginalImage) {
                                                    final lines = submission.split('\n');
                                                    originalImagePath = lines[0].substring('[IMAGE]:'.length);
                                                    if (lines.length > 1 && lines[1].startsWith('[CORRECTED]:')) {
                                                      correctedImagePath = lines[1].substring('[CORRECTED]:'.length);
                                                      actualText = lines.skip(2).join('\n');
                                                    } else {
                                                      actualText = lines.skip(1).join('\n');
                                                    }
                                                  }

                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (actualText.trim().isNotEmpty)
                                                        Text('Jawaban murid: $actualText', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                      if (originalImagePath != null) ...[
                                                        const SizedBox(height: 8),
                                                        const Text('Lampiran PR Murid:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 4),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: Image.file(
                                                            File(originalImagePath),
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ],
                                                      if (correctedImagePath != null) ...[
                                                        const SizedBox(height: 8),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                                            const SizedBox(width: 4),
                                                            const Text('Koreksi Gambar Tutor:', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: Image.file(
                                                            File(correctedImagePath),
                                                            height: 100,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (request != null) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      TutorStatusBadge.custom(
                                        label:
                                            'Request ${request.requestType} menunggu persetujuan',
                                        background: const Color(0xFFF2E8FF),
                                        foreground: const Color(0xFF7B2CBF),
                                      ),
                                    ],
                                  ),
                                  if (request.targetUid == currentUid) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                                    try {
                                                      await ref
                                                          .read(bookingControllerProvider)
                                                          .respondSessionChangeRequest(
                                                            requestId: request.id,
                                                            approved: false,
                                                          );
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Permintaan ditolak.')),
                                                      );
                                                    } catch (e) {
                                                      if (!context.mounted) return;
                                                      final errorMsg = e.toString().replaceAll('PostgrestException:', '').trim();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Gagal menolak permintaan: $errorMsg'),
                                                          backgroundColor: Colors.red.shade800,
                                                        ),
                                                      );
                                                    }
                                                  },
                                            child: const Text('Tolak'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                                    try {
                                                      await ref
                                                          .read(bookingControllerProvider)
                                                          .respondSessionChangeRequest(
                                                            requestId: request.id,
                                                            approved: true,
                                                          );
                                                      if (!context.mounted) return;
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Permintaan disetujui.')),
                                                      );
                                                    } catch (e) {
                                                      if (!context.mounted) return;
                                                      final errorMsg = e.toString().replaceAll('PostgrestException:', '').trim();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Gagal menyetujui permintaan: $errorMsg'),
                                                          backgroundColor: Colors.red.shade800,
                                                        ),
                                                      );
                                                    }
                                                  },
                                            child: const Text('Setujui'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                if (canStartSession) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              try {
                                                // Trigger Supabase Realtime calling event to student's background listener
                                                 final callingChannelName = 'student_calls_${item.studentUid}';
                                                 final callingChannel = Supabase.instance.client.channel(callingChannelName);
                                                 callingChannel.subscribe((status, error) async {
                                                   if (status == RealtimeSubscribeStatus.subscribed) {
                                                     await callingChannel.sendBroadcastMessage(
                                                       event: 'call_start',
                                                       payload: {
                                                         'subject': item.subject,
                                                         'tutor_name': ref.read(userProfileProvider(item.tutorUid)).valueOrNull?.displayName ?? item.tutorName,
                                                         'booking_id': item.id,
                                                       },
                                                     );
                                                   }
                                                 });

                                                 await ref
                                                     .read(
                                                       bookingControllerProvider,
                                                     )
                                                     .markSessionStartedByTutor(
                                                       session.id,
                                                     );
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Sesi dimulai! Jangan lupa tandai selesai setelah kelas berakhir.',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Gagal memulai sesi: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      icon: const Icon(
                                        FluentIcons.play_circle_24_regular,
                                      ),
                                      label: const Text('Mulai Sesi'),
                                    ),
                                  ),
                                ],
                                if (canMarkDone) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                                  final success = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => _UploadSessionProofDialog(
                                                      sessionId: session.id,
                                                    ),
                                                  );
                                                  if (success == true && context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Pertemuan berhasil ditandai selesai dengan foto bukti dan sekarang menunggu konfirmasi murid.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          child: const Text(
                                            'Tandai Sesi Selesai',
                                          ),
                                        ),
                                      ),
                                      if (canMarkStudentNoShow) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: isLoading
                                                ? null
                                                : () async {
                                                    try {
                                                      await ref
                                                          .read(
                                                            bookingControllerProvider,
                                                          )
                                                          .markStudentNoShow(
                                                            session.id,
                                                          );
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Sesi berhasil ditandai sebagai murid tidak hadir.',
                                                          ),
                                                        ),
                                                      );
                                                    } on Exception catch (
                                                      error
                                                    ) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Gagal memperbarui kehadiran murid. Coba lagi. ${error.toString()}',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                            icon: const Icon(
                                              FluentIcons
                                                  .person_prohibited_24_regular,
                                            ),
                                            label: const Text(
                                              'Murid Tidak Hadir',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                                if (session.status ==
                                    BookingSessionStatus.disputedPending) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _showDisputeSupportDialog(context),
                                          icon: const Icon(Icons.support_agent),
                                          label: const Text('Hubungi CS'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                                  try {
                                                    await ref
                                                        .read(
                                                          bookingControllerProvider,
                                                        )
                                                        .resolveDisputeByTutor(
                                                          session.id,
                                                        );
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Dispute berhasil ditutup dan status sesi diperbarui.',
                                                        ),
                                                      ),
                                                    );
                                                  } on Exception catch (error) {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Gagal menutup dispute. Coba lagi sebentar lagi. ${error.toString()}',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(
                                            FluentIcons.certificate_24_regular,
                                          ),
                                          label: const Text('Tutup Dispute'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (canRequestChange) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: isLoading
                                              ? null
                                              : () => _showCancelRequestDialog(
                                                  context: context,
                                                  ref: ref,
                                                  session: session,
                                                ),
                                          child: const Text('Ajukan Batal'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: isLoading
                                              ? null
                                              : () =>
                                                    _showRescheduleRequestDialog(
                                                      context: context,
                                                      ref: ref,
                                                      session: session,
                                                      durationMinutes:
                                                          item.durationMinutes,
                                                    ),
                                          child: const Text(
                                            'Ajukan Reschedule',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () {
                                                final isAllowed = session.status ==
                                                        BookingSessionStatus
                                                            .donePendingConfirmation ||
                                                    session.status ==
                                                        BookingSessionStatus
                                                            .confirmed ||
                                                    session.status ==
                                                        BookingSessionStatus
                                                            .disputedResolved;
                                                if (!isAllowed) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Harap tandai sesi selesai terlebih dahulu sebelum mengisi materi atau PR.',
                                                      ),
                                                      behavior:
                                                          SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                _showLearningRecordDialog(
                                                  context: context,
                                                  ref: ref,
                                                  booking: item,
                                                  sessionId: session.id,
                                                  existing: learningRecord,
                                                );
                                              },
                                        icon: const Icon(
                                          FluentIcons.book_24_regular,
                                        ),
                                        label: const Text('Materi & PR'),
                                      ),
                                    ),
                                    if (learningRecord != null &&
                                        learningRecord.homeworkStatus ==
                                            HomeworkStatus.submitted) ...[
                                      Builder(
                                        builder: (context) {
                                          final submission = learningRecord.studentSubmission;
                                          final hasImage = submission.startsWith('[IMAGE]:');
                                          if (!hasImage) return const SizedBox.shrink();

                                          final lines = submission.split('\n');
                                          final originalImagePath = lines[0].substring('[IMAGE]:'.length);

                                          return Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: ElevatedButton.icon(
                                              onPressed: () async {
                                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                                final resultPath = await Navigator.push<String>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => HomeworkCorrectionPage(
                                                      imagePath: originalImagePath,
                                                      sessionId: session.id,
                                                    ),
                                                  ),
                                                );

                                                if (!context.mounted) return;
                                                if (resultPath != null) {
                                                  final updatedSubmission = '[IMAGE]:$originalImagePath\n[CORRECTED]:$resultPath\n${lines.skip(lines.length > 1 && lines[1].startsWith('[CORRECTED]:') ? 2 : 1).join('\n')}';
                                                  
                                                  await Supabase.instance.client
                                                      .from('session_learning_records')
                                                      .update({'student_submission': updatedSubmission})
                                                      .eq('session_id', session.id);
                                                  
                                                  if (!context.mounted) return;
                                                  final success = await showDialog<bool>(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (_) => _ReviewHomeworkDialog(sessionId: session.id),
                                                  );
                                                  if (success == true) {
                                                    scaffoldMessenger.showSnackBar(
                                                      const SnackBar(content: Text('Koreksi gambar berhasil disimpan dan PR telah direview dengan nilai!')),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Koreksi Gambar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFF1377),
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.tonalIcon(
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                                  final success = await showDialog<bool>(
                                                    context: context,
                                                    builder: (_) => _ReviewHomeworkDialog(sessionId: session.id),
                                                  );
                                                  if (success == true && context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'PR berhasil ditandai sebagai sudah direview dengan nilai.',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          icon: const Icon(Icons.task_alt),
                                          label: const Text('Review PR'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        final showFilteredOnly = widget.focusedSessionId != null &&
                            widget.focusedSessionId!.isNotEmpty &&
                            !_clearedBookingFilters.contains(item.id);

                        if (showFilteredOnly) {
                          final shortlist = _selectDisplayedSessions(
                            sessions,
                            widget.focusedSessionId,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...shortlist.map(buildSessionCard),
                              if (sessions.length > 1)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _clearedBookingFilters.add(item.id);
                                      });
                                    },
                                    icon: const Icon(Icons.unfold_more, size: 16),
                                    label: const Text('Tampilkan Semua Sesi'),
                                  ),
                                ),
                            ],
                          );
                        }

                        final now = DateTime.now();
                        final upcoming = sessions.where((s) =>
                            s.status == BookingSessionStatus.inProgress ||
                            s.status == BookingSessionStatus.donePendingConfirmation ||
                            s.sessionEnd.isAfter(now)).toList()
                          ..sort((a, b) => a.sessionStart.compareTo(b.sessionStart));

                        final past = sessions.where((s) =>
                            s.status == BookingSessionStatus.confirmed ||
                            s.status == BookingSessionStatus.disputedResolved ||
                            s.status == BookingSessionStatus.studentNoShow ||
                            s.status == BookingSessionStatus.tutorNoShow ||
                            s.status.name.startsWith('cancelled') ||
                            s.sessionEnd.isBefore(now)).toList()
                          ..sort((a, b) => b.sessionStart.compareTo(a.sessionStart));

                        final isExpanded = _expandedPastSessions.contains(item.id);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (upcoming.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.event_outlined, size: 16, color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF4B176E)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sesi Mendatang',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF4B176E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...upcoming.map(buildSessionCard),
                            ],
                            if (past.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedPastSessions.remove(item.id);
                                    } else {
                                      _expandedPastSessions.add(item.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.history, size: 16, color: isDark ? Colors.white60 : Colors.black54),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sesi Selesai / Terlewat (${past.length})',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        isExpanded ? Icons.expand_less : Icons.expand_more,
                                        size: 18,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isExpanded) ...past.map(buildSessionCard),
                            ],
                          ],
                        );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: AppLoadingState(
                        message: 'Memuat sesi booking...',
                        fullScreen: false,
                      ),
                    ),
                    error: (error, _) => AppErrorState(
                      message: 'Gagal memuat sesi booking.',
                      detail: error.toString(),
                      onRetry: () =>
                          ref.invalidate(bookingSessionsProvider(item.id)),
                      fullScreen: false,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.status == BookingStatus.pending)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => onRespond(
                                    bookingId: item.id,
                                    status: BookingStatus.rejected,
                                    successMessage: 'Booking ditolak.',
                                  ),
                            child: const Text('Tolak'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: isLoading
                                ? null
                                : () => onRespond(
                                    bookingId: item.id,
                                    status: BookingStatus.awaitingPayment,
                                    successMessage:
                                        'Booking diterima. Menunggu pembayaran murid.',
                                  ),
                            child: const Text('Terima'),
                          ),
                        ),
                      ],
                    )
                  else if (item.status == BookingStatus.paid)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking akan selesai otomatis saat seluruh sesi sudah mencapai status final.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.pushNamed(
                            ChatPage.routeName,
                            pathParameters: {'bookingId': item.id},
                          ),
                          icon: const Icon(FluentIcons.chat_24_regular),
                          label: const Text('Chat'),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => context.pushNamed(
                        ChatPage.routeName,
                        pathParameters: {'bookingId': item.id},
                      ),
                      icon: const Icon(FluentIcons.chat_24_regular),
                      label: const Text('Buka Chat'),
                    ),
                ],
              ),
            ),
          ).animate().fade(delay: (index * 50).ms, duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut);
        }),
      ],
    );
  }
}

class _TutorActionSummaryCard extends StatelessWidget {
  const _TutorActionSummaryCard({
    required this.totalCount,
    required this.pendingCount,
    required this.waitingPaymentCount,
    required this.activeCount,
  });

  final int totalCount;
  final int pendingCount;
  final int waitingPaymentCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(18),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Butuh Aksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pendingCount == 0 && waitingPaymentCount == 0
                ? 'Semua booking cukup terkendali sekarang. Kamu bisa fokus ke sesi aktif.'
                : 'Prioritaskan permintaan baru dan booking yang sedang menunggu pembayaran murid.',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TutorMetricPill(
                label: 'Total',
                value: '$totalCount',
                background: const Color(0xFFE5ECF0),
                foreground: const Color(0xFF21425B),
              ),
              TutorMetricPill(
                label: 'Permintaan',
                value: '$pendingCount',
                background: const Color(0xFFFFE9D5),
                foreground: const Color(0xFF9A4D00),
              ),
              TutorMetricPill(
                label: 'Menunggu Bayar',
                value: '$waitingPaymentCount',
                background: const Color(0xFFF7DCE0),
                foreground: const Color(0xFFA6334A),
              ),
              TutorMetricPill(
                label: 'Aktif',
                value: '$activeCount',
                background: const Color(0xFFE0F2E7),
                foreground: const Color(0xFF206A42),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090D16) : const Color(0xFFF7F9FF),
        borderRadius: BorderRadius.circular(12),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF655C74),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF191622),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsGeofencingWidget extends StatefulWidget {
  const _GpsGeofencingWidget({
    required this.locationName,
  });

  final String locationName;

  @override
  State<_GpsGeofencingWidget> createState() => _GpsGeofencingWidgetState();
}

class _GpsGeofencingWidgetState extends State<_GpsGeofencingWidget> {
  bool _isLoading = false;
  bool _isVerified = false;
  String _message = 'Lokasi les offline belum terverifikasi GPS';

  Future<void> _verifyLocation() async {
    setState(() {
      _isLoading = true;
      _message = 'Mengakses GPS...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Izin akses lokasi (GPS) ditolak oleh pengguna.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      double targetLat = -6.2088;
      double targetLng = 106.8456;
      if (widget.locationName.toLowerCase().contains('cafe') || widget.locationName.toLowerCase().contains('mawar')) {
        targetLat = -6.2100;
        targetLng = 106.8460;
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );

      setState(() {
        _isVerified = true;
        _isLoading = false;
        if (distance <= 100) {
          _message = 'Verifikasi GPS Sukses! Anda berada di lokasi les offline (${distance.round()}m).';
        } else {
          _message = 'GPS Terdeteksi (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}). '
              'Jarak: ${distance.round()}m. Status: Terverifikasi (Mode Demo Aktif).';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Gagal verifikasi GPS: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isVerified
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFECFDF5))
            : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFFF7ED)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isVerified
              ? (isDark ? const Color(0xFF059669) : const Color(0xFF10B981))
              : (isDark ? const Color(0xFFD97706) : const Color(0xFFFDBA74)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isVerified ? Icons.verified_user : Icons.gpp_maybe_outlined,
                color: _isVerified
                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
                    : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B)),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isVerified ? 'Kehadiran Terverifikasi GPS' : 'Verifikasi Kehadiran Offline',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isVerified
                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                        : (isDark ? const Color(0xFFFFD3A3) : const Color(0xFF9A3412)),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _message,
            style: TextStyle(
              color: _isVerified
                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF047857))
                  : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFC2410C)),
              fontSize: 12,
            ),
          ),
          if (!_isVerified) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _verifyLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed, size: 14),
                label: const Text('Verifikasi GPS Sekarang', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFC2410C),
                  side: BorderSide(color: isDark ? const Color(0xFFD97706) : const Color(0xFFFDBA74)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CorrectionStroke {
  CorrectionStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;
}

class HomeworkCorrectionPage extends StatefulWidget {
  const HomeworkCorrectionPage({
    super.key,
    required this.imagePath,
    required this.sessionId,
  });

  final String imagePath;
  final String sessionId;

  @override
  State<HomeworkCorrectionPage> createState() => _HomeworkCorrectionPageState();
}

class _HomeworkCorrectionPageState extends State<HomeworkCorrectionPage> {
  final List<CorrectionStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = const Color(0xFFFF1377);
  final double _selectedWidth = 4.0;
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _saveCorrection() async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas koreksi tidak ditemukan.');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/Koreksi_${widget.sessionId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        navigator.pop(); // pop loading
        navigator.pop(filePath); // return the path of annotated image
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // pop loading
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Gagal menyimpan koreksi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110E1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF19162A),
        foregroundColor: Colors.white,
        title: const Text('Koreksi Jawaban Murid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            tooltip: 'Simpan Koreksi',
            onPressed: _saveCorrection,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                _currentPoints = [details.localPosition];
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                _currentPoints.add(details.localPosition);
                              });
                            },
                            onPanEnd: (details) {
                              setState(() {
                                _strokes.add(CorrectionStroke(
                                  points: List.from(_currentPoints),
                                  color: _selectedColor,
                                  strokeWidth: _selectedWidth,
                                ));
                                _currentPoints = [];
                              });
                            },
                            child: CustomPaint(
                              painter: SimpleCanvasPainter(
                                strokes: _strokes,
                                currentPoints: _currentPoints,
                                currentColor: _selectedColor,
                                currentWidth: _selectedWidth,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF131024),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.removeLast()),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.clear()),
                ),
                const Spacer(),
                _buildColorOption(const Color(0xFFFF1377)),
                const SizedBox(width: 8),
                _buildColorOption(const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildColorOption(const Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return InkWell(
      onTap: () => setState(() => _selectedColor = color),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }
}

class SimpleCanvasPainter extends CustomPainter {
  SimpleCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  final List<CorrectionStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      paint.color = stroke.color;
      paint.strokeWidth = stroke.strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (currentPoints.length > 1) {
      paint.color = currentColor;
      paint.strokeWidth = currentWidth;
      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SimpleCanvasPainter oldDelegate) => true;
}

class _UploadSessionProofDialog extends ConsumerStatefulWidget {
  const _UploadSessionProofDialog({required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<_UploadSessionProofDialog> createState() => _UploadSessionProofDialogState();
}

class _UploadSessionProofDialogState extends ConsumerState<_UploadSessionProofDialog> {
  File? _imageFile;
  bool _isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1000,
    );
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
    });
  }

  Future<void> _submit() async {
    if (_imageFile == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(bookingControllerProvider).markSessionDoneByTutor(
        widget.sessionId,
        photoFile: _imageFile,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyelesaikan sesi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1B2336) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Bukti Sesi Belajar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF191622),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan ambil foto bersama murid saat les sebagai bukti kehadiran fisik sesi belajar.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                      onPressed: () => setState(() => _imageFile = null),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_imageFile == null || _isSaving) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B176E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Selesaikan Sesi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewHomeworkDialog extends ConsumerStatefulWidget {
  const _ReviewHomeworkDialog({required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<_ReviewHomeworkDialog> createState() => _ReviewHomeworkDialogState();
}

class _ReviewHomeworkDialogState extends ConsumerState<_ReviewHomeworkDialog> {
  final _feedbackController = TextEditingController();
  final _gradeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final gradeText = _gradeController.text.trim();
      final grade = gradeText.isEmpty ? null : int.tryParse(gradeText);
      final feedback = _feedbackController.text.trim();

      await ref.read(bookingControllerProvider).markHomeworkReviewed(
        sessionId: widget.sessionId,
        feedback: feedback,
        grade: grade,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1B2336) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Review Pekerjaan Rumah (PR)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF191622),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Berikan nilai dan catatan koreksi bimbingan belajar untuk murid.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nilai PR (0 - 100) (Opsional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gradeController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Masukkan nilai (misal: 95)',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark ? const BorderSide(color: Color(0xFF28354E)) : BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  final num = int.tryParse(val.trim());
                  if (num == null || num < 0 || num > 100) {
                    return 'Nilai harus berkisar antara 0 - 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Catatan / Feedback Koreksi (Wajib)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _feedbackController,
                maxLines: 3,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tulis evaluasi, saran belajar, atau koreksi...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: isDark ? const BorderSide(color: Color(0xFF28354E)) : BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Catatan koreksi wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4B176E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Kirim Review'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
