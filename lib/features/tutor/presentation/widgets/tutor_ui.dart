import 'package:educonnect/features/booking/domain/models/booking_session_status.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:flutter/material.dart';

class TutorUi {
  static const Color ink = Color(0xFF4B176E);
  static const Color navy = Color(0xFF4B176E);
  static const Color pink = Color(0xFFFF1377);
  static const Color cream = Color(0xFFF7F9FF);
  static const Color lavender = Color(0xFFEAF2FF);
  static const Color mint = Color(0xFFE0F2E7);
  static const Color rose = Color(0xFFF7DCE0);
  static const Color peach = Color(0xFFFFE9D5);
  static const Color cloud = Color(0xFFE5ECF0);
  static const Color slate = Color(0xFFF3F4F6);

  static const LinearGradient heroGradientPrimary = LinearGradient(
    colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x10000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x11000000),
    blurRadius: 18,
    offset: Offset(0, 8),
  );

  static BoxDecoration elevatedCardDecoration({
    Color color = Colors.white,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [softShadow],
    );
  }

  static BoxDecoration raisedCardDecoration({
    Color color = Colors.white,
    double radius = 22,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [mediumShadow],
    );
  }

  static BoxDecoration softPanelDecoration({
    Color color = cream,
    double radius = 20,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

class TutorStatusBadge extends StatelessWidget {
  const TutorStatusBadge.booking({super.key, required BookingStatus status})
    : _bookingStatus = status,
      _sessionStatus = null,
      _label = null,
      _background = null,
      _foreground = null;

  const TutorStatusBadge.session({
    super.key,
    required BookingSessionStatus status,
  }) : _bookingStatus = null,
       _sessionStatus = status,
       _label = null,
       _background = null,
       _foreground = null;

  const TutorStatusBadge.custom({
    super.key,
    required String label,
    required Color background,
    required Color foreground,
  }) : _bookingStatus = null,
       _sessionStatus = null,
       _label = label,
       _background = background,
       _foreground = foreground;

  final BookingStatus? _bookingStatus;
  final BookingSessionStatus? _sessionStatus;
  final String? _label;
  final Color? _background;
  final Color? _foreground;

  @override
  Widget build(BuildContext context) {
    final style = switch ((_label, _bookingStatus, _sessionStatus)) {
      (final String label, _, _) => (label, _background!, _foreground!),
      (_, final BookingStatus bookingStatus, _) => _bookingStyle(bookingStatus),
      (_, _, final BookingSessionStatus sessionStatus) => _sessionStyle(
        sessionStatus,
      ),
      _ => throw StateError('TutorStatusBadge style belum lengkap.'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.$2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.$1,
        style: TextStyle(
          color: style.$3,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static (String, Color, Color) _bookingStyle(BookingStatus status) {
    return switch (status) {
      BookingStatus.pending => (
        status.label,
        TutorUi.peach,
        const Color(0xFF9A4D00),
      ),
      BookingStatus.awaitingPayment => (
        status.label,
        TutorUi.rose,
        const Color(0xFFA6334A),
      ),
      BookingStatus.paid => (
        status.label,
        TutorUi.mint,
        const Color(0xFF206A42),
      ),
      BookingStatus.completed => (status.label, TutorUi.cloud, TutorUi.ink),
      BookingStatus.rejected => (
        status.label,
        TutorUi.slate,
        const Color(0xFF4B5563),
      ),
      BookingStatus.cancelled => (
        status.label,
        const Color(0xFFF2E7E8),
        const Color(0xFF8A3A45),
      ),
    };
  }

  static (String, Color, Color) _sessionStyle(BookingSessionStatus status) {
    return switch (status) {
      BookingSessionStatus.scheduled => (
        'Terjadwal',
        const Color(0xFFE6F0F2),
        TutorUi.ink,
      ),
      BookingSessionStatus.inProgress => (
        'Sedang Berlangsung',
        const Color(0xFFE1F5FE),
        const Color(0xFF0277BD),
      ),
      BookingSessionStatus.donePendingConfirmation => (
        'Menunggu Konfirmasi',
        TutorUi.peach,
        const Color(0xFF9A4D00),
      ),
      BookingSessionStatus.confirmed => (
        'Terkonfirmasi',
        TutorUi.mint,
        const Color(0xFF206A42),
      ),
      BookingSessionStatus.disputedPending => (
        'Dispute',
        TutorUi.rose,
        const Color(0xFFA6334A),
      ),
      BookingSessionStatus.disputedResolved => (
        'Dispute Selesai',
        TutorUi.lavender,
        const Color(0xFF5B2B85),
      ),
      BookingSessionStatus.cancelledByStudent => (
        'Batal Murid',
        TutorUi.slate,
        const Color(0xFF4B5563),
      ),
      BookingSessionStatus.cancelledByTutor => (
        'Batal Tutor',
        TutorUi.slate,
        const Color(0xFF4B5563),
      ),
      BookingSessionStatus.cancelledEarly => (
        'Batal Early',
        TutorUi.slate,
        const Color(0xFF4B5563),
      ),
      BookingSessionStatus.cancelledLate => (
        'Batal Late',
        const Color(0xFFF2E7E8),
        const Color(0xFF8A3A45),
      ),
      BookingSessionStatus.rescheduled => (
        'Reschedule',
        const Color(0xFFE9EEF8),
        const Color(0xFF3257A8),
      ),
      BookingSessionStatus.studentNoShow => (
        'Murid No-show',
        const Color(0xFFF8E4CC),
        const Color(0xFFA05A00),
      ),
      BookingSessionStatus.tutorNoShow => (
        'Tutor No-show',
        const Color(0xFFF6D8DE),
        const Color(0xFFB3261E),
      ),
    };
  }
}

class TutorMetricPill extends StatelessWidget {
  const TutorMetricPill({
    super.key,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
