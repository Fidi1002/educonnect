class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderUid,
    required this.receiverUid,
    required this.body,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String bookingId;
  final String senderUid;
  final String receiverUid;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: (map['id'] as String?) ?? '',
      bookingId: (map['booking_id'] as String?) ?? '',
      senderUid: (map['sender_uid'] as String?) ?? '',
      receiverUid: (map['receiver_uid'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      readAt: DateTime.tryParse(map['read_at'] as String? ?? '')?.toLocal(),
    );
  }
}
