// features/analysis/presentation/screens/analysis_result_screen.dart
// Screen B — Hero Analysis Result Screen.
// UX decisions:
//   • Image fills top ~50% with color-coded bounding box overlay
//   • Interactive filter chips toggle each grain class layer
//   • DraggableScrollableSheet shows the Summary Card on first drag
//   • Integrity Score in extra-large bold text is the immediate focal point
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/analysis_result.dart';
import '../providers/analysis_provider.dart';
import '../widgets/grain_bounding_box_overlay.dart';
import '../widgets/integrity_score_gauge.dart';
import '../widgets/stat_chip.dart';

class AnalysisResultScreen extends ConsumerWidget {
  final AnalysisResult result;
  const AnalysisResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(layerVisibilityProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F14),
      body: Stack(
        children: [
          // ── Full-screen image with overlay ──────────────────────────────
          SizedBox(
            height: size.height * 0.58,
            width: size.width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                result.imagePath.isNotEmpty && File(result.imagePath).existsSync()
                    ? Image.file(
                        File(result.imagePath),
                        fit: BoxFit.cover,
                      )
                    : _MockGrainImage(counts: result.counts),

                // Bounding box overlay
                GrainBoundingBoxOverlay(
                  counts: result.counts,
                  showHealthy: layers.showHealthy,
                  showBroken: layers.showBroken,
                  showDiscolored: layers.showDiscolored,
                ),

                // Top gradient for readability
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).padding.top + 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(180),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom gradient blending into card
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF0D1F15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── App Bar ─────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _BackButton(onTap: () => context.pop()),
                  const Spacer(),
                  _BatchBadge(name: result.batchName),
                  const SizedBox(width: 12),
                  _ShareButton(onTap: () =>
                      context.push(AppRoutes.report, extra: result)),
                ],
              ),
            ),
          ),

          // ── Filter Chips (layer toggles) ─────────────────────────────────
          Positioned(
            top: size.height * 0.48,
            left: 0,
            right: 0,
            child: _LayerFilterChips(
              layers: layers,
              notifier: ref.read(layerVisibilityProvider.notifier),
            ),
          ),

          // ── Summary Bottom Sheet ─────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.48, 0.7, 0.92],
            builder: (context, scrollCtrl) {
              return _SummarySheet(
                result: result,
                scrollCtrl: scrollCtrl,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(120),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }
}

class _BatchBadge extends StatelessWidget {
  final String name;
  const _BatchBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(120),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_rounded,
              color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.healthyGreen.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.bar_chart_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}

