import 'package:flutter/material.dart';

class SetupRequiredPage extends StatelessWidget {
  const SetupRequiredPage({required this.errorMessage, super.key});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EduConnect Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi belum terkoneksi penuh ke Supabase.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Langkah lanjutan:'
              '\n1. Isi SUPABASE_URL via --dart-define'
              '\n2. Isi SUPABASE_ANON_KEY via --dart-define'
              '\n3. (Opsional) Isi SUPABASE_GOOGLE_REDIRECT_URL'
              '\n4. Isi MAPS_API_KEY di android/local.properties',
            ),
            const SizedBox(height: 16),
            Text(
              'Error detail: $errorMessage',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
