import 'dart:convert';
import 'dart:io';
import 'package:educonnect/core/services/local_cache_service.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:flutter/foundation.dart';

class OfflineSyncService {
  OfflineSyncService._();

  static const String _queueKey = 'offline_sync_queue';

  static List<Map<String, dynamic>> getPendingOperations() {
    final box = LocalCacheService.box;
    final data = box?.get(_queueKey) as String?;
    if (data == null) {
      return [];
    }
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addOperation(String type, Map<String, dynamic> payload) async {
    final box = LocalCacheService.box;
    if (box == null) return;

    final queue = getPendingOperations();
    final newOp = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    queue.add(newOp);
    await box.put(_queueKey, jsonEncode(queue));
    debugPrint('Offline Operation added: $type');
  }

  static Future<void> removeOperation(String id) async {
    final box = LocalCacheService.box;
    if (box == null) return;

    final queue = getPendingOperations();
    queue.removeWhere((op) => op['id'] == id);
    await box.put(_queueKey, jsonEncode(queue));
  }

  static Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncPendingOperations(BookingController bookingController) async {
    if (!await hasInternet()) {
      return;
    }

    final queue = getPendingOperations();
    if (queue.isEmpty) {
      return;
    }

    debugPrint('Starting offline synchronization of ${queue.length} items...');

    for (final op in List<Map<String, dynamic>>.from(queue)) {
      final id = op['id'] as String;
      final type = op['type'] as String;
      final payload = Map<String, dynamic>.from(op['payload'] as Map);

      try {
        if (type == 'submit_homework') {
          await bookingController.submitHomework(
            sessionId: payload['sessionId'] as String,
            submissionText: payload['submissionText'] as String,
          );
        } else if (type == 'request_reschedule') {
          await bookingController.requestSessionReschedule(
            sessionId: payload['sessionId'] as String,
            proposedStart: DateTime.parse(payload['proposedStart'] as String),
            proposedEnd: DateTime.parse(payload['proposedEnd'] as String),
            reason: payload['reason'] as String,
          );
        } else if (type == 'request_cancel') {
          await bookingController.requestSessionCancel(
            sessionId: payload['sessionId'] as String,
            reason: payload['reason'] as String,
          );
        } else if (type == 'respond_change_request') {
          await bookingController.respondSessionChangeRequest(
            requestId: payload['requestId'] as String,
            approved: payload['approved'] as bool,
          );
        }
        await removeOperation(id);
        debugPrint('Successfully synced offline operation: $type');
      } catch (e) {
        debugPrint('Error syncing offline operation $type: $e');
      }
    }
  }
}
