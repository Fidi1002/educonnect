class AppNotification {
  const AppNotification({
    required this.id,
    required this.userUid,
    required this.actorUid,
    required this.category,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userUid;
  final String actorUid;
  final String category;
  final String title;
  final String body;
  final String targetType;
  final String targetId;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: (map['id'] as String?) ?? '',
      userUid: (map['user_uid'] as String?) ?? '',
      actorUid: (map['actor_uid'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'general',
      title: (map['title'] as String?) ?? '',
      body: (map['body'] as String?) ?? '',
      targetType: (map['target_type'] as String?) ?? 'session_change',
      targetId: (map['target_id'] as String?) ?? '',
      isRead: (map['is_read'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
