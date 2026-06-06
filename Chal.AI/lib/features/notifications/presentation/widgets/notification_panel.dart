import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/app_notification.dart';
import '../providers/notification_provider.dart';

Future<void> showNotificationPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NotificationPanel(),
  );
}

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1F15) : cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.notifications,
                            style: GoogleFonts.inter(
                              color: cs.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.notificationUnreadCount(state.unreadCount),
                            style: GoogleFonts.inter(
                              color: cs.onSurface.withValues(alpha: 0.48),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.unreadCount > 0)
                      TextButton(
                        onPressed: () => ref
                            .read(notificationProvider.notifier)
                            .markAllRead(),
                        child: Text(s.markAllRead),
                      ),
                    if (!state.isEmpty)
                      TextButton(
                        onPressed: () =>
                            ref.read(notificationProvider.notifier).clearAll(),
                        child: Text(
                          s.clearAll,
                          style: GoogleFonts.inter(
                            color: AppTheme.brokenRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(color: cs.outlineVariant, height: 1),
              Expanded(
                child: _NotificationBody(
                  state: state,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationBody extends ConsumerWidget {
  final NotificationState state;
  final ScrollController scrollController;

  const _NotificationBody({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.healthyGreen),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: cs.onSurface.withValues(alpha: 0.22),
                size: 56,
              ),
              const SizedBox(height: 14),
              Text(
                s.noNotificationsYet,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: cs.onSurface.withValues(alpha: 0.48),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.notificationsWillAppear,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: cs.onSurface.withValues(alpha: 0.32),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _NotificationTile(notification: state.notifications[index]);
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorFor(notification.type);
    final unread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleTap(context, ref),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread
                ? color.withValues(alpha: isDark ? 0.16 : 0.10)
                : (isDark ? const Color(0xFF131E17) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? color.withValues(alpha: 0.36) : cs.outlineVariant,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(_iconFor(notification.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleFor(notification.type, s),
                            style: GoogleFonts.inter(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight:
                                  unread ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _messageFor(notification, s),
                      style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.58),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (notification.errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.errorMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: cs.onSurface.withValues(alpha: 0.40),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      s.notificationTimeAgo(notification.createdAt),
                      style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.34),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: s.delete,
                visualDensity: VisualDensity.compact,
                onPressed: () => ref
                    .read(notificationProvider.notifier)
                    .delete(notification.id),
                icon: Icon(
                  Icons.close_rounded,
                  color: cs.onSurface.withValues(alpha: 0.30),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    await ref.read(notificationProvider.notifier).markRead(notification.id);

    if (!context.mounted) return;
    if (notification.type == AppNotificationType.analysisCompleted ||
        notification.type == AppNotificationType.historySaveFailed) {
      Navigator.of(context).pop();
      router.push(AppRoutes.history);
    }
  }

  IconData _iconFor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.analysisCompleted => Icons.check_circle_rounded,
      AppNotificationType.analysisFailed => Icons.error_outline_rounded,
      AppNotificationType.historySaveFailed => Icons.cloud_off_rounded,
    };
  }

  Color _colorFor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.analysisCompleted => AppTheme.healthyGreen,
      AppNotificationType.analysisFailed => AppTheme.brokenRed,
      AppNotificationType.historySaveFailed => AppTheme.discoloredAmber,
    };
  }

  String _titleFor(AppNotificationType type, AppStrings s) {
    return switch (type) {
      AppNotificationType.analysisCompleted =>
        s.analysisCompletedNotificationTitle,
      AppNotificationType.analysisFailed => s.analysisFailedNotificationTitle,
      AppNotificationType.historySaveFailed =>
        s.historySaveFailedNotificationTitle,
    };
  }

  String _messageFor(AppNotification notification, AppStrings s) {
    return switch (notification.type) {
      AppNotificationType.analysisCompleted =>
        s.analysisCompletedNotificationMessage(
          notification.batchName,
          (notification.integrityScore ?? 0).toStringAsFixed(1),
        ),
      AppNotificationType.analysisFailed =>
        s.analysisFailedNotificationMessage(notification.batchName),
      AppNotificationType.historySaveFailed =>
        s.historySaveFailedNotificationMessage(notification.batchName),
    };
  }
}
