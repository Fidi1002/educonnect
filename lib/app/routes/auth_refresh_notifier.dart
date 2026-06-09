import 'package:flutter/material.dart';

class AuthRefreshNotifier extends ChangeNotifier {
  void triggerRefresh() {
    notifyListeners();
  }
}

