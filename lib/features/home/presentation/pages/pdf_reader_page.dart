import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfReaderPage extends StatefulWidget {
  const PdfReaderPage({
    super.key,
    required this.title,
    required this.localPath,
    required this.accentColor,
  });

  final String title;
  final String localPath;
  final Color accentColor;

  static const routeName = 'pdf-reader';

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  PDFViewController? _pdfViewController;

  bool _isNightMode = false;
  bool _isSwipeHorizontal = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _isNightMode || theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF7F9FF),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            FluentIcons.arrow_left_24_regular,
            color: isDark ? Colors.white : const Color(0xFF4B176E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF4B176E),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mode Malam',
            icon: Icon(
              _isNightMode ? FluentIcons.weather_sunny_24_filled : FluentIcons.weather_moon_24_regular,
              color: isDark ? Colors.amber : const Color(0xFF4B176E),
            ),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
          IconButton(
            tooltip: 'Arah Gulir',
            icon: Icon(
              _isSwipeHorizontal ? FluentIcons.arrow_split_24_regular : FluentIcons.arrow_sync_24_regular,
              color: isDark ? Colors.white : const Color(0xFF4B176E),
            ),
            onPressed: () {
              setState(() {
                _isSwipeHorizontal = !_isSwipeHorizontal;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.localPath,
            enableSwipe: true,
            swipeHorizontal: _isSwipeHorizontal,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: _currentPage,
            fitPolicy: FitPolicy.WIDTH,
            preventLinkNavigation: false,
            nightMode: _isNightMode,
            onRender: (pages) {
              setState(() {
                _totalPages = pages ?? 0;
                _isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                _errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                _errorMessage = 'Error halaman $page: $error';
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              _pdfViewController = pdfViewController;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page ?? 0;
              });
            },
          ),
          if (!_isReady && _errorMessage.isEmpty)
            Center(
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      FluentIcons.warning_24_regular,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal memuat dokumen PDF',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isReady && _totalPages > 0
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Hal ${_currentPage + 1} dari $_totalPages',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      activeColor: widget.accentColor,
                      inactiveColor: widget.accentColor.withValues(alpha: 0.2),
                      value: _currentPage.toDouble(),
                      min: 0,
                      max: (_totalPages - 1).toDouble(),
                      divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                      label: 'Halaman ${_currentPage + 1}',
                      onChanged: (val) {
                        final targetPage = val.round();
                        _pdfViewController?.setPage(targetPage);
                      },
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
