import 'dart:io';
import 'package:educonnect/features/home/data/repositories/ebook_repository.dart';
import 'package:educonnect/features/home/domain/models/library_ebook.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ebooksProvider = FutureProvider<List<LibraryEbook>>((ref) async {
  final repo = ref.watch(ebookRepositoryProvider);
  return repo.getEbooks();
});

final myEbooksProvider = FutureProvider.family<List<LibraryEbook>, String>((ref, tutorUid) async {
  final repo = ref.watch(ebookRepositoryProvider);
  return repo.getMyEbooks(tutorUid);
});

final ebookControllerProvider = Provider<EbookController>((ref) {
  return EbookController(ref);
});

class EbookController {
  const EbookController(this._ref);

  final Ref _ref;

  Future<void> uploadEbook({
    required String tutorUid,
    required String title,
    required String description,
    required File pdfFile,
    required String accentColorHex,
    String? bookingId,
  }) async {
    final repo = _ref.read(ebookRepositoryProvider);
    await repo.uploadEbook(
      tutorUid: tutorUid,
      title: title,
      description: description,
      pdfFile: pdfFile,
      accentColorHex: accentColorHex,
      bookingId: bookingId,
    );

    // Refresh providers
    _ref.invalidate(ebooksProvider);
    _ref.invalidate(myEbooksProvider(tutorUid));
  }
}
