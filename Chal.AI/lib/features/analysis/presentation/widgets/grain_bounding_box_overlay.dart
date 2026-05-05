// features/analysis/presentation/widgets/grain_bounding_box_overlay.dart
// Draws mock color-coded bounding boxes / ellipses over the grain image.
// Visibility of each class is controlled by the filter chip state.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/analysis_result.dart';

class GrainBoundingBoxOverlay extends StatelessWidget {
  final GrainCounts counts;
  final bool showHealthy, showBroken, showDiscolored;

  const GrainBoundingBoxOverlay({
    super.key,
    required this.counts,
    required this.showHealthy,
    required this.showBroken,
    required this.showDiscolored,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BoundingBoxPainter(
        counts: counts,
        showHealthy: showHealthy,
        showBroken: showBroken,
        showDiscolored: showDiscolored,
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final GrainCounts counts;
  final bool showHealthy, showBroken, showDiscolored;

  _BoundingBoxPainter({
    required this.counts,
    required this.showHealthy,
    required this.showBroken,
    required this.showDiscolored,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(99);

    void drawBoxes(int n, Color color, bool visible) {
      if (!visible) return;
      final paint = Paint()
        ..color = color.withAlpha(180)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      final fillPaint = Paint()
        ..color = color.withAlpha(28)
        ..style = PaintingStyle.fill;

      final cap = math.min(n, 60);
      for (var i = 0; i < cap; i++) {
        final x = 16 + rng.nextDouble() * (size.width - 48);
        final y = 16 + rng.nextDouble() * (size.height - 40);
        final w = 20.0 + rng.nextDouble() * 10;
        final h = 8.0 + rng.nextDouble() * 4;
        final rect = Rect.fromCenter(
            center: Offset(x, y), width: w, height: h);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
        canvas.drawRRect(rrect, fillPaint);
        canvas.drawRRect(rrect, paint);
      }
    }

    drawBoxes(counts.healthy, AppTheme.healthyGreen, showHealthy);
    drawBoxes(counts.broken, AppTheme.brokenRed, showBroken);
    drawBoxes(counts.discolored, AppTheme.discoloredAmber, showDiscolored);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter old) =>
      old.showHealthy != showHealthy ||
      old.showBroken != showBroken ||
      old.showDiscolored != showDiscolored;
}
