import 'dart:io';
import 'package:educonnect/features/home/domain/models/library_ebook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final ebookRepositoryProvider = Provider<EbookRepository>((ref) {
  return EbookRepository(Supabase.instance.client);
});

class EbookRepository {
  const EbookRepository(this._client);

  final SupabaseClient _client;

  Future<List<LibraryEbook>> getEbooks() async {
    final data = await _client
        .from('library_ebooks')
        .select('''
          *,
          tutor:tutor_uid (
            display_name
          )
        ''')
        .order('created_at', ascending: false);

    return data.map((json) {
      final tutor = json['tutor'] as Map<String, dynamic>? ?? {};
      return LibraryEbook.fromJson({
        ...json,
        'tutor_name': tutor['display_name'],
      });
    }).toList();
  }

  Future<List<LibraryEbook>> getMyEbooks(String tutorUid) async {
    final data = await _client
        .from('library_ebooks')
        .select()
        .eq('tutor_uid', tutorUid)
        .order('created_at', ascending: false);

    return data.map((json) => LibraryEbook.fromJson(json)).toList();
  }

  Future<void> uploadEbook({
    required String tutorUid,
    required String title,
    required String description,
    required File pdfFile,
    required String accentColorHex,
  }) async {
    // 1. Baca byte berkas untuk validasi keamanan sebelum unggah
    final fileBytes = await pdfFile.readAsBytes();
    
    // Validasi Ukuran Berkas (Maksimal 15MB)
    final double sizeMb = fileBytes.length / (1024 * 1024);
    if (sizeMb > 15.0) {
      throw Exception('Ukuran berkas melebihi batas maksimal 15MB (Ukuran file: ${sizeMb.toStringAsFixed(2)}MB).');
    }

    // Validasi Magic Bytes PDF (%PDF-)
    if (fileBytes.length < 4 ||
        fileBytes[0] != 0x25 || // '%'
        fileBytes[1] != 0x50 || // 'P'
        fileBytes[2] != 0x44 || // 'D'
        fileBytes[3] != 0x46) { // 'F'
      throw Exception('Format berkas tidak valid. Berkas harus merupakan dokumen PDF asli (Magic Bytes mismatch).');
    }

    // 2. Upload file ke Supabase Storage (bucket: ebooks)
    final fileName = '${tutorUid}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = 'uploads/$fileName';
    
    await _client.storage.from('ebooks').upload(
      filePath, 
      pdfFile,
      fileOptions: const FileOptions(contentType: 'application/pdf'),
    );

    // Dapatkan public URL
    final publicUrl = _client.storage.from('ebooks').getPublicUrl(filePath);

    // 3. Simpan metadata ke tabel library_ebooks
    await _client.from('library_ebooks').insert({
      'tutor_uid': tutorUid,
      'title': title.trim(),
      'description': description.trim(),
      'file_url': publicUrl,
      'file_size_mb': sizeMb,
      'format': 'PDF',
      'accent_color_hex': accentColorHex,
    });
  }
}
