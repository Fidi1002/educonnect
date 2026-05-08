import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class StudentEbookPage extends StatelessWidget {
  const StudentEbookPage({super.key});

  static const routeName = 'student-ebooks';
  static const routePath = '/student/ebooks';

  @override
  Widget build(BuildContext context) {
    final books = <(String, String, Color)>[
      (
        'Strategi Belajar Efektif',
        'Panduan teknik belajar untuk siswa SMP/SMA',
        const Color(0xFF4B176E),
      ),
      (
        'Dasar Matematika Cepat',
        'Ringkasan rumus dan contoh soal praktis',
        const Color(0xFF0F766E),
      ),
      (
        'Sains Seru Sehari-hari',
        'Konsep IPA dalam kehidupan harian',
        const Color(0xFF9A6700),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('E-Book Perpustakaan')),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final item = books[index];
          return _EbookCard(
            title: item.$1,
            description: item.$2,
            accentColor: item.$3,
          );
        },
      ),
    );
  }
}

class _EbookCard extends StatelessWidget {
  const _EbookCard({
    required this.title,
    required this.description,
    required this.accentColor,
  });

  final String title;
  final String description;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background soft accent shape
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3D Folder Mock
                Container(
                  width: 72,
                  height: 96,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      FluentIcons.book_open_24_filled,
                      color: accentColor,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.3, // Mock progress
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '30%',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
