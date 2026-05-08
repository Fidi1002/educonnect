import 'dart:async';

import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/notifications/data/repositories/push_token_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    repository: ref.watch(pushTokenRepositoryProvider),
    client: ref.watch(supabaseClientProvider),
  );
});

class PushNotificationService {
  PushNotificationService({
    required PushTokenRepository repository,
    required SupabaseClient client,
  }) : _repository = repository,
       _client = client;

  final PushTokenRepository _repository;
  final SupabaseClient _client;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _firebaseReady = false;
  String? _lastKnownToken;

  bool get _isAndroidNative =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_isAndroidNative) {
      return;
    }

    if (!_firebaseReady) {
      await Firebase.initializeApp();
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
          .listen((token) {
            unawaited(_syncToken(token));
          });
      _firebaseReady = true;
    }
  }

  Future<void> syncCurrentUserToken() async {
    if (!_isAndroidNative) {
      return;
    }

    await initialize();

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _syncToken(token);
  }

  Future<void> markCurrentDeviceInactive() async {
    if (!_isAndroidNative) {
      return;
    }

    final token = _lastKnownToken;
    if (token == null || token.isEmpty) {
      return;
    }

    await _repository.deactivateDeviceToken(token);
  }

  Future<void> _syncToken(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return;
    }

    _lastKnownToken = token;
    await _repository.upsertDeviceToken(
      userUid: user.id,
      token: token,
      platform: 'android',
      deviceLabel: 'Android',
    );
  }
}
