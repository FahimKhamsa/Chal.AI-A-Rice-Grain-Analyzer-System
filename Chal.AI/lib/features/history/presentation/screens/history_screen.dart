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
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _HistoryCard(
              record: records[index],
              onDelete: () =>
                  ref.read(historyProvider.notifier).delete(records[index].id),
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

class _HistoryCardState extends ConsumerState<_HistoryCard> {
  bool _loading = false;

  Color _scoreColor(double score) {
    if (score >= 80) return AppTheme.healthyGreen;
    if (score >= 60) return AppTheme.discoloredAmber;
    return AppTheme.brokenRed;
  }

  Future<void> _openRecord() async {
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
    final score = widget.record.integrityScore;
    final scoreColor = _scoreColor(score);
    final dateStr = _formatDate(widget.record.createdAt.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _loading ? null : _openRecord,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131E17) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
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
                          color: scoreColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800),
                    ),
                    Text('%',
                        style: GoogleFonts.inter(
                            color: scoreColor.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
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
                    Text(
                      widget.record.detectedVariety.isNotEmpty
                          ? widget.record.detectedVariety
                          : s.unknownVariety,
                      style: GoogleFonts.inter(
                          color: AppTheme.healthyGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
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
              if (_loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.healthyGreen),
                )
              else
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
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
