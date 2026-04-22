import 'package:flutter/material.dart';

class StudentEbookPage extends StatelessWidget {
  const StudentEbookPage({super.key});

  static const routeName = 'student-ebooks';
  static const routePath = '/student/ebooks';

  @override
  Widget build(BuildContext context) {
    final books = <(String, String)>[
      (
        'Strategi Belajar Efektif',
        'Panduan teknik belajar untuk siswa SMP/SMA',
      ),
      ('Dasar Matematika Cepat', 'Ringkasan rumus dan contoh soal praktis'),
      ('Sains Seru Sehari-hari', 'Konsep IPA dalam kehidupan harian'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('E-Book')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = books[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.menu_book)),
              title: Text(item.$1),
              subtitle: Text(item.$2),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
