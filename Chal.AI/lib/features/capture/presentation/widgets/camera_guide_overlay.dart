// features/capture/presentation/widgets/camera_guide_overlay.dart
// Semi-transparent guide overlay showing the user exactly where to frame
// the rice grains. Uses a CustomPainter for the dashed bounding box and
// corner "crosshair" indicators.
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';

class CameraGuideOverlay extends StatefulWidget {
  const CameraGuideOverlay({super.key});

  @override
  State<CameraGuideOverlay> createState() => _CameraGuideOverlayState();
}

class _CameraGuideOverlayState extends State<CameraGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxW = size.width * 0.75;
    final boxH = boxW * 0.6;

    return Stack(
      children: [
        // Dark vignette around the guide box
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _VignettePainter(
            boxW: boxW,
            boxH: boxH,
            cx: size.width / 2,
            cy: size.height * 0.38,
          ),
        ),

        // Animated guide box
        Center(
          child: Transform.translate(
            offset: Offset(0, -size.height * 0.06),
            child: AnimatedBuilder(
              animation: _opacity,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: CustomPaint(
                  size: Size(boxW, boxH),
                  painter: _GuideBoxPainter(),
                ),
              ),
            ),
          ),
        ),

        // Instruction label
        Positioned(
          bottom: size.height * 0.45,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.center_focus_strong_rounded,
                      color: Colors.white70, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Align grains within the frame',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cornerLength = size.width * 0.12;
    const radius = 16.0;

    // Corner brackets (solid, vivid green)
    final cornerPaint = Paint()
      ..color = AppTheme.healthyGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawArc(
        const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
        math.pi,
        math.pi / 2,
        false,
        cornerPaint);
    canvas.drawLine(
        const Offset(radius, 0), Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(
        const Offset(0, radius), Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
        -math.pi / 2,
        math.pi / 2,
        false,
        cornerPaint);
    canvas.drawLine(Offset(size.width - cornerLength, 0),
        Offset(size.width - radius, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, radius),
        Offset(size.width, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawArc(
        Rect.fromLTWH(
            0, size.height - radius * 2, radius * 2, radius * 2),
        math.pi / 2,
        math.pi / 2,
        false,
        cornerPaint);
    canvas.drawLine(Offset(radius, size.height),
        Offset(cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height - cornerLength),
        Offset(0, size.height - radius), cornerPaint);

    // Bottom-right
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2,
            size.height - radius * 2, radius * 2, radius * 2),
        0,
        math.pi / 2,
        false,
        cornerPaint);
    canvas.drawLine(
        Offset(size.width - cornerLength, size.height),
        Offset(size.width - radius, size.height),
        cornerPaint);
    canvas.drawLine(
        Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height - radius),
        cornerPaint);

    // Dashed center lines
    final dashPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _drawDashedLine(
        canvas,
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        dashPaint,
        6,
        4);
    _drawDashedLine(
        canvas,
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        dashPaint,
        6,
        4);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashLen, double gapLen) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final ux = dx / dist;
    final uy = dy / dist;
    double drawn = 0;
    bool drawing = true;
    while (drawn < dist) {
      final segLen =
          math.min(drawing ? dashLen : gapLen, dist - drawn);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * drawn, start.dy + uy * drawn),
          Offset(
              start.dx + ux * (drawn + segLen),
              start.dy + uy * (drawn + segLen)),
          paint,
        );
      }
      drawn += segLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _VignettePainter extends CustomPainter {
  final double boxW, boxH, cx, cy;
  _VignettePainter(
      {required this.boxW,
      required this.boxH,
      required this.cx,
      required this.cy});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: boxW, height: boxH),
      const Radius.circular(16),
    );
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withAlpha(100)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
