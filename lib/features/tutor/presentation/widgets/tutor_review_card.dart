import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class TutorReviewCard extends StatelessWidget {
  const TutorReviewCard({
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.date,
    this.photoUrl,
    super.key,
  });

  final String studentName;
  final double rating;
  final String comment;
  final String date;
  final String? photoUrl;

  String _maskName(String name) {
    if (name.isEmpty) return 'Siswa Tersembunyi';
    final parts = name.trim().split(' ');
    final maskedParts = parts.map((part) {
      if (part.length <= 2) {
        return '${part[0]}*';
      }
      return part.substring(0, 2) + '*' * (part.length - 2);
    });
    return maskedParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final maskedStudentName = _maskName(studentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2336) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF28354E)) : null,
        boxShadow: isDark ? null : const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? const Color(0xFF28354E) : const Color(0xFFF3F0F7),
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Text(
                        maskedStudentName.isNotEmpty ? maskedStudentName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF4B176E),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maskedStudentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B2E1E) : const Color(0xFFFFF1C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.star_16_filled,
                      size: 12,
                      color: isDark ? const Color(0xFFFFB224) : const Color(0xFFA16207),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFFB224) : const Color(0xFFA16207),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
