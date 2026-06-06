import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../analysis/domain/models/analysis_result.dart';
import '../../../analysis/presentation/widgets/full_screen_image_viewer.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';

class DetailedReportScreen extends ConsumerStatefulWidget {
  final AnalysisResult result;
  const DetailedReportScreen({super.key, required this.result});

  @override
  ConsumerState<DetailedReportScreen> createState() =>
      _DetailedReportScreenState();
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _ReportHeader(result: r, s: s),
          Container(
            color:
                isDark ? const Color(0xFF0F2318) : cs.surfaceContainerHighest,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.healthyGreen,
              indicatorWeight: 3,
              labelColor: AppTheme.healthyGreen,
              unselectedLabelColor: cs.onSurface.withValues(alpha: 0.38),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
// (Unchanged from your original code)
class _ReportHeader extends StatelessWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _ReportHeader({required this.result, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? const Color(0xFF0F2318) : cs.surfaceContainerHighest,
            Theme.of(context).scaffoldBackgroundColor,
          ],
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
                        color: cs.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: cs.onSurface, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullReport,
                          style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${result.batchName} · ${result.analyzedAt.day}/${result.analyzedAt.month}/${result.analyzedAt.year}',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.54),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const NotificationBellButton(),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.38),
                              fontSize: 10),
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
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Tab 1: Grain Breakdown ────────────────────────────────────────────────
// (Unchanged from your original code)
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
      (
        label: s.healthy,
        color: AppTheme.healthyGreen,
        icon: Icons.check_circle_rounded
      ),
      (
        label: s.threeQuarterBroken,
        color: const Color(0xFFFFD600),
        icon: Icons.broken_image_rounded
      ),
      (
        label: s.halfBroken,
        color: AppTheme.brokenRed,
        icon: Icons.broken_image_outlined
      ),
      (
        label: s.impurity,
        color: const Color(0xFFDD44FF),
        icon: Icons.warning_amber_rounded
      ),
      (
        label: s.discolored,
        color: const Color(0xFF4488FF),
        icon: Icons.palette_rounded
      ),
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
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38),
                fontSize: 15)),
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
                            _touchedIndex =
                                res?.touchedSection?.touchedSectionIndex ?? -1;
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
                          title: '${(val / total * 100).toStringAsFixed(1)}%',
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
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
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
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
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
                    style:
                        TextStyle(color: color.withAlpha(180), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Annotated Images ───────────────────────────────────────────────
// (Unchanged from your original code)
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
            Icon(Icons.image_not_supported_rounded,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.24),
                size: 48),
            const SizedBox(height: 12),
            Text(s.noAnnotatedImages,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
                    fontSize: 14)),
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
              title: s.annotatedImages, subtitle: s.aiGeneratedOverlays),
          const SizedBox(height: 20),
          if (hasMorph) ...[
            _ImageCard(
              title: s.morphologyAnalysis,
              subtitle: s.morphologySubtitle,
              imageBytes: result.morphologyImageBytes!,
              filename:
                  'chal_ai_${result.batchName.replaceAll(' ', '_')}_morph.jpg',
              expandLabel: s.expand,
            ),
          ],
          if (hasMorph && hasColor) const SizedBox(height: 20),
          if (hasColor) ...[
            _ImageCard(
              title: s.colorAnalysis,
              subtitle: s.colorSubtitle,
              imageBytes: result.colorImageBytes!,
              filename:
                  'chal_ai_${result.batchName.replaceAll(' ', '_')}_color.jpg',
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
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.54),
                fontSize: 12)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _SectionTitle extends StatelessWidget {
  final String title, subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.54),
                fontSize: 13)),
      ],
    );
  }
}

// ── Export Bar (UPDATED with PDF Generation & Loading States) ───────────────

class _ExportBar extends StatefulWidget {
  final AnalysisResult result;
  final AppStrings s;
  const _ExportBar({required this.result, required this.s});

  @override
  State<_ExportBar> createState() => _ExportBarState();
}

class _ExportBarState extends State<_ExportBar> {
  bool _isSharing = false;
  bool _isDownloading = false;

  // Force an English instance of AppStrings for the PDF
  final AppStrings _enStrings = const AppStrings('en');

