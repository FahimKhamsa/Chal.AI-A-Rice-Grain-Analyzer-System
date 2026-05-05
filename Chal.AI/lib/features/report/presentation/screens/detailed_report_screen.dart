// features/report/presentation/screens/detailed_report_screen.dart
// Screen C — Detailed Report View.
// UX decisions:
//   • Uses fl_chart BarChart for grain length distribution
//   • PieChart for defect breakdown (scientific, accessible colors)
//   • Export/Share button is always visible in the bottom action bar
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../../../core/theme/app_theme.dart';
import '../../../analysis/domain/models/analysis_result.dart';

class DetailedReportScreen extends StatefulWidget {
  final AnalysisResult result;
  const DetailedReportScreen({super.key, required this.result});

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen>
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A1F14),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _ReportHeader(result: r),

          // ── Tabs ────────────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0F2318),
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.healthyGreen,
              indicatorWeight: 3,
              labelColor: AppTheme.healthyGreen,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Length Distribution'),
                Tab(text: 'Defect Analysis'),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _LengthDistributionTab(result: r),
                _DefectAnalysisTab(result: r),
              ],
            ),
          ),

          // ── Export Bar ─────────────────────────────────────────────────
          _ExportBar(result: r),
        ],
      ),
    );
  }
}

// ── Report Header ─────────────────────────────────────────────────────────

