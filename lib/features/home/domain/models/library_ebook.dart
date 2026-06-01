class LibraryEbook {
  const LibraryEbook({
    required this.id,
    required this.tutorUid,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileSizeMb,
    required this.format,
    required this.accentColorHex,
    required this.createdAt,
    required this.targetLevel,
    required this.scanStatus,
    this.tutorName,
    this.bookingId,
  });

  final String id;
  final String tutorUid;
  final String title;
  final String description;
  final String fileUrl;
  final double fileSizeMb;
  final String format;
  final String accentColorHex;
  final DateTime createdAt;
  final String targetLevel;
  final String scanStatus;
  final String? tutorName;
  final String? bookingId;

  factory LibraryEbook.fromJson(Map<String, dynamic> json) {
    return LibraryEbook(
      id: json['id'] as String? ?? '',
      tutorUid: json['tutor_uid'] as String? ?? '',
      title: json['title'] as String? ?? 'Tanpa Judul',
      description: json['description'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      fileSizeMb: (json['file_size_mb'] as num?)?.toDouble() ?? 0.0,
      format: json['format'] as String? ?? 'PDF',
      accentColorHex: json['accent_color_hex'] as String? ?? '#4B176E',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      targetLevel: json['target_level'] as String? ?? 'SD',
      scanStatus: json['scan_status'] as String? ?? 'clean',
      tutorName: json['tutor_name'] as String?,
      bookingId: json['booking_id'] as String?,
    );
  }
}
