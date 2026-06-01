import 'package:educonnect/features/home/application/ebook_controller.dart';
import 'package:educonnect/features/home/application/pdf_cache_controller.dart';
import 'package:educonnect/features/home/domain/models/library_ebook.dart';
import 'package:educonnect/features/home/presentation/pages/pdf_reader_page.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentEbookPage extends ConsumerWidget {
  const StudentEbookPage({super.key});

  static const routeName = 'student-ebooks';
  static const routePath = '/student/ebooks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ebooksAsync = ref.watch(ebooksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            'Perpustakaan Ebook',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF4B176E),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4B176E), Color(0xFFFF1377)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4B176E).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.library_24_regular, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi Digital Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Akses ribuan materi belajar kapan saja dan di mana saja.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terakhir Dibaca',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
            ],
          ),
          const SizedBox(height: 12),
          ebooksAsync.when(
            data: (ebooks) {
              if (ebooks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Belum ada buku di perpustakaan.',
                      style: TextStyle(color: Color(0xFF667085)),
                    ),
                  ),
                );
              }
              return Column(
                children: ebooks.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _EbookCard(ebook: item),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat e-book: $e')),
          ),
        ],
      ),
    );
  }
}

class _EbookCard extends ConsumerWidget {
  const _EbookCard({
    required this.ebook,
  });

  final LibraryEbook ebook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheState = ref.watch(pdfCacheStateProvider(ebook));
    final accentColor = Color(int.parse(ebook.accentColorHex.replaceAll('#', '0xFF')));
    final meta = '${ebook.fileSizeMb.toStringAsFixed(1)} MB • ${ebook.format}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAF2FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withValues(alpha: 0.2)),
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
                    ebook.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4B176E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ebook.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9BA5B7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Oleh: ${ebook.tutorName ?? "EduConnect"}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9BA5B7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildScanStatusBadge(ebook.scanStatus),
                        ],
                      ),
                      const Spacer(),
                      _buildActionButton(context, ref, cacheState, accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanStatusBadge(String status) {
    Color color;
    IconData icon;
    String text;
    
    switch (status) {
      case 'infected':
        color = Colors.red.shade700;
        icon = Icons.gpp_bad;
        text = 'Karantina: Terinfeksi Virus';
        break;
      case 'pending':
        color = Colors.blue.shade700;
        icon = Icons.shield_outlined;
        text = 'Memindai Keamanan...';
        break;
      case 'clean':
      default:
        color = Colors.green.shade700;
        icon = Icons.verified;
        text = 'Terverifikasi Aman (ClamAV)';
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    PdfCacheState cacheState,
    Color accentColor,
  ) {
    if (ebook.scanStatus == 'infected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Diblokir',
          style: TextStyle(
            color: Colors.red.shade800,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (ebook.scanStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Text(
          'Memindai',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    if (cacheState.isDownloading) {
      return SizedBox(
        width: 36,
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: cacheState.progress > 0 ? cacheState.progress : null,
              color: accentColor,
              strokeWidth: 3,
            ),
            Text(
              '${(cacheState.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (cacheState.isDownloaded) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => PdfReaderPage(
                title: ebook.title,
                localPath: cacheState.localPath,
                accentColor: accentColor,
              ),
            ),
          );
        },
        icon: const Icon(FluentIcons.book_open_24_regular, size: 14),
        label: const Text(
          'Baca',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Default: Not Downloaded
    return OutlinedButton.icon(
      onPressed: () async {
        try {
          await ref.read(pdfCacheStateProvider(ebook).notifier).download();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengunduh e-book: $e')),
            );
          }
        }
      },
      icon: const Icon(FluentIcons.arrow_download_24_regular, size: 14),
      label: const Text(
        'Unduh',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
