import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final lang = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isBn = lang == 'bn';
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sectionLabelStyle = GoogleFonts.inter(
      color: cs.onSurface.withValues(alpha: 0.4),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );

    final cardDecoration = BoxDecoration(
      color: isDark ? const Color(0xFF131E17) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant),
    );

    return Scaffold(
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: Text(
          s.settings,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // ── Appearance section ──────────────────────────────────────
            Text(s.appearance.toUpperCase(), style: sectionLabelStyle),
            const SizedBox(height: 8),
            Container(
              decoration: cardDecoration,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined,
                        color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.theme,
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _themeModeLabel(themeMode, isDark),
                          style: GoogleFonts.inter(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _ThemeSegmentedButton(
                        themeMode: themeMode, ref: ref, cs: cs),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Language section ────────────────────────────────────────
            Text(s.language.toUpperCase(), style: sectionLabelStyle),
            const SizedBox(height: 8),
            Container(
              decoration: cardDecoration,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.language_rounded,
                        color: cs.onSurface.withValues(alpha: 0.4), size: 20),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.language,
                          style: GoogleFonts.inter(
                            color: cs.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBn ? 'বাংলা' : 'English',
                          style: GoogleFonts.inter(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _LangSegmentedButton(isBn: isBn, ref: ref, cs: cs),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── About section ────────────────────────────────────────────
            Text(s.about.toUpperCase(), style: sectionLabelStyle),
            const SizedBox(height: 8),
            Container(
              decoration: cardDecoration,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: s.appName,
                    subtitle: s.appTagline,
                    cs: cs,
                  ),
                  Divider(color: cs.outlineVariant, height: 1, indent: 56),
                  _SettingsTile(
                    icon: Icons.verified_outlined,
                    title: s.version,
                    subtitle: '1.0.0',
                    cs: cs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode, bool isDark) {
    return switch (mode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => isDark ? 'System (Dark)' : 'System (Light)',
    };
  }
}

// ── Three-way Theme Segment ────────────────────────────────────────────────

class _ThemeSegmentedButton extends StatelessWidget {
  final ThemeMode themeMode;
  final WidgetRef ref;
  final ColorScheme cs;
  const _ThemeSegmentedButton(
      {required this.themeMode, required this.ref, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeSeg(
            icon: Icons.brightness_auto_rounded,
            active: themeMode == ThemeMode.system,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.system),
            cs: cs,
          ),
          _ThemeSeg(
            icon: Icons.light_mode_rounded,
            active: themeMode == ThemeMode.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.light),
            cs: cs,
          ),
          _ThemeSeg(
            icon: Icons.dark_mode_rounded,
            active: themeMode == ThemeMode.dark,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setThemeMode(ThemeMode.dark),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _ThemeSeg extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _ThemeSeg(
      {required this.icon,
      required this.active,
      required this.onTap,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.healthyGreen.withAlpha(220)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : cs.onSurface.withValues(alpha: 0.38),
          size: 16,
        ),
      ),
    );
  }
}

// ── Language Segment ──────────────────────────────────────────────────────

class _LangSegmentedButton extends StatelessWidget {
  final bool isBn;
  final WidgetRef ref;
  final ColorScheme cs;
  const _LangSegmentedButton(
      {required this.isBn, required this.ref, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Seg(
            label: 'EN',
            active: !isBn,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('en'),
          ),
          _Seg(
            label: 'বাং',
            active: isBn,
            onTap: () => ref.read(languageProvider.notifier).setLanguage('bn'),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.healthyGreen.withAlpha(220)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurface.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: cs.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: cs.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