  Future<void> _handlePdfAction(bool isShare) async {
    if (isShare) {
      setState(() => _isSharing = true);
    } else {
      setState(() => _isDownloading = true);
    }

    try {
      // Pass the forced English strings (_enStrings) to the PDF generator
      final file = await _generatePdf(widget.result, _enStrings);

      if (isShare) {
        // Share the generated PDF file directly, using English text for the share dialogue
        await Share.shareXFiles(
          [XFile(file.path)],
          text: _enStrings.reportHeader,
        );
      } else {
        // Confirm download success to user (This keeps the UI SnackBar in the user's selected language)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF Downloaded to:\n${file.path}'),
              backgroundColor: AppTheme.healthyGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.s.somethingWentWrong),
            backgroundColor: AppTheme.brokenRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF0F2318) : cs.surfaceContainerHighest,
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (_isSharing || _isDownloading)
                  ? null
                  : () => _handlePdfAction(true),
              icon: _isSharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              label:
                  Text(widget.s.share), // Button label stays in user's language
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
              onPressed: (_isSharing || _isDownloading)
                  ? null
                  : () => _handlePdfAction(false),
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(widget
                  .s.downloadPdf), // Button label stays in user's language
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

  // ── PDF Generation Logic ───────────────────────────────────────────────────

  Future<File> _generatePdf(AnalysisResult r, AppStrings s) async {
    final pdf = pw.Document();

    // We can safely use the default Helvetica font now since the text is guaranteed to be English
    final font = pw.Font.helvetica();

    // Helper to convert Flutter colors to PDF Colors
    PdfColor toPdfColor(Color c) => PdfColor.fromInt(c.toARGB32());

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font),
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(s.reportHeader,
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: toPdfColor(AppTheme.healthyGreen))),
                    pw.SizedBox(height: 4),
                    pw.Text('${s.batch}: ${r.batchName}',
                        style: const pw.TextStyle(fontSize: 14)),
                    pw.Text(
                        '${s.date}: ${r.analyzedAt.day}/${r.analyzedAt.month}/${r.analyzedAt.year}',
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: toPdfColor(AppTheme.healthyGreen).shade(0.1),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(
                        color: toPdfColor(AppTheme.healthyGreen), width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('${r.integrityScore.toStringAsFixed(0)}%',
                          style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: toPdfColor(AppTheme.healthyGreen))),
                      pw.Text(s.score,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey300, height: 30, thickness: 1),

            // Variety & Time summary
            pw.Row(children: [
              pw.Text('${s.varietyDetected}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(r.detectedVariety),
              pw.SizedBox(width: 20),
              pw.Text('${s.totalGrains}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${r.counts.total}'),
              pw.SizedBox(width: 20),
              pw.Text('${s.processingTime}: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  '${(r.processingTime.inMilliseconds / 1000).toStringAsFixed(1)}${s.seconds}'),
            ]),
            pw.SizedBox(height: 30),

            // Grain Breakdown Chart Section
            pw.Text(s.grainBreakdown,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),

            if (r.counts.total > 0)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // The colored Pie Chart (Inline legends removed to prevent overlap)
                  pw.SizedBox(
                    width: 200,
                    height: 200,
                    child: pw.Chart(
                      grid: pw.PieGrid(),
                      datasets: [
                        if (r.counts.healthy > 0)
                          pw.PieDataSet(
                            value: r.counts.healthy.toDouble(),
                            color: toPdfColor(AppTheme.healthyGreen),
                          ),
                        if (r.counts.threeQuarterBroken > 0)
                          pw.PieDataSet(
                            value: r.counts.threeQuarterBroken.toDouble(),
                            color: toPdfColor(const Color(0xFFFFD600)),
                          ),
                        if (r.counts.halfBroken > 0)
                          pw.PieDataSet(
                            value: r.counts.halfBroken.toDouble(),
                            color: toPdfColor(AppTheme.brokenRed),
                          ),
                        if (r.counts.impurity > 0)
                          pw.PieDataSet(
                            value: r.counts.impurity.toDouble(),
                            color: toPdfColor(const Color(0xFFDD44FF)),
                          ),
                        if (r.counts.discolored > 0)
                          pw.PieDataSet(
                            value: r.counts.discolored.toDouble(),
                            color: toPdfColor(const Color(0xFF4488FF)),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),

                  // The Data Table next to the chart acts as the perfect non-overlapping legend
                  pw.Expanded(
                      child: pw.Table(columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  }, children: [
                    _buildPdfTableRow(s.healthy, r.counts.healthy,
                        r.counts.healthyPct, toPdfColor(AppTheme.healthyGreen)),
                    _buildPdfTableRow(
                        s.threeQuarterBroken,
                        r.counts.threeQuarterBroken,
                        r.counts.threeQuarterBrokenPct,
                        toPdfColor(const Color(0xFFFFD600))),
                    _buildPdfTableRow(s.halfBroken, r.counts.halfBroken,
                        r.counts.halfBrokenPct, toPdfColor(AppTheme.brokenRed)),
                    _buildPdfTableRow(
                        s.impurity,
                        r.counts.impurity,
                        r.counts.impurityPct,
                        toPdfColor(const Color(0xFFDD44FF))),
                    _buildPdfTableRow(
                        s.discolored,
                        r.counts.discolored,
                        r.counts.discoloredPct,
                        toPdfColor(const Color(0xFF4488FF))),
                  ]))
                ],
              ),

            // Appended Images (if any)
            if (r.morphologyImageBytes != null ||
                r.colorImageBytes != null) ...[
              pw.SizedBox(height: 40),
              pw.Text(s.annotatedImages,
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
            ],

            if (r.morphologyImageBytes != null) ...[
              pw.Text(s.morphologyAnalysis,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 250,
                child: pw.Image(pw.MemoryImage(r.morphologyImageBytes!),
                    fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: 20),
            ],

            if (r.colorImageBytes != null) ...[
              pw.Text(s.colorAnalysis,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 250,
                child: pw.Image(pw.MemoryImage(r.colorImageBytes!),
                    fit: pw.BoxFit.contain),
              ),
            ],

            // Footer
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Center(
              child: pw.Text(s.generatedBy,
                  style: const pw.TextStyle(
                      color: PdfColors.grey500, fontSize: 10)),
            )
          ];
        },
      ),
    );

    // ── Save PDF to Device Downloads Directory ──

    // Attempt to get the public Downloads directory (Works on Android, Windows, macOS, Linux)
    Directory? dir = await getDownloadsDirectory();

    // Fallback to Documents directory for iOS (iOS strict sandboxing prevents direct Downloads folder access)
    dir ??= await getApplicationDocumentsDirectory();

    // Fallback dir for Desktop if path_provider fails entirely
    final directoryPath = dir.path.isNotEmpty ? dir.path : '.';
    final file = File(
        '$directoryPath/Chal_AI_Report_${r.batchName.replaceAll(' ', '_')}.pdf');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.TableRow _buildPdfTableRow(
      String label, int count, double pct, PdfColor color) {
    return pw.TableRow(children: [
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(children: [
            pw.Container(
                width: 8,
                height: 8,
                decoration:
                    pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 8),
            pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          ])),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text('$count',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text('${pct.toStringAsFixed(1)}%',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
      ),
    ]);
  }
}
