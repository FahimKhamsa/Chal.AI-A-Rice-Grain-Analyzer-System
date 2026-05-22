// features/analysis/presentation/widgets/integrity_score_gauge.dart
// Circular arc gauge showing the integrity score percentage.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class IntegrityScoreGauge extends StatelessWidget {
  final double score; // 0–100

  const IntegrityScoreGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _GaugePainter(
            score: score, bgColor: cs.onSurface.withValues(alpha: 0.12)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.round()}',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                    color: AppTheme.healthyGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color bgColor;
  _GaugePainter({required this.score, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background arc
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppTheme.healthyGreen, Color(0xFF4ADE80)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 0.75,
      math.pi * 1.5 * (score / 100),
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.score != score;
}
