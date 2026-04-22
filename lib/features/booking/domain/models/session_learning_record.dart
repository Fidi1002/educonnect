enum HomeworkStatus { none, assigned, submitted, reviewed }

extension HomeworkStatusX on HomeworkStatus {
  String get value {
    switch (this) {
      case HomeworkStatus.none:
        return 'none';
      case HomeworkStatus.assigned:
        return 'assigned';
      case HomeworkStatus.submitted:
        return 'submitted';
      case HomeworkStatus.reviewed:
        return 'reviewed';
    }
  }

  String get label {
    switch (this) {
      case HomeworkStatus.none:
        return 'Belum Ada PR';
      case HomeworkStatus.assigned:
        return 'PR Diberikan';
      case HomeworkStatus.submitted:
        return 'PR Dikumpulkan';
      case HomeworkStatus.reviewed:
        return 'PR Direview';
    }
  }

  static HomeworkStatus fromValue(String? value) {
    switch (value) {
      case 'assigned':
        return HomeworkStatus.assigned;
      case 'submitted':
        return HomeworkStatus.submitted;
      case 'reviewed':
        return HomeworkStatus.reviewed;
      case 'none':
      default:
        return HomeworkStatus.none;
    }
  }
}

class SessionLearningRecord {
  const SessionLearningRecord({
    required this.id,
    required this.bookingId,
    required this.sessionId,
    required this.studentUid,
    required this.tutorUid,
    required this.materialSummary,
    required this.materialNotes,
    required this.homeworkTitle,
    required this.homeworkDescription,
    required this.homeworkStatus,
    required this.studentSubmission,
    required this.homeworkAssignedAt,
    required this.submittedAt,
    required this.reviewedAt,
    required this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String sessionId;
  final String studentUid;
  final String tutorUid;
  final String materialSummary;
  final String materialNotes;
  final String homeworkTitle;
  final String homeworkDescription;
  final HomeworkStatus homeworkStatus;
  final String studentSubmission;
  final DateTime? homeworkAssignedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime updatedAt;

  bool get hasMaterial => materialSummary.trim().isNotEmpty;
  bool get hasHomework => homeworkStatus != HomeworkStatus.none;

  factory SessionLearningRecord.fromMap(Map<String, dynamic> map) {
    return SessionLearningRecord(
      id: (map['id'] as String?) ?? '',
      bookingId: (map['booking_id'] as String?) ?? '',
      sessionId: (map['session_id'] as String?) ?? '',
      studentUid: (map['student_uid'] as String?) ?? '',
      tutorUid: (map['tutor_uid'] as String?) ?? '',
      materialSummary: (map['material_summary'] as String?) ?? '',
      materialNotes: (map['material_notes'] as String?) ?? '',
      homeworkTitle: (map['homework_title'] as String?) ?? '',
      homeworkDescription: (map['homework_description'] as String?) ?? '',
      homeworkStatus: HomeworkStatusX.fromValue(
        map['homework_status'] as String?,
      ),
      studentSubmission: (map['student_submission'] as String?) ?? '',
      homeworkAssignedAt: DateTime.tryParse(
        map['homework_assigned_at'] as String? ?? '',
      )?.toLocal(),
      submittedAt: DateTime.tryParse(
        map['submitted_at'] as String? ?? '',
      )?.toLocal(),
      reviewedAt: DateTime.tryParse(
        map['reviewed_at'] as String? ?? '',
      )?.toLocal(),
      updatedAt:
          DateTime.tryParse(map['updated_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
