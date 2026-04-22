import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/auth/data/repositories/auth_repository.dart';
import 'package:educonnect/features/notifications/data/repositories/notification_repository.dart';
import 'package:educonnect/features/notifications/domain/models/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myNotificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream<List<AppNotification>>.empty();
  }
  return ref
      .watch(notificationRepositoryProvider)
      .watchMyNotifications(user.uid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(myNotificationsProvider).valueOrNull ?? const [];
  return items.where((item) => !item.isRead).length;
});

final notificationControllerProvider = Provider<NotificationController>((ref) {
  return NotificationController(ref);
});

class NotificationController {
  NotificationController(this._ref);

  final Ref _ref;

  Future<void> markAsRead(String id) {
    return _ref.read(notificationRepositoryProvider).markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    final userUid = _ref.read(authRepositoryProvider).currentUser?.uid;
    if (userUid == null || userUid.isEmpty) {
      return;
    }
    await _ref.read(notificationRepositoryProvider).markAllAsRead(userUid);
  }

  Future<String?> resolveBookingIdFromTarget({
    required String targetType,
    required String targetId,
  }) {
    return _ref
        .read(notificationRepositoryProvider)
        .resolveBookingIdFromTarget(targetType: targetType, targetId: targetId);
  }
}
