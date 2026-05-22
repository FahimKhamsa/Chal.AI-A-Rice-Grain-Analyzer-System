import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../localization/app_strings.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/profile_provider.dart';

class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final profile = ref.watch(profileNotifierProvider).valueOrNull;
    final displayName = profile != null ? profile.fullName : email;
    final initials = profile != null
        ? '${profile.firstName[0]}${profile.lastName[0]}'.toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : 'U');

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void close() => Navigator.pop(context);

    void navigate(String route, {bool replace = false}) {
      close();
      if (replace) {
        context.go(route);
      } else {
        context.push(route);
      }
    }

    void confirmSignOut() {
      final authService = ref.read(authServiceProvider);
      close();
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131E17) : cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            s.signOutConfirmTitle,
            style: GoogleFonts.inter(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            s.signOutConfirmMessage,
            style: GoogleFonts.inter(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                s.cancel,
                style: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.54)),
              ),
            ),
            TextButton(
              onPressed: () => authService.signOut(),
              child: Text(
                s.signOut,
                style: GoogleFonts.inter(
                  color: AppTheme.brokenRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0D1F15) : cs.surface,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.healthyGreen.withAlpha(40),
                      border: Border.all(
                        color: AppTheme.healthyGreen.withAlpha(80),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        color: AppTheme.healthyGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 8),

            _SidebarItem(
              icon: Icons.person_outline_rounded,
              label: s.profile,
              isActive: currentLocation == AppRoutes.profile,
              onTap: () => navigate(AppRoutes.profile),
            ),
            _SidebarItem(
              icon: Icons.camera_alt_outlined,
              label: s.home,
              isActive: currentLocation == AppRoutes.capture,
              onTap: () => navigate(AppRoutes.capture, replace: true),
            ),
            _SidebarItem(
              icon: Icons.history_rounded,
              label: s.history,
              isActive: currentLocation == AppRoutes.history,
              onTap: () => navigate(AppRoutes.history),
            ),
            _SidebarItem(
              icon: Icons.settings_outlined,
              label: s.settings,
              isActive: currentLocation == AppRoutes.settings,
              onTap: () => navigate(AppRoutes.settings),
            ),
            _SidebarItem(
              icon: Icons.menu_book_outlined,
              label: s.userGuidelines,
              isActive: currentLocation == AppRoutes.guidelines,
              onTap: () => navigate(AppRoutes.guidelines),
            ),

            const Spacer(),
            Divider(color: cs.outlineVariant, height: 1),

            _SidebarItem(
              icon: Icons.logout_rounded,
              label: s.signOut,
              color: AppTheme.brokenRed,
              onTap: confirmSignOut,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemColor = isActive
        ? AppTheme.healthyGreen
        : (color ?? cs.onSurface.withValues(alpha: 0.7));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: isActive
          ? BoxDecoration(
              color: AppTheme.healthyGreen.withAlpha(22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.healthyGreen.withAlpha(50),
                width: 1,
              ),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: cs.onSurface.withValues(alpha: 0.06),
        highlightColor: cs.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: itemColor, size: 22),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: itemColor,
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
