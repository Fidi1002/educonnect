import 'package:url_launcher/url_launcher.dart';

class CalendarSyncHelper {
  static String generateGoogleCalendarUrl({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String description,
    required String location,
  }) {
    // Format UTC times for Google Calendar: YYYYMMDDTHHmmSSZ
    final startUtc = startTime.toUtc();
    final endUtc = endTime.toUtc();
    
    final startStr = _formatDateTimeToUtcString(startUtc);
    final endStr = _formatDateTimeToUtcString(endUtc);
    
    final text = Uri.encodeComponent(title);
    final details = Uri.encodeComponent(description);
    final loc = Uri.encodeComponent(location);
    
    return 'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$text&dates=$startStr/$endStr&details=$details&location=$loc';
  }

  static Future<void> addToGoogleCalendar({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String description,
    required String location,
  }) async {
    final urlString = generateGoogleCalendarUrl(
      title: title,
      startTime: startTime,
      endTime: endTime,
      description: description,
      location: location,
    );
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _formatDateTimeToUtcString(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }
}
