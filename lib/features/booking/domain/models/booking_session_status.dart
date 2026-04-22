enum BookingSessionStatus {
  scheduled,
  donePendingConfirmation,
  confirmed,
  disputedPending,
  disputedResolved,
  cancelledByStudent,
  cancelledByTutor,
  cancelledEarly,
  cancelledLate,
  rescheduled,
  studentNoShow,
  tutorNoShow,
}

extension BookingSessionStatusX on BookingSessionStatus {
  String get value {
    switch (this) {
      case BookingSessionStatus.scheduled:
        return 'scheduled';
      case BookingSessionStatus.donePendingConfirmation:
        return 'done_pending_confirmation';
      case BookingSessionStatus.confirmed:
        return 'confirmed';
      case BookingSessionStatus.disputedPending:
        return 'disputed_pending';
      case BookingSessionStatus.disputedResolved:
        return 'disputed_resolved';
      case BookingSessionStatus.cancelledByStudent:
        return 'cancelled_by_student';
      case BookingSessionStatus.cancelledByTutor:
        return 'cancelled_by_tutor';
      case BookingSessionStatus.cancelledEarly:
        return 'cancelled_early';
      case BookingSessionStatus.cancelledLate:
        return 'cancelled_late';
      case BookingSessionStatus.rescheduled:
        return 'rescheduled';
      case BookingSessionStatus.studentNoShow:
        return 'student_no_show';
      case BookingSessionStatus.tutorNoShow:
        return 'tutor_no_show';
    }
  }

  String get label {
    switch (this) {
      case BookingSessionStatus.scheduled:
        return 'Terjadwal';
      case BookingSessionStatus.donePendingConfirmation:
        return 'Menunggu Konfirmasi';
      case BookingSessionStatus.confirmed:
        return 'Terkonfirmasi';
      case BookingSessionStatus.disputedPending:
        return 'Dispute (Menunggu Review)';
      case BookingSessionStatus.disputedResolved:
        return 'Dispute (Selesai)';
      case BookingSessionStatus.cancelledByStudent:
        return 'Batal oleh Murid';
      case BookingSessionStatus.cancelledByTutor:
        return 'Batal oleh Tutor';
      case BookingSessionStatus.cancelledEarly:
        return 'Dibatalkan (Early)';
      case BookingSessionStatus.cancelledLate:
        return 'Dibatalkan (Late)';
      case BookingSessionStatus.rescheduled:
        return 'Reschedule';
      case BookingSessionStatus.studentNoShow:
        return 'Murid Tidak Hadir';
      case BookingSessionStatus.tutorNoShow:
        return 'Tutor Tidak Hadir';
    }
  }

  static BookingSessionStatus fromValue(String? value) {
    switch (value) {
      case 'done_pending_confirmation':
        return BookingSessionStatus.donePendingConfirmation;
      case 'confirmed':
        return BookingSessionStatus.confirmed;
      case 'disputed_pending':
        return BookingSessionStatus.disputedPending;
      case 'disputed_resolved':
        return BookingSessionStatus.disputedResolved;
      case 'disputed':
        return BookingSessionStatus.disputedPending;
      case 'cancelled_by_student':
        return BookingSessionStatus.cancelledByStudent;
      case 'cancelled_by_tutor':
        return BookingSessionStatus.cancelledByTutor;
      case 'cancelled_early':
        return BookingSessionStatus.cancelledEarly;
      case 'cancelled_late':
        return BookingSessionStatus.cancelledLate;
      case 'rescheduled':
        return BookingSessionStatus.rescheduled;
      case 'student_no_show':
        return BookingSessionStatus.studentNoShow;
      case 'tutor_no_show':
        return BookingSessionStatus.tutorNoShow;
      case 'scheduled':
      default:
        return BookingSessionStatus.scheduled;
    }
  }
}
