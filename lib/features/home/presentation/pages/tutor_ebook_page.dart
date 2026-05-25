import 'dart:io';
import 'package:educonnect/features/auth/application/auth_controller.dart';
import 'package:educonnect/features/home/application/ebook_controller.dart';
import 'package:educonnect/features/booking/application/booking_controller.dart';
import 'package:educonnect/features/booking/domain/models/booking_status.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class TutorEbookPage extends ConsumerWidget {
  const TutorEbookPage({super.key});

  static const routeName = 'tutor-ebooks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).value?.uid ?? '';
    final ebooksAsync = ref.watch(myEbooksProvider(currentUid));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FF),
      appBar: AppBar(
        title: const Text('Koleksi E-Book Saya'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _UploadEbookSheet(),
          );
        },
        backgroundColor: const Color(0xFF4B176E),
        icon: const Icon(
          FluentIcons.arrow_upload_24_regular,
          color: Colors.white,
        ),
        label: const Text(
          'Unggah Modul',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ebooksAsync.when(
        data: (ebooks) {
          if (ebooks.isEmpty) {
            return const Center(
              child: Text(
                'Anda belum mengunggah E-Book.\nYuk, bagikan ilmumu!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF718096), fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: ebooks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final ebook = ebooks[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(
                            ebook.accentColorHex.replaceAll('#', '0xFF'),
                          ),
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          FluentIcons.book_24_regular,
                          color: Color(
                            int.parse(
                              ebook.accentColorHex.replaceAll('#', '0xFF'),
                            ),
                          ),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ebook.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F0F7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${ebook.fileSizeMb.toStringAsFixed(1)} MB',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4B176E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat e-book: $e')),
      ),
    );
  }
}

class _UploadEbookSheet extends ConsumerStatefulWidget {
  const _UploadEbookSheet();

  @override
  ConsumerState<_UploadEbookSheet> createState() => _UploadEbookSheetState();
}

class _UploadEbookSheetState extends ConsumerState<_UploadEbookSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  File? _selectedFile;
  String? _selectedBookingId;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty || desc.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi form dan pilih file PDF.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final currentUid = ref.read(authStateProvider).value?.uid ?? '';
      await ref
          .read(ebookControllerProvider)
          .uploadEbook(
            tutorUid: currentUid,
            title: title,
            description: desc,
            pdfFile: _selectedFile!,
            accentColorHex: '#4B176E', // Default premium color
            bookingId: _selectedBookingId,
          );

      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('E-Book berhasil diunggah!')),
      );
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal mengunggah: $errorMessage')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myTutorBookingsProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Unggah Modul E-Book',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Judul Modul',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Deskripsi Modul',
              filled: true,
              fillColor: const Color(0xFFF7F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          bookingsAsync.when(
            data: (bookings) {
              final activeBookings = bookings
                  .where((b) =>
                      b.status == BookingStatus.paid ||
                      b.status == BookingStatus.completed)
                  .toList();

              return DropdownButtonFormField<String?>(
                initialValue: _selectedBookingId,
                decoration: InputDecoration(
                  labelText: 'Bagikan Ke (Opsional)',
                  filled: true,
                  fillColor: const Color(0xFFF7F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Semua Murid (Umum / Publik)'),
                  ),
                  ...activeBookings.map((b) => DropdownMenuItem<String?>(
                        value: b.id,
                        child: Text(
                          'Privat: ${b.studentName} - ${b.subject}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedBookingId = val;
                  });
                },
              );
            },
            loading: () => const SizedBox(
              height: 50,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(FluentIcons.document_pdf_24_regular),
            label: Text(
              _selectedFile == null
                  ? 'Pilih File PDF'
                  : 'File: ${_selectedFile!.path.split(Platform.pathSeparator).last}',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _upload,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Unggah Sekarang',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
