import 'dart:io';
import 'dart:ui' as ui;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawingStroke {
  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  final List<Offset> points;
  final Color color;
  final double strokeWidth;
}

class VirtualClassroomPage extends StatefulWidget {
  const VirtualClassroomPage({
    super.key,
    required this.subject,
    required this.partnerName,
  });

  final String subject;
  final String partnerName;

  static const routeName = 'virtual-classroom';

  @override
  State<VirtualClassroomPage> createState() => _VirtualClassroomPageState();
}

class _VirtualClassroomPageState extends State<VirtualClassroomPage> with TickerProviderStateMixin {
  // Video panel states
  bool _isMicOn = true;
  bool _isVideoOn = true;
  bool _isScreenShareOn = false;

  // Whiteboard drawing states
  final List<DrawingStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _selectedColor = const Color(0xFFFF1377);
  double _selectedWidth = 4.0;

  // Remote whiteboard drawing states
  List<Offset> _remoteCurrentPoints = [];
  Color _remoteColor = const Color(0xFFFF1377);
  double _remoteWidth = 4.0;

  // Supabase Realtime channel
  RealtimeChannel? _realtimeChannel;
  final GlobalKey _whiteboardKey = GlobalKey();

  // Animation controller for voice waves simulating live audio
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Setup Supabase Realtime channel for whiteboard collaborative drawing
    final channelName = 'classroom-${widget.subject.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    _realtimeChannel = Supabase.instance.client.channel(channelName);
    _realtimeChannel!.onBroadcast(
      event: 'draw',
      callback: (payload) {
        final type = payload['type'] as String?;
        if (type == 'start') {
          final point = payload['point'] as Map<String, dynamic>;
          final colorVal = payload['color'] as int;
          final widthVal = (payload['width'] as num).toDouble();
          setState(() {
            _remoteColor = Color(colorVal);
            _remoteWidth = widthVal;
            _remoteCurrentPoints = [Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble())];
          });
        } else if (type == 'update') {
          final point = payload['point'] as Map<String, dynamic>;
          setState(() {
            _remoteCurrentPoints.add(Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble()));
          });
        } else if (type == 'end') {
          setState(() {
            if (_remoteCurrentPoints.isNotEmpty) {
              _strokes.add(DrawingStroke(
                points: List.from(_remoteCurrentPoints),
                color: _remoteColor,
                strokeWidth: _remoteWidth,
              ));
              _remoteCurrentPoints.clear();
            }
          });
        } else if (type == 'undo') {
          setState(() {
            if (_strokes.isNotEmpty) {
              _strokes.removeLast();
            }
          });
        } else if (type == 'clear') {
          setState(() {
            _strokes.clear();
            _remoteCurrentPoints.clear();
          });
        }
      },
    );
    _realtimeChannel!.subscribe();
  }

  @override
  void dispose() {
    _waveController.dispose();
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  Future<void> _exportToPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final boundary = _whiteboardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Canvas papan tulis tidak ditemukan.');
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      pw.ThemeData theme;
      try {
        final fontRegular = await PdfGoogleFonts.robotoRegular();
        final fontBold = await PdfGoogleFonts.robotoBold();
        final fontItalic = await PdfGoogleFonts.robotoItalic();
        theme = pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        );
      } catch (_) {
        theme = pw.ThemeData();
      }

      final pdf = pw.Document(theme: theme);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Catatan Belajar Kelas Virtual: ${widget.subject}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Partner: ${widget.partnerName} • Tanggal: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(
                      pw.MemoryImage(pngBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final filePath = '${output.path}/Catatan_${widget.subject.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (mounted) Navigator.pop(context); // pop loading

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ekspor Berhasil'),
            content: Text('Catatan papan tulis berhasil diekspor sebagai berkas PDF di:\n$filePath'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // pop loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF110E1B), // Premium dark theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF19162A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelas Online: ${widget.subject}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Partner: ${widget.partnerName}',
              style: TextStyle(fontSize: 11, color: Colors.purple.shade200),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(FluentIcons.call_end_20_filled, color: Colors.red),
              label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.shade900.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return isLandscape
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildVideoFeeds(isLandscape)),
                    Container(width: 1, color: const Color(0xFF2D264D)),
                    Expanded(flex: 3, child: _buildWhiteboard(context)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(flex: 2, child: _buildVideoFeeds(isLandscape)),
                    Container(height: 1, color: const Color(0xFF2D264D)),
                    Expanded(flex: 3, child: _buildWhiteboard(context)),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildVideoFeeds(bool isLandscape) {
    return Container(
      color: const Color(0xFF151224),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: isLandscape
                ? Column(
                    children: [
                      Expanded(child: _buildVideoCard(widget.partnerName, false)),
                      const SizedBox(height: 10),
                      Expanded(child: _buildVideoCard('Anda', true)),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildVideoCard(widget.partnerName, false)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildVideoCard('Anda', true)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          // Call Controls Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCallControlBtn(
                icon: _isMicOn ? FluentIcons.mic_24_filled : FluentIcons.mic_off_24_filled,
                isActive: _isMicOn,
                onPressed: () => setState(() => _isMicOn = !_isMicOn),
              ),
              const SizedBox(width: 12),
              _buildCallControlBtn(
                icon: _isVideoOn ? FluentIcons.video_24_filled : FluentIcons.video_off_24_filled,
                isActive: _isVideoOn,
                onPressed: () => setState(() => _isVideoOn = !_isVideoOn),
              ),
              const SizedBox(width: 12),
              _buildCallControlBtn(
                icon: Icons.screen_share_rounded,
                isActive: _isScreenShareOn,
                onPressed: () => setState(() => _isScreenShareOn = !_isScreenShareOn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(String name, bool isLocal) {
    final showCamera = isLocal ? _isVideoOn : true;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D264D)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Live Video Simulation
          if (showCamera)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D1854), Color(0xFF131024)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(
                      FluentIcons.video_clip_24_filled,
                      color: Colors.purple.shade200,
                      size: 80,
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(
              child: Text(
                'Kamera Mati',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          
          // User Initial Avatar (if camera is off or overlay)
          if (!showCamera)
            Center(
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFF1377),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          
          // Name and Mute Overlays
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  if (isLocal && !_isMicOn) ...[
                    const SizedBox(width: 4),
                    const Icon(FluentIcons.mic_off_12_filled, color: Colors.red, size: 12),
                  ] else if (!isLocal) ...[
                    const SizedBox(width: 6),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          children: List.generate(3, (index) {
                            final double h = (index == 1 ? 8 : 4) + (_waveController.value * (index == 1 ? 8 : 12));
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 2,
                              height: h,
                              color: const Color(0xFF10B981),
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControlBtn({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4B176E) : const Color(0xFF1E1A33),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFFFF1377) : const Color(0xFF2D264D)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildWhiteboard(BuildContext context) {
    return Container(
      color: const Color(0xFF1A162B),
      child: Column(
        children: [
          // Whiteboard Header / Tools Row
          Container(
            color: const Color(0xFF131024),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(FluentIcons.board_24_filled, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Papan Tulis Kolaboratif',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                // Undo Button
                IconButton(
                  icon: const Icon(FluentIcons.arrow_undo_24_regular, color: Colors.white70, size: 20),
                  tooltip: 'Undo',
                  onPressed: _strokes.isEmpty
                      ? null
                      : () {
                          setState(() => _strokes.removeLast());
                          _realtimeChannel?.sendBroadcastMessage(
                            event: 'draw',
                            payload: {'type': 'undo'},
                          );
                        },
                ),
                // Clear Button
                IconButton(
                  icon: const Icon(FluentIcons.delete_24_regular, color: Colors.red, size: 20),
                  tooltip: 'Hapus Semua',
                  onPressed: _strokes.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _strokes.clear();
                            _remoteCurrentPoints.clear();
                          });
                          _realtimeChannel?.sendBroadcastMessage(
                            event: 'draw',
                            payload: {'type': 'clear'},
                          );
                        },
                ),
                // Export PDF Button
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.blueAccent, size: 20),
                  tooltip: 'Ekspor PDF',
                  onPressed: _exportToPdf,
                ),
              ],
            ),
          ),

          // Paint Canvas Area
          Expanded(
            child: Container(
              color: Colors.white, // Classic whiteboard clean color
              child: RepaintBoundary(
                key: _whiteboardKey,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _currentPoints = [details.localPosition];
                    });
                    _realtimeChannel?.sendBroadcastMessage(
                      event: 'draw',
                      payload: {
                        'type': 'start',
                        'point': {'x': details.localPosition.dx, 'y': details.localPosition.dy},
                        'color': _selectedColor.toARGB32(),
                        'width': _selectedWidth,
                      },
                    );
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _currentPoints.add(details.localPosition);
                    });
                    _realtimeChannel?.sendBroadcastMessage(
                      event: 'draw',
                      payload: {
                        'type': 'update',
                        'point': {'x': details.localPosition.dx, 'y': details.localPosition.dy},
                      },
                    );
                  },
                  onPanEnd: (details) {
                    setState(() {
                      _strokes.add(DrawingStroke(
                        points: List.from(_currentPoints),
                        color: _selectedColor,
                        strokeWidth: _selectedWidth,
                      ));
                      _currentPoints = [];
                    });
                    _realtimeChannel?.sendBroadcastMessage(
                      event: 'draw',
                      payload: {
                        'type': 'end',
                      },
                    );
                  },
                  child: CustomPaint(
                    painter: WhiteboardPainter(
                      strokes: _strokes,
                      currentPoints: _currentPoints,
                      currentColor: _selectedColor,
                      currentWidth: _selectedWidth,
                      remoteCurrentPoints: _remoteCurrentPoints,
                      remoteColor: _remoteColor,
                      remoteWidth: _remoteWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),

          // Color & Stroke Palette Control
          Container(
            color: const Color(0xFF131024),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Colors list selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorOption(const Color(0xFFFF1377)), // EduConnect Pink
                    _buildColorOption(const Color(0xFF7B2CBF)), // Purple
                    _buildColorOption(const Color(0xFF2563EB)), // Blue
                    _buildColorOption(const Color(0xFF10B981)), // Green
                    _buildColorOption(const Color(0xFF1E293B)), // Dark Slate
                  ],
                ),
                const SizedBox(height: 10),
                // Thickness Slider
                Row(
                  children: [
                    const Icon(FluentIcons.line_thickness_24_regular, color: Colors.white60, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFFF1377),
                          inactiveTrackColor: const Color(0xFF2D264D),
                          thumbColor: const Color(0xFFFF1377),
                          overlayColor: const Color(0xFFFF1377).withValues(alpha: 0.1),
                        ),
                        child: Slider(
                          min: 2.0,
                          max: 12.0,
                          value: _selectedWidth,
                          onChanged: (val) => setState(() => _selectedWidth = val),
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedWidth.round()}px',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return InkWell(
      onTap: () => setState(() => _selectedColor = color),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2.5)
              : Border.all(color: Colors.white30, width: 1),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  WhiteboardPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.remoteCurrentPoints,
    required this.remoteColor,
    required this.remoteWidth,
  });

  final List<DrawingStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final List<Offset> remoteCurrentPoints;
  final Color remoteColor;
  final double remoteWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw past strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      final points = stroke.points;
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Draw currently drawing stroke (local)
    if (currentPoints.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = currentWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }

    // Draw currently drawing stroke (remote)
    if (remoteCurrentPoints.length > 1) {
      final paint = Paint()
        ..color = remoteColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = remoteWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < remoteCurrentPoints.length - 1; i++) {
        canvas.drawLine(remoteCurrentPoints[i], remoteCurrentPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhiteboardPainter oldDelegate) {
    return true;
  }
}
