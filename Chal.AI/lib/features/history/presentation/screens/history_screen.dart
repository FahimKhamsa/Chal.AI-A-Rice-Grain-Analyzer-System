import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/analysis_record.dart';
import '../providers/history_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: Text(
          s.analysisHistory,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.healthyGreen)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: cs.onSurface.withValues(alpha: 0.38), size: 48),
              const SizedBox(height: 12),
              Text(s.failedToLoadHistory,
                  style: GoogleFonts.inter(
                      color: cs.onSurface.withValues(alpha: 0.54),
                      fontSize: 14)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(historyProvider),
                child: Text(s.retry,
                    style: GoogleFonts.inter(color: AppTheme.healthyGreen)),
              ),
            ],
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      color: cs.onSurface.withValues(alpha: 0.24), size: 64),
                  const SizedBox(height: 16),
                  Text(s.noAnalysesYet,
                      style: GoogleFonts.inter(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(s.savedAnalysesWillAppear,
                      style: GoogleFonts.inter(
                          color: cs.onSurface.withValues(alpha: 0.24),
                          fontSize: 13)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppTheme.healthyGreen,
            onRefresh: () async => ref.invalidate(historyProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _HistoryCard(
                record: records[index],
                onDelete: () =>
                    ref.read(historyProvider.notifier).delete(records[index].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerStatefulWidget {
  final AnalysisRecord record;
  final VoidCallback onDelete;

  const _HistoryCard({required this.record, required this.onDelete});

  @override
  ConsumerState<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends ConsumerState<_HistoryCard>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.record.status == AnalysisStatus.analysing) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_HistoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.record.status == AnalysisStatus.analysing) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }


  Future<void> _openRecord() async {
    if (widget.record.status != AnalysisStatus.completed) return;
    setState(() => _loading = true);
    try {
      final svc = ref.read(historyServiceProvider);
      final morphBytes = widget.record.morphologyImageUrl != null
          ? await svc.downloadImage(widget.record.morphologyImageUrl!)
          : null;
      final colorBytes = widget.record.colorImageUrl != null
          ? await svc.downloadImage(widget.record.colorImageUrl!)
          : null;
      if (!mounted) return;
      context.push(
        AppRoutes.analysisResult,
        extra: widget.record.toAnalysisResult(
          morphologyImageBytes: morphBytes,
          colorImageBytes: colorBytes,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = widget.record.status;
    final dateStr = _formatDate(widget.record.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_loading || status == AnalysisStatus.analysing) ? null : _openRecord,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131E17) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: status == AnalysisStatus.analysing
                  ? AppTheme.discoloredAmber.withValues(alpha: 0.5)
                  : status == AnalysisStatus.failed
                      ? AppTheme.brokenRed.withValues(alpha: 0.4)
                      : cs.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              // ── Left status widget ──────────────────────────────────────
              _StatusBadge(
                record: widget.record,
                pulseAnim: _pulseAnim,
              ),

              const SizedBox(width: 14),

              // ── Text info ───────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.batchName,
                      style: GoogleFonts.inter(
                          color: cs.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    _SubtitleText(record: widget.record, s: s),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                          color: cs.onSurface.withValues(alpha: 0.38),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ── Right trailing ──────────────────────────────────────────
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.healthyGreen),
                )
              else if (status == AnalysisStatus.completed)
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withValues(alpha: 0.24), size: 20),

              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: cs.onSurface.withValues(alpha: 0.24), size: 20),
                onPressed: () => _confirmDelete(context, s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m $ampm';
  }

  void _confirmDelete(BuildContext context, AppStrings s) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131E17) : cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.deleteRecord,
            style: GoogleFonts.inter(
                color: cs.onSurface, fontWeight: FontWeight.w700)),
        content: Text(s.deleteConfirmMessage,
            style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.54), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel,
                style: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.54))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete();
            },
            child: Text(s.delete,
                style: GoogleFonts.inter(
                    color: AppTheme.brokenRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Status badge widget ───────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final AnalysisRecord record;
  final Animation<double> pulseAnim;

  const _StatusBadge({required this.record, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    final status = record.status;

    if (status == AnalysisStatus.analysing) {
      return AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, __) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.discoloredAmber
                .withValues(alpha: 0.08 + pulseAnim.value * 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.discoloredAmber
                  .withValues(alpha: 0.3 + pulseAnim.value * 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: AppTheme.discoloredAmber
                      .withValues(alpha: 0.5 + pulseAnim.value * 0.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '…',
                style: TextStyle(
                  color: AppTheme.discoloredAmber,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status == AnalysisStatus.failed) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.brokenRed.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.brokenRed.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppTheme.brokenRed, size: 22),
          ],
        ),
      );
    }

    // Completed — show integrity score
    final score = record.integrityScore;
    final scoreColor = score >= 80
        ? AppTheme.healthyGreen
        : score >= 60
            ? AppTheme.discoloredAmber
            : AppTheme.brokenRed;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toStringAsFixed(0),
            style: GoogleFonts.inter(
                color: scoreColor, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text('%',
              style: GoogleFonts.inter(
                  color: scoreColor.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Subtitle text (status-aware) ──────────────────────────────────────────────

class _SubtitleText extends StatelessWidget {
  final AnalysisRecord record;
  final AppStrings s;

  const _SubtitleText({required this.record, required this.s});

  @override
  Widget build(BuildContext context) {
    final status = record.status;

    if (status == AnalysisStatus.analysing) {
      return Text(
        s.statusAnalysing,
        style: GoogleFonts.inter(
            color: AppTheme.discoloredAmber,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
    }

    if (status == AnalysisStatus.failed) {
      return Text(
        s.statusFailed,
        style: GoogleFonts.inter(
            color: AppTheme.brokenRed,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
    }

    // Completed
    return Text(
      record.detectedVariety.isNotEmpty
          ? record.detectedVariety
          : s.unknownVariety,
      style: GoogleFonts.inter(
          color: AppTheme.healthyGreen,
          fontSize: 12,
          fontWeight: FontWeight.w500),
    );
  }
}
