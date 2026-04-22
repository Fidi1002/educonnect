class SessionChangeRequest {
  const SessionChangeRequest({
    required this.id,
    required this.sessionId,
    required this.bookingId,
    required this.requesterUid,
    required this.requesterRole,
    required this.targetUid,
    required this.requestType,
    required this.reason,
    required this.proposedStart,
    required this.proposedEnd,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String bookingId;
  final String requesterUid;
  final String requesterRole;
  final String targetUid;
  final String requestType;
  final String reason;
  final DateTime? proposedStart;
  final DateTime? proposedEnd;
  final String status;
  final DateTime createdAt;

  bool get isPending => status == 'pending';

  factory SessionChangeRequest.fromMap(Map<String, dynamic> map) {
    return SessionChangeRequest(
      id: (map['id'] as String?) ?? '',
      sessionId: (map['session_id'] as String?) ?? '',
      bookingId: (map['booking_id'] as String?) ?? '',
      requesterUid: (map['requester_uid'] as String?) ?? '',
      requesterRole: (map['requester_role'] as String?) ?? '',
      targetUid: (map['target_uid'] as String?) ?? '',
      requestType: (map['request_type'] as String?) ?? '',
      reason: (map['reason'] as String?) ?? '',
      proposedStart: DateTime.tryParse(
        map['proposed_start'] as String? ?? '',
      )?.toLocal(),
      proposedEnd: DateTime.tryParse(
        map['proposed_end'] as String? ?? '',
      )?.toLocal(),
      status: (map['status'] as String?) ?? 'pending',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