class _ReportHeader extends StatelessWidget {
  final AnalysisResult result;
  const _ReportHeader({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F2318),
            const Color(0xFF0A1F14),
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
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Full Report',
                          style: TextStyle(
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
                  // Score badge
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
                        const Text(
                          'Score',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Quick summary row
              Row(
                children: [
                  _SummaryPill(
                      label: result.detectedVariety,
                      icon: Icons.eco_rounded,
                      color: AppTheme.healthyGreen),
                  const SizedBox(width: 8),
                  _SummaryPill(
                      label: '${result.counts.total} Grains',
                      icon: Icons.grain_rounded,
                      color: AppTheme.integrityBlue),
                  const SizedBox(width: 8),
                  _SummaryPill(
                      label:
                          '${result.varietyConfidence.toStringAsFixed(0)}% Conf.',
                      icon: Icons.verified_rounded,
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

// ── Tab 1: Grain Length Distribution ─────────────────────────────────────

class _LengthDistributionTab extends StatelessWidget {
  final AnalysisResult result;
  const _LengthDistributionTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final dist = result.lengthDistribution;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Grain Length Distribution',
            subtitle: 'Percentage of grains by length category',
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: [
                  _bar(0, dist.shortPct, const Color(0xFF60A5FA), 'Short'),
                  _bar(1, dist.mediumPct, AppTheme.healthyGreen, 'Medium'),
                  _bar(2, dist.longPct, const Color(0xFF818CF8), 'Long'),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        const labels = ['Short\n<5mm', 'Medium\n5–6.5mm', 'Long\n>6.5mm'];
                        final idx = v.toInt();
                        if (idx < 0 || idx > 2) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[idx],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}%',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),

          const SizedBox(height: 28),

          // Legend cards
          Row(
            children: [
              _LegendCard(
                  label: 'Short (<5mm)',
                  pct: dist.shortPct,
                  color: const Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              _LegendCard(
                  label: 'Medium (5–6.5mm)',
                  pct: dist.mediumPct,
                  color: AppTheme.healthyGreen),
              const SizedBox(width: 10),
              _LegendCard(
                  label: 'Long (>6.5mm)',
                  pct: dist.longPct,
                  color: const Color(0xFF818CF8)),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 36,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: color.withAlpha(30),
          ),
        ),
      ],
    );
  }
}

class _LegendCard extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _LegendCard(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Column(
          children: [
            Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 10, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2: Defect Analysis ────────────────────────────────────────────────

class _DefectAnalysisTab extends StatefulWidget {
  final AnalysisResult result;
  const _DefectAnalysisTab({required this.result});

  @override
  State<_DefectAnalysisTab> createState() => _DefectAnalysisTabState();
}

class _DefectAnalysisTabState extends State<_DefectAnalysisTab> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final d = widget.result.defectBreakdown;

    final sections = [
      _pieSection(0, 'Chalky', d.chalkyPct, const Color(0xFFF8BBD0)),
      _pieSection(1, 'Red-Streaked', d.redStreakedPct, AppTheme.brokenRed),
      _pieSection(2, 'Immature', d.immaturePct, AppTheme.discoloredAmber),
      _pieSection(3, 'Foreign Matter', d.foreignMatterPct,
          const Color(0xFF9C27B0)),
    ];

    final totalDefect =
        d.chalkyPct + d.redStreakedPct + d.immaturePct + d.foreignMatterPct;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Defect Breakdown',
            subtitle: 'Percentage breakdown of grain defect types',
          ),
          const SizedBox(height: 24),

          // Pie Chart
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
                                res?.touchedSection?.touchedSectionIndex ??
                                    -1;
                          });
                        },
                      ),
                      sections: sections,
                      centerSpaceRadius: 48,
                      sectionsSpace: 3,
                    ),
                  duration: const Duration(milliseconds: 500),
                  ),
                ),
                const SizedBox(width: 20),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _pieLegend('Chalky', d.chalkyPct,
                        const Color(0xFFF8BBD0)),
                    _pieLegend('Red-Streaked', d.redStreakedPct,
                        AppTheme.brokenRed),
                    _pieLegend('Immature', d.immaturePct,
                        AppTheme.discoloredAmber),
                    _pieLegend('Foreign', d.foreignMatterPct,
                        const Color(0xFF9C27B0)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Total defect summary
          _TotalDefectSummary(totalDefect: totalDefect),

          const SizedBox(height: 24),

          // Individual defect detail cards
          _DefectDetailCard(
            label: 'Chalky Grains',
            pct: d.chalkyPct,
            color: const Color(0xFFF8BBD0),
            description:
                'Caused by high temperatures or water stress during grain-fill stage.',
            icon: Icons.circle_outlined,
          ),
          const SizedBox(height: 10),
          _DefectDetailCard(
            label: 'Red-Streaked Grains',
            pct: d.redStreakedPct,
            color: AppTheme.brokenRed,
            description:
                'Indicates bran pigmentation exposure during milling.',
            icon: Icons.line_axis_rounded,
          ),
          const SizedBox(height: 10),
          _DefectDetailCard(
            label: 'Immature Grains',
            pct: d.immaturePct,
            color: AppTheme.discoloredAmber,
            description:
                'Harvested prematurely; higher moisture content expected.',
            icon: Icons.eco_rounded,
          ),
          const SizedBox(height: 10),
          _DefectDetailCard(
            label: 'Foreign Matter',
            pct: d.foreignMatterPct,
            color: const Color(0xFF9C27B0),
            description:
                'Stones, husks, or other non-grain material detected.',
            icon: Icons.warning_amber_rounded,
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(
      int idx, String title, double value, Color color) {
    final isTouched = idx == _touchedIndex;
    return PieChartSectionData(
      value: value,
      color: color,
      radius: isTouched ? 72 : 60,
      title: '${value.toStringAsFixed(1)}%',
      titleStyle: TextStyle(
        fontSize: isTouched ? 14 : 12,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _pieLegend(String label, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label\n${pct.toStringAsFixed(1)}%',
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _TotalDefectSummary extends StatelessWidget {
  final double totalDefect;
  const _TotalDefectSummary({required this.totalDefect});

  @override
  Widget build(BuildContext context) {
    final isLow = totalDefect <= 10;
    final color = isLow ? AppTheme.healthyGreen : AppTheme.brokenRed;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isLow ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Defect Rate: ${totalDefect.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  isLow
                      ? 'Within acceptable range (≤10% defects)'
                      : 'Exceeds recommended defect threshold',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DefectDetailCard extends StatelessWidget {
  final String label, description;
  final double pct;
  final Color color;
  final IconData icon;

  const _DefectDetailCard({
    required this.label,
    required this.description,
    required this.pct,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(14),
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
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 15, // max 15% for visual scale
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
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
            style:
                const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

// ── Export Bar ────────────────────────────────────────────────────────────

class _ExportBar extends StatelessWidget {
  final AnalysisResult result;
  const _ExportBar({required this.result});

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
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.healthyGreen,
                side: BorderSide(
                    color: AppTheme.healthyGreen.withAlpha(120),
                    width: 1.5),
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
              onPressed: _exportMockPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export PDF'),
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
Chal.AI Analysis Report
Batch: ${r.batchName}
Date: ${r.analyzedAt.day}/${r.analyzedAt.month}/${r.analyzedAt.year}

Integrity Score: ${r.integrityScore.toStringAsFixed(1)}%
Variety: ${r.detectedVariety} (${r.varietyConfidence.toStringAsFixed(1)}% confidence)

Grains:
  • Healthy: ${r.counts.healthy} (${r.counts.healthyPct.toStringAsFixed(1)}%)
  • Broken: ${r.counts.broken} (${r.counts.brokenPct.toStringAsFixed(1)}%)
  • Discolored: ${r.counts.discolored} (${r.counts.discoloredPct.toStringAsFixed(1)}%)

Generated by Chal.AI 🌾
''';
    Share.share(text);
  }

  void _exportMockPdf() {
    // Real PDF export would use printing or pdf packages.
    // This mock triggers the share sheet with a summary.
    _shareText();
  }
}