class _LayerFilterChips extends StatelessWidget {
  final LayerVisibilityState layers;
  final LayerVisibilityNotifier notifier;
  const _LayerFilterChips(
      {required this.layers, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FilterChip(
            label: '🟢 Healthy',
            selected: layers.showHealthy,
            color: AppTheme.healthyGreen,
            onTap: notifier.toggleHealthy,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🔴 Broken',
            selected: layers.showBroken,
            color: AppTheme.brokenRed,
            onTap: notifier.toggleBroken,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '🟡 Discolored',
            selected: layers.showDiscolored,
            color: AppTheme.discoloredAmber,
            onTap: notifier.toggleDiscolored,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha(220)
              : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white30,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Summary Sheet ─────────────────────────────────────────────────────────────

class _SummarySheet extends StatelessWidget {
  final AnalysisResult result;
  final ScrollController scrollCtrl;
  const _SummarySheet(
      {required this.result, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? const Color(0xFF162B1E),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Integrity Score ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integrity Score',
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white60,
                          letterSpacing: 1.0,
                          fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          result.integrityScore.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                            height: 1,
                          ),
                        ),
                        const Text(
                          '%',
                          style: TextStyle(
                            color: AppTheme.healthyGreen,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getIntegrityLabel(result.integrityScore),
                      style: TextStyle(
                        color: _getIntegrityColor(result.integrityScore),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IntegrityScoreGauge(score: result.integrityScore),
            ],
          ),

          const SizedBox(height: 20),

          // ── Variety Detected ─────────────────────────────────────────
          _VarietyCard(result: result),

          const SizedBox(height: 20),

          // ── Grain Count Stats ────────────────────────────────────────
          Text(
            'GRAIN BREAKDOWN',
            style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2, color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatChip(
                  label: 'Healthy',
                  value: result.counts.healthy.toString(),
                  pct: result.counts.healthyPct,
                  color: AppTheme.healthyGreen,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChip(
                  label: 'Broken',
                  value: result.counts.broken.toString(),
                  pct: result.counts.brokenPct,
                  color: AppTheme.brokenRed,
                  icon: Icons.broken_image_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChip(
                  label: 'Discolored',
                  value: result.counts.discolored.toString(),
                  pct: result.counts.discoloredPct,
                  color: AppTheme.discoloredAmber,
                  icon: Icons.circle_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Total & Processing Time ──────────────────────────────────
          Row(
            children: [
              _InfoTile(
                label: 'Total Grains',
                value: result.counts.total.toString(),
                icon: Icons.grain_rounded,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                label: 'Processed In',
                value:
                    '${result.processingTime.inMilliseconds / 1000}s',
                icon: Icons.timer_rounded,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                label: 'Analyzed On',
                value:
                    '${result.analyzedAt.day}/${result.analyzedAt.month}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── View Full Report Button ──────────────────────────────────
          FilledButton.icon(
            onPressed: () =>
                context.push(AppRoutes.report, extra: result),
            icon: const Icon(Icons.analytics_rounded),
            label: const Text('View Full Report'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: AppTheme.healthyGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  String _getIntegrityLabel(double score) {
    if (score >= 85) return '⭐ Excellent Quality';
    if (score >= 70) return '✅ Good Quality';
    if (score >= 55) return '⚠️ Fair Quality';
    return '❌ Poor Quality';
  }

  Color _getIntegrityColor(double score) {
    if (score >= 85) return AppTheme.healthyGreen;
    if (score >= 70) return const Color(0xFF86EFAC);
    if (score >= 55) return AppTheme.discoloredAmber;
    return AppTheme.brokenRed;
  }
}

class _VarietyCard extends StatelessWidget {
  final AnalysisResult result;
  const _VarietyCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.healthyGreen.withAlpha(40),
            AppTheme.healthyGreen.withAlpha(10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.healthyGreen.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.healthyGreen.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded,
                color: AppTheme.healthyGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VARIETY DETECTED',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  result.detectedVariety,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${result.varietyConfidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: AppTheme.healthyGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
              ),
              const Text(
                'confidence',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white38, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ── Mock Grain Image (when no real photo) ──────────────────────────────────
class _MockGrainImage extends StatelessWidget {
  final GrainCounts counts;
  const _MockGrainImage({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A2E23), const Color(0xFF0D1F15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: _MockGrainPainter(counts: counts),
      ),
    );
  }
}

class _MockGrainPainter extends CustomPainter {
  final GrainCounts counts;
  _MockGrainPainter({required this.counts});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final grains = <({Offset pos, String type, double angle})>[];

    // Generate grain positions deterministically
    void addGrains(int n, String type) {
      for (var i = 0; i < n && grains.length < 200; i++) {
        grains.add((
          pos: Offset(rng.nextDouble() * size.width,
              rng.nextDouble() * size.height),
          type: type,
          angle: rng.nextDouble() * math.pi,
        ));
      }
    }

    final scale = (counts.total > 0) ? math.min(200 / counts.total, 1.0) : 1.0;
    addGrains((counts.healthy * scale).round(), 'healthy');
    addGrains((counts.broken * scale).round(), 'broken');
    addGrains((counts.discolored * scale).round(), 'discolored');

    for (final g in grains) {
      final color = g.type == 'healthy'
          ? AppTheme.healthyGreen.withAlpha(200)
          : g.type == 'broken'
              ? AppTheme.brokenRed.withAlpha(180)
              : AppTheme.discoloredAmber.withAlpha(180);
      final paint = Paint()..color = color;
      canvas.save();
      canvas.translate(g.pos.dx, g.pos.dy);
      canvas.rotate(g.angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: 24 + rng.nextDouble() * 8,
                height: 8 + rng.nextDouble() * 3),
            const Radius.circular(4)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
