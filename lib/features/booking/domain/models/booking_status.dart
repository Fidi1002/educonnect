enum BookingStatus {
  pending,
  awaitingPayment,
  paid,
  rejected,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.awaitingPayment:
        return 'awaiting_payment';
      case BookingStatus.paid:
        return 'paid';
      case BookingStatus.rejected:
        return 'rejected';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Menunggu';
      case BookingStatus.awaitingPayment:
        return 'Menunggu Pembayaran';
      case BookingStatus.paid:
        return 'Lunas';
      case BookingStatus.rejected:
        return 'Ditolak';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  static BookingStatus fromValue(String? value) {
    switch (value) {
      case 'awaiting_payment':
        return BookingStatus.awaitingPayment;
      case 'paid':
        return BookingStatus.paid;
      case 'rejected':
        return BookingStatus.rejected;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      default:
        return BookingStatus.pending;
    }
  }
}
