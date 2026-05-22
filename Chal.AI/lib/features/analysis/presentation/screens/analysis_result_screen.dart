import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/image_download.dart';
import '../../domain/models/analysis_result.dart';
import '../widgets/full_screen_image_viewer.dart';
import '../widgets/integrity_score_gauge.dart';
import '../widgets/stat_chip.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final AnalysisResult result;
  const AnalysisResultScreen({super.key, required this.result});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  final _sheetCtrl = DraggableScrollableController();
  double _imageOpacity = 1.0;

  AnalysisResult get result => widget.result;

  @override
  void initState() {
    super.initState();
    _sheetCtrl.addListener(_onSheetChanged);
  }

  void _onSheetChanged() {
    if (!_sheetCtrl.isAttached) return;
    final size = _sheetCtrl.size;
    // Fade out as sheet grows from 0.55 to 0.75
    final opacity = 1.0 - ((size - 0.55) / 0.20).clamp(0.0, 1.0);
    if (mounted && (opacity - _imageOpacity).abs() > 0.005) {
      setState(() => _imageOpacity = opacity);
    }
  }

  @override
  void dispose() {
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Full-screen annotated image (fades as sheet expands) ─────
          AnimatedOpacity(
            opacity: _imageOpacity,
            duration: const Duration(milliseconds: 80),
            child: SizedBox(
              height: size.height * 0.58,
              width: size.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Real annotated image from backend, plain dark bg as fallback
                  result.morphologyImageBytes != null
                      ? GestureDetector(
                          onTap: () => FullScreenImageViewer.show(
                            context,
                            imageBytes: result.morphologyImageBytes!,
                            downloadFilename:
                                'chal_ai_${result.batchName.replaceAll(' ', '_')}.jpg',
                          ),
                          child: Image.memory(
                            result.morphologyImageBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Center(
                            child: Icon(Icons.grain_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.12),
                                size: 64),
                          ),
                        ),

                  // Expand + download buttons (only when image is available)
                  if (result.morphologyImageBytes != null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _ImageActionButtons(
                        bytes: result.morphologyImageBytes!,
                        filename:
                            'chal_ai_${result.batchName.replaceAll(' ', '_')}.jpg',
                        onExpand: () => FullScreenImageViewer.show(
                          context,
                          imageBytes: result.morphologyImageBytes!,
                          downloadFilename:
                              'chal_ai_${result.batchName.replaceAll(' ', '_')}.jpg',
                        ),
                      ),
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
                            Theme.of(context).scaffoldBackgroundColor,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── App Bar ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _BackButton(onTap: () => context.pop()),
                  const Spacer(),
                  _BatchBadge(name: result.batchName),
                  const SizedBox(width: 12),
                  _ShareButton(
                      onTap: () =>
                          context.push(AppRoutes.report, extra: result)),
                ],
              ),
            ),
          ),

          // ── Summary Bottom Sheet ─────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: 0.48,
            minChildSize: 0.42,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.48, 0.7, 0.92],
            builder: (context, scrollCtrl) {
              return _SummarySheet(
                result: result,
                scrollCtrl: scrollCtrl,
                s: ref.watch(appStringsProvider),
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
        child:
            const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ── Summary Sheet ─────────────────────────────────────────────────────────────

class _SummarySheet extends StatelessWidget {
  final AnalysisResult result;
  final ScrollController scrollCtrl;
  final AppStrings s;
  const _SummarySheet({
    required this.result,
    required this.scrollCtrl,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? const Color(0xFF162B1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.24),
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
                      s.integrityScore.toUpperCase(),
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
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
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
                      _getIntegrityLabel(result.integrityScore, s),
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
          _VarietyCard(result: result, s: s),

          const SizedBox(height: 20),

          // ── Grain Count Stats ────────────────────────────────────────
          Text(
            s.grainBreakdown,
            style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatChip(
                  label: s.healthy,
                  value: result.counts.healthy.toString(),
                  pct: result.counts.healthyPct,
                  color: AppTheme.healthyGreen,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChip(
                  label: s.threeQuarterBroken,
                  value: result.counts.threeQuarterBroken.toString(),
                  pct: result.counts.threeQuarterBrokenPct,
                  color: const Color(0xFFFFD600),
                  icon: Icons.broken_image_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChip(
                  label: s.halfBroken,
                  value: result.counts.halfBroken.toString(),
                  pct: result.counts.halfBrokenPct,
                  color: AppTheme.brokenRed,
                  icon: Icons.broken_image_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatChip(
                  label: s.impurity,
                  value: result.counts.impurity.toString(),
                  pct: result.counts.impurityPct,
                  color: const Color(0xFFDD44FF),
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatChip(
                  label: s.discolored,
                  value: result.counts.discolored.toString(),
                  pct: result.counts.discoloredPct,
                  color: const Color(0xFF4488FF),
                  icon: Icons.palette_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Total & Processing Time ──────────────────────────────────
          Row(
            children: [
              _InfoTile(
                label: s.totalGrains,
                value: result.counts.total.toString(),
                icon: Icons.grain_rounded,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                label: s.processedIn,
                value:
                    '${result.processingTime.inMilliseconds / 1000} ${s.seconds}',
                icon: Icons.timer_rounded,
              ),
              const SizedBox(width: 12),
              _InfoTile(
                label: s.analyzedOn,
                value: '${result.analyzedAt.day}/${result.analyzedAt.month}',
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── View Full Report Button ──────────────────────────────────
          FilledButton.icon(
            onPressed: () => context.push(AppRoutes.report, extra: result),
            icon: const Icon(Icons.analytics_rounded),
            label: Text(s.viewFullReport),
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

  String _getIntegrityLabel(double score, AppStrings s) {
    if (score >= 85) return s.excellentQuality;
    if (score >= 70) return s.goodQuality;
    if (score >= 55) return s.fairQuality;
    return s.poorQuality;
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
  final AppStrings s;
  const _VarietyCard({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
        border:
            Border.all(color: AppTheme.healthyGreen.withAlpha(80), width: 1.5),
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
                Text(
                  s.varietyDetected,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.38),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  result.detectedVariety,
                  style: TextStyle(
                      color: cs.onSurface,
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
              Text(
                s.confidence,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Image overlay: expand + download buttons ──────────────────────────────────

class _ImageActionButtons extends ConsumerStatefulWidget {
  final Uint8List bytes;
  final String filename;
  final VoidCallback onExpand;
  const _ImageActionButtons({
    required this.bytes,
    required this.filename,
    required this.onExpand,
  });

  @override
  ConsumerState<_ImageActionButtons> createState() =>
      _ImageActionButtonsState();
}

class _ImageActionButtonsState extends ConsumerState<_ImageActionButtons> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await downloadImage(widget.bytes, widget.filename);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PillBtn(
          icon: Icons.fullscreen_rounded,
          label: s.view,
          onTap: widget.onExpand,
        ),
        const SizedBox(width: 8),
        _PillBtn(
          icon: _downloading ? null : Icons.download_rounded,
          label: _downloading ? s.saving : s.download,
          onTap: _downloading ? null : _download,
          loading: _downloading,
          accent: true,
        ),
      ],
    );
  }
}

class _PillBtn extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool accent;
  const _PillBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accent
              ? AppTheme.healthyGreen.withAlpha(220)
              : Colors.black.withAlpha(150),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else if (icon != null)
              Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: cs.onSurface.withValues(alpha: 0.38), size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.38),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
