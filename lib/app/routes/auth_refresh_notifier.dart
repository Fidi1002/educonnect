import 'dart:async';

import 'package:educonnect/features/auth/domain/models/auth_user.dart';
import 'package:flutter/material.dart';

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<AppAuthUser?> authStateChanges) {
    _subscription = authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AppAuthUser?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

