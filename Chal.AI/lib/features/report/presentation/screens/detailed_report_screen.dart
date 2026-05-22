import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analysis/domain/models/analysis_result.dart';
import '../../../analysis/presentation/widgets/full_screen_image_viewer.dart';

class DetailedReportScreen extends ConsumerStatefulWidget {
  final AnalysisResult result;
  const DetailedReportScreen({super.key, required this.result});

  @override
  ConsumerState<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends ConsumerState<DetailedReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F14),
      body: Column(
        children: [
          _ReportHeader(result: r, s: s),

          Container(
            color: const Color(0xFF0F2318),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.healthyGreen,
              indicatorWeight: 3,
              labelColor: AppTheme.healthyGreen,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: s.grainBreakdownTab),
                Tab(text: s.imagesTab),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GrainBreakdownTab(result: r, s: s),
                _AnnotatedImagesTab(result: r, s: s),
              ],
            ),
          ),

          _ExportBar(result: r, s: s),
        ],
      ),
    );
  }
}

// ── Report Header ─────────────────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _ReportHeader({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2318), Color(0xFF0A1F14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullReport,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${result.batchName} · ${result.analyzedAt.day}/${result.analyzedAt.month}/${result.analyzedAt.year}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.healthyGreen.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.healthyGreen.withAlpha(120),
                          width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${result.integrityScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: AppTheme.healthyGreen,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                        Text(
                          s.score,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _SummaryPill(
                      label: result.detectedVariety,
                      icon: Icons.eco_rounded,
                      color: AppTheme.healthyGreen),
                  const SizedBox(width: 8),
                  _SummaryPill(
                      label: '${result.counts.total} ${s.grains}',
                      icon: Icons.grain_rounded,
                      color: AppTheme.integrityBlue),
                  const SizedBox(width: 8),
                  _SummaryPill(
                      label:
                          '${(result.processingTime.inMilliseconds / 1000).toStringAsFixed(1)}${s.seconds}',
                      icon: Icons.timer_rounded,
                      color: AppTheme.discoloredAmber),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _SummaryPill(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Tab 1: Grain Breakdown ────────────────────────────────────────────────

class _GrainBreakdownTab extends StatefulWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _GrainBreakdownTab({required this.result, required this.s});

  @override
  State<_GrainBreakdownTab> createState() => _GrainBreakdownTabState();
}

class _GrainBreakdownTabState extends State<_GrainBreakdownTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final counts = widget.result.counts;
    final categories = [
      (label: s.healthy,           color: AppTheme.healthyGreen,  icon: Icons.check_circle_rounded),
      (label: s.threeQuarterBroken, color: const Color(0xFFFFD600), icon: Icons.broken_image_rounded),
      (label: s.halfBroken,        color: AppTheme.brokenRed,     icon: Icons.broken_image_outlined),
      (label: s.impurity,          color: const Color(0xFFDD44FF), icon: Icons.warning_amber_rounded),
      (label: s.discolored,        color: const Color(0xFF4488FF), icon: Icons.palette_rounded),
    ];
    final values = [
      counts.healthy.toDouble(),
      counts.threeQuarterBroken.toDouble(),
      counts.halfBroken.toDouble(),
      counts.impurity.toDouble(),
      counts.discolored.toDouble(),
    ];
    final total = counts.total;

    if (total == 0) {
      return Center(
        child: Text(s.noGrainsDetected,
            style: const TextStyle(color: Colors.white38, fontSize: 15)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: s.grainBreakdownTitle,
            subtitle: '${s.distributionAcross} $total ${s.detectedGrains}',
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (ev, res) {
                          setState(() {
                            _touchedIndex = res
                                    ?.touchedSection
                                    ?.touchedSectionIndex ??
                                -1;
                          });
                        },
                      ),
                      sections: List.generate(categories.length, (i) {
                        final val = values[i];
                        if (val <= 0) {
                          return PieChartSectionData(
                              value: 0, showTitle: false, radius: 0);
                        }
                        final isTouched = i == _touchedIndex;
                        return PieChartSectionData(
                          value: val,
                          color: categories[i].color,
                          radius: isTouched ? 72 : 60,
                          title:
                              '${(val / total * 100).toStringAsFixed(1)}%',
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 13 : 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }),
                      centerSpaceRadius: 48,
                      sectionsSpace: 3,
                    ),
                    duration: const Duration(milliseconds: 500),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(categories.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: categories[i].color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${categories[i].label}\n${values[i].toInt()} ${s.grains}',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                height: 1.3),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          for (int i = 0; i < categories.length; i++) ...[
            _GrainCategoryCard(
              label: categories[i].label,
              count: values[i].toInt(),
              pct: total > 0 ? values[i] / total * 100 : 0.0,
              color: categories[i].color,
              icon: categories[i].icon,
              ofTotalLabel: s.ofTotal,
              grainsLabel: s.grains,
            ),
            if (i < categories.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _GrainCategoryCard extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  final Color color;
  final IconData icon;
  final String ofTotalLabel;
  final String grainsLabel;
  const _GrainCategoryCard({
    required this.label,
    required this.count,
    required this.pct,
    required this.color,
    required this.icon,
    required this.ofTotalLabel,
    required this.grainsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('$count $grainsLabel',
                        style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${pct.toStringAsFixed(1)}% $ofTotalLabel',
                    style: TextStyle(
                        color: color.withAlpha(180), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Annotated Images ───────────────────────────────────────────────

class _AnnotatedImagesTab extends StatelessWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _AnnotatedImagesTab({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    final hasMorph = result.morphologyImageBytes != null;
    final hasColor = result.colorImageBytes != null;

    if (!hasMorph && !hasColor) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_rounded,
                color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(s.noAnnotatedImages,
                style: const TextStyle(color: Colors.white38, fontSize: 14)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: s.annotatedImages,
            subtitle: s.aiGeneratedOverlays,
          ),
          const SizedBox(height: 20),

          if (hasMorph) ...[
            _ImageCard(
              title: s.morphologyAnalysis,
              subtitle: s.morphologySubtitle,
              imageBytes: result.morphologyImageBytes!,
              filename: 'chal_ai_${result.batchName.replaceAll(' ', '_')}_morph.jpg',
              expandLabel: s.expand,
            ),
          ],

          if (hasMorph && hasColor) const SizedBox(height: 20),

          if (hasColor) ...[
            _ImageCard(
              title: s.colorAnalysis,
              subtitle: s.colorSubtitle,
              imageBytes: result.colorImageBytes!,
              filename: 'chal_ai_${result.batchName.replaceAll(' ', '_')}_color.jpg',
              expandLabel: s.expand,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title, subtitle, filename, expandLabel;
  final Uint8List imageBytes;
  const _ImageCard({
    required this.title,
    required this.subtitle,
    required this.imageBytes,
    required this.filename,
    required this.expandLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => FullScreenImageViewer.show(
            context,
            imageBytes: imageBytes,
            downloadFilename: filename,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.memory(imageBytes,
                    width: double.infinity, fit: BoxFit.fitWidth),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fullscreen_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text(expandLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

// ── Export Bar ────────────────────────────────────────────────────────────

class _ExportBar extends StatelessWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _ExportBar({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F2318),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareText,
              icon: const Icon(Icons.share_rounded),
              label: Text(s.share),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.healthyGreen,
                side: BorderSide(
                    color: AppTheme.healthyGreen.withAlpha(120), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _shareText,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(s.exportPdf),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.healthyGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareText() {
    final r = result;
    final text = '''
${s.reportHeader}
${s.batch}: ${r.batchName}
${s.date}: ${r.analyzedAt.day}/${r.analyzedAt.month}/${r.analyzedAt.year}

${s.integrityScore}: ${r.integrityScore.toStringAsFixed(1)}%
${s.totalGrains}: ${r.counts.total}

${s.grainBreakdown}:
  • ${s.healthy}: ${r.counts.healthy} (${r.counts.healthyPct.toStringAsFixed(1)}%)
  • ${s.threeQuarterBroken}: ${r.counts.threeQuarterBroken} (${r.counts.threeQuarterBrokenPct.toStringAsFixed(1)}%)
  • ${s.halfBroken}: ${r.counts.halfBroken} (${r.counts.halfBrokenPct.toStringAsFixed(1)}%)
  • ${s.impurity}: ${r.counts.impurity} (${r.counts.impurityPct.toStringAsFixed(1)}%)
  • ${s.discolored}: ${r.counts.discolored} (${r.counts.discoloredPct.toStringAsFixed(1)}%)

${s.processingTime}: ${(r.processingTime.inMilliseconds / 1000).toStringAsFixed(2)}${s.seconds}
${s.generatedBy}
''';
    Share.share(text);
  }
}
