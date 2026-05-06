import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_download.dart';

class FullScreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String downloadFilename;

  const FullScreenImageViewer({
    super.key,
    required this.imageBytes,
    required this.downloadFilename,
  });

  static Future<void> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String downloadFilename,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => FullScreenImageViewer(
          imageBytes: imageBytes,
          downloadFilename: downloadFilename,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);
    try {
      await downloadImage(widget.imageBytes, widget.downloadFilename);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Pinch-to-zoom image ─────────────────────────────────────
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 6.0,
              child: Image.memory(widget.imageBytes),
            ),
          ),

          // ── Right-side legend ──────────────────────────────────────
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: _BoundingBoxLegend(),
            ),
          ),

          // ── Top action bar ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close
                  _CircleBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),

                  // Download
                  _DownloadBtn(
                    isDownloading: _isDownloading,
                    onTap: _download,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bounding box legend ───────────────────────────────────────────────────────
// Colors match exactly what cv_pipeline.py draws on the morphology image (RGB).

class _BoundingBoxLegend extends StatelessWidget {
  // Exact RGB values the backend paints — do NOT substitute AppTheme colours.
  static const _items = [
    (color: Color(0xFF00FF00), label: 'Healthy'),
    (color: Color(0xFFFFFF00), label: '¾ Broken'),
    (color: Color(0xFFFF0000), label: 'Half Broken'),
    (color: Color(0xFF0000FF), label: 'Discolored'),
    (color: Color(0xFFFF00FF), label: 'Impurity'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LEGEND',
            style: TextStyle(
              color: Colors.white.withAlpha(100),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _items.length; i++) ...[
            _LegendRow(color: _items[i].color, label: _items[i].label),
            if (i < _items.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withAlpha(60),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(24),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _DownloadBtn extends StatelessWidget {
  final bool isDownloading;
  final VoidCallback onTap;
  const _DownloadBtn(
      {required this.isDownloading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDownloading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isDownloading
              ? Colors.white.withAlpha(16)
              : AppTheme.healthyGreen.withAlpha(230),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDownloading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.download_rounded,
                  color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              isDownloading ? 'Saving…' : 'Download',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
