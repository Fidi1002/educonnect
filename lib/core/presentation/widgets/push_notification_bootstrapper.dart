import 'dart:async';

import 'package:educonnect/app/routes/app_router.dart';
import 'package:educonnect/core/presentation/app_messenger.dart';
import 'package:educonnect/core/services/push_notification_service.dart';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:educonnect/features/auth/domain/models/app_user_role.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_session.dart';
import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/core/services/local_notification_service.dart';

class PushNotificationBootstrapper extends ConsumerStatefulWidget {
  const PushNotificationBootstrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrapper> createState() =>
      _PushNotificationBootstrapperState();
}

class _PushNotificationBootstrapperState
    extends ConsumerState<PushNotificationBootstrapper> {
  ProviderSubscription<AsyncValue<AppAuthUser?>>? _authSubscription;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  ProviderSubscription<AsyncValue<List<BookingSession>>>?
  _studentSessionsSubscription;
  ProviderSubscription<AsyncValue<List<BookingSession>>>?
  _tutorSessionsSubscription;

  bool get _supportsMobileNotificationBootstrap =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final service = ref.read(pushNotificationServiceProvider);
    Future<void>.microtask(() async {
      if (!_supportsMobileNotificationBootstrap) {
        return;
      }
      await service.initialize();
      await service.syncCurrentUserToken();
      _setupMessageListeners();
    });

    _authSubscription = ref.listenManual(authStateProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user == null) {
        if (_supportsMobileNotificationBootstrap) {
          unawaited(LocalNotificationService.cancelAll());
        }
        return;
      }
      if (_supportsMobileNotificationBootstrap) {
        unawaited(
          ref.read(pushNotificationServiceProvider).syncCurrentUserToken(),
        );
      }
    });

    if (_supportsMobileNotificationBootstrap) {
      _studentSessionsSubscription = ref.listenManual(
        myStudentSessionsProvider,
        (previous, next) {
          final sessions = next.valueOrNull;
          if (sessions == null) {
            return;
          }
          _scheduleLocalReminders(sessions, isTutor: false);
        },
      );

      _tutorSessionsSubscription = ref.listenManual(
        myTutorSessionsProvider,
        (previous, next) {
          final sessions = next.valueOrNull;
          if (sessions == null) {
            return;
          }
          _scheduleLocalReminders(sessions, isTutor: true);
        },
      );
    }
  }

  void _scheduleLocalReminders(
    List<BookingSession> sessions, {
    required bool isTutor,
  }) {
    for (final session in sessions) {
      if (session.status == BookingSessionStatus.scheduled &&
          session.sessionStart.isAfter(DateTime.now())) {
        final h1 = session.sessionStart.subtract(const Duration(hours: 1));
        if (h1.isAfter(DateTime.now())) {
          unawaited(
            LocalNotificationService.scheduleSessionReminder(
              id: session.id.hashCode ^ (isTutor ? 1 : 0),
              title: isTutor
                  ? 'Persiapan Mengajar (1 Jam)'
                  : 'Reminder Kelas (1 Jam)',
              body: isTutor
                  ? 'Sesi mengajar akan dimulai dalam 1 jam.'
                  : 'Sesi belajar akan dimulai dalam 1 jam. Siapkan materimu.',
              scheduledTime: h1,
            ),
          );
        }

        final m15 = session.sessionStart.subtract(const Duration(minutes: 15));
        if (m15.isAfter(DateTime.now())) {
          unawaited(
            LocalNotificationService.scheduleSessionReminder(
              id: (session.id.hashCode ^ (isTutor ? 1 : 0)) + 1,
              title: isTutor
                  ? 'Sesi Mengajar Segera Mulai'
                  : 'Sesi Belajar Segera Mulai',
              body: isTutor
                  ? 'Sesi mengajar dimulai dalam 15 menit.'
                  : 'Sesi belajar dimulai dalam 15 menit. Yuk siap-siap!',
              scheduledTime: m15,
            ),
          );
        }
      }
    }
  }

  void _setupMessageListeners() {
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationClick);

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationClick(message);
      }
    });

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${notification.title ?? 'Notifikasi Baru'}\n${notification.body ?? ''}',
            ),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () {
                rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                _handleNotificationClick(message);
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final router = ref.read(routerProvider);

    if (type == 'chat') {
      final bookingId = data['booking_id'];
      if (bookingId != null && bookingId.toString().isNotEmpty) {
        router.push('/chat/$bookingId');
      }
    } else if (type == 'call_start') {
      final bookingId = data['booking_id']?.toString() ?? '';
      final role = ref.read(currentUserProfileProvider).valueOrNull?.role;
      if (role == AppUserRole.student) {
        router.pushNamed(
          'student-bookings',
          queryParameters: {'bookingId': bookingId},
        );
      }
    } else if (type == 'booking_update') {
      final bookingId = data['booking_id']?.toString() ?? '';
      final sessionId = data['session_id']?.toString() ?? '';
      final role = ref.read(currentUserProfileProvider).valueOrNull?.role;

      if (role == AppUserRole.student) {
        router.pushNamed(
          'student-bookings',
          queryParameters: {'bookingId': bookingId, 'sessionId': sessionId},
        );
      } else if (role == AppUserRole.tutor) {
        router.pushNamed(
          'tutor-bookings',
          queryParameters: {'bookingId': bookingId, 'sessionId': sessionId},
        );
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _studentSessionsSubscription?.close();
    _tutorSessionsSubscription?.close();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
