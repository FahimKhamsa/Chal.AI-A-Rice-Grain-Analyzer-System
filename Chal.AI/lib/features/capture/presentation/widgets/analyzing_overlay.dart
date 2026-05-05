// features/capture/presentation/widgets/analyzing_overlay.dart
// Full-screen overlay shown while AI analysis is running.
// Clean, minimal design — blurred backdrop + spinner + status text.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnalyzingOverlay extends StatefulWidget {
  const AnalyzingOverlay({super.key});

  @override
  State<AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<AnalyzingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _spinCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int _msgIndex = 0;

  static const _messages = [
    'Detecting grains...',
    'Classifying quality...',
    'Identifying variety...',
    'Building report...',
  ];

  @override
  void initState() {
    super.initState();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
          _fadeCtrl.forward(from: 0);
        }
      });
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut),
    );
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(180),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner
            SizedBox(
              width: 56,
              height: 56,
              child: RotationTransition(
                turns: _spinCtrl,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.healthyGreen,
                      width: 3,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.healthyGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Analyzing',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 10),

            FadeTransition(
              opacity: _fadeAnim,
              child: Text(
                _messages[_msgIndex],
                style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Step indicators
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_messages.length, (i) {
                final active = i == _msgIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: active
                        ? AppTheme.healthyGreen
                        : Colors.white.withAlpha(50),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
