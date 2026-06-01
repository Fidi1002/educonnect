import 'package:educonnect/features/home/data/repositories/ebook_repository.dart';
import 'package:educonnect/features/home/domain/models/library_ebook.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PdfCacheState {
  const PdfCacheState({
    required this.isDownloaded,
    required this.isDownloading,
    required this.progress,
    required this.localPath,
  });

  final bool isDownloaded;
  final bool isDownloading;
  final double progress;
  final String localPath;

  factory PdfCacheState.notDownloaded() {
    return const PdfCacheState(
      isDownloaded: false,
      isDownloading: false,
      progress: 0.0,
      localPath: '',
    );
  }

  factory PdfCacheState.downloading(double progress) {
    return PdfCacheState(
      isDownloaded: false,
      isDownloading: true,
      progress: progress,
      localPath: '',
    );
  }

  factory PdfCacheState.downloaded(String localPath) {
    return PdfCacheState(
      isDownloaded: true,
      isDownloading: false,
      progress: 1.0,
      localPath: localPath,
    );
  }
}

final pdfCacheStateProvider = StateNotifierProvider.family<PdfCacheNotifier, PdfCacheState, LibraryEbook>((ref, ebook) {
  final repo = ref.watch(ebookRepositoryProvider);
  final notifier = PdfCacheNotifier(ebook, repo);
  notifier.checkCache();
  return notifier;
});

class PdfCacheNotifier extends StateNotifier<PdfCacheState> {
  PdfCacheNotifier(this._ebook, this._repository) : super(PdfCacheState.notDownloaded());

  final LibraryEbook _ebook;
  final EbookRepository _repository;

  Future<void> checkCache() async {
    if (_ebook.fileUrl.isEmpty) {
      state = PdfCacheState.notDownloaded();
      return;
    }
    try {
      final fileInfo = await DefaultCacheManager().getFileFromCache(_ebook.fileUrl);
      if (fileInfo != null && await fileInfo.file.exists()) {
        state = PdfCacheState.downloaded(fileInfo.file.path);
      } else {
        state = PdfCacheState.notDownloaded();
      }
    } catch (_) {
      state = PdfCacheState.notDownloaded();
    }
  }

  Future<void> download() async {
    if (_ebook.fileUrl.isEmpty) {
      return;
    }
    state = PdfCacheState.downloading(0.0);
    try {
      final downloadUrl = await _repository.getSignedUrl(_ebook.fileUrl);

      final fileStream = DefaultCacheManager().getFileStream(
        downloadUrl,
        key: _ebook.fileUrl,
        withProgress: true,
      );

      await for (final response in fileStream) {
        if (response is DownloadProgress) {
          state = PdfCacheState.downloading(response.progress ?? 0.0);
        } else if (response is FileInfo) {
          state = PdfCacheState.downloaded(response.file.path);
        }
      }
    } catch (_) {
      state = PdfCacheState.notDownloaded();
      rethrow;
    }
  }

  Future<void> clearCache() async {
    if (_ebook.fileUrl.isEmpty) {
      return;
    }
    try {
      await DefaultCacheManager().removeFile(_ebook.fileUrl);
      state = PdfCacheState.notDownloaded();
    } catch (_) {}
  }
}
