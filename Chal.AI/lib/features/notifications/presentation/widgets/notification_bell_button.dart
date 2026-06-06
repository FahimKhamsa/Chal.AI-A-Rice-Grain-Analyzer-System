import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../presentation/providers/notification_provider.dart';
import 'notification_panel.dart';

class NotificationBellButton extends ConsumerWidget {
  final Color? iconColor;
  final Color? backgroundColor;

  const NotificationBellButton({
    super.key,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final unreadCount = ref.watch(
      notificationProvider.select((state) => state.unreadCount),
    );
    final cs = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? cs.onSurface;

    final button = IconButton(
      tooltip: s.notifications,
      onPressed: () => showNotificationPanel(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unreadCount > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: effectiveIconColor,
            size: 24,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: _UnreadBadge(count: unreadCount),
            ),
        ],
      ),
    );

    if (backgroundColor == null) return button;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: button,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
