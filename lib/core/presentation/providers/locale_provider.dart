import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._prefs) : super(const Locale('id')) {
    _loadLocale();
  }

  final SharedPreferences _prefs;

  static const _key = 'app_locale';

  void _loadLocale() {
    final localeStr = _prefs.getString(_key);
    if (localeStr == 'en') {
      state = const Locale('en');
    } else {
      state = const Locale('id');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_key, locale.languageCode);
  }
}
