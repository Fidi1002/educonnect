import 'dart:developer';

class AnalyticsService {
  const AnalyticsService();

  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    final payload = <String, Object>{'event': name};
    parameters?.forEach((key, value) {
      if (value == null) {
        return;
      }
      if (value is String || value is num || value is bool) {
        payload[key] = value;
      } else {
        payload[key] = value.toString();
      }
    });

    log('analytics_event', name: 'educonnect', error: payload);
  }
}
