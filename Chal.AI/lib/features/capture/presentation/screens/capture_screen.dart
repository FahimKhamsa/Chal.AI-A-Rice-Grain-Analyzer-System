import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../analysis/domain/models/analysis_result.dart';
import '../providers/capture_provider.dart';
import '../widgets/analyzing_overlay.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final _batchController = TextEditingController(text: '');
  late AnimationController _entryCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _batchController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(captureProvider);
    final notifier = ref.read(captureProvider.notifier);
    final s = ref.watch(appStringsProvider);
    final mq = MediaQuery.of(context);

    ref.listen(captureProvider, (prev, next) {
      if (next.status == CaptureStatus.done && next.result != null) {
        context.push(AppRoutes.analysisResult, extra: next.result);
        Future.delayed(const Duration(milliseconds: 600), notifier.reset);
      } else if (next.status == CaptureStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        notifier.reset();
      }
      if (next.historySaveError != null && prev?.historySaveError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.couldNotSaveRecord}: ${next.historySaveError}'),
            backgroundColor: AppTheme.brokenRed,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    const _Header(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Hero capture card ────────────────────
                            _HeroCaptureCard(
                              imageBytes: state.imageBytes,
                              onCameraTap: () => notifier.captureFromCamera(),
                              s: s,
                            ),

                            const SizedBox(height: 20),

                            // ── Batch name field ─────────────────────
                            _BatchSection(
                              controller: _batchController,
                              onChanged: notifier.setBatchName,
                              s: s,
                            ),

                            const SizedBox(height: 20),

                            // ── Action buttons ───────────────────────
                            _ActionButtons(
                              onGallery: () => notifier.pickFromGallery(),
                              onDemo: () {
                                final name =
                                    _batchController.text.trim().isEmpty
                                        ? s.batchADefault
                                        : _batchController.text.trim();
                                context.push(
                                  AppRoutes.analysisResult,
                                  extra: AnalysisResult.mock(batchName: name),
                                );
                              },
                              s: s,
                            ),

                            const SizedBox(height: 20),

                            // ── Tip ──────────────────────────────────
                            _Tip(s: s),

                            SizedBox(height: mq.padding.bottom + 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (state.status == CaptureStatus.analyzing) const AnalyzingOverlay(),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 12, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu_rounded,
                  color: Theme.of(ctx).colorScheme.onSurface, size: 24),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const AppLogo(size: 36, showText: true),
          const Spacer(),
          const _LangToggleButton(),
        ],
      ),
    );
  }
}

// ─── Language Toggle Pill ─────────────────────────────────────────────────────

class _LangToggleButton extends ConsumerWidget {
  const _LangToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isBn = lang == 'bn';

    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).toggle(),
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF131E17)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LangPill(label: 'EN', active: !isBn),
            _LangPill(label: 'বাং', active: isBn),
          ],
        ),
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool active;
  const _LangPill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            active ? AppTheme.healthyGreen.withAlpha(220) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Hero Capture Card ────────────────────────────────────────────────────────

class _HeroCaptureCard extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onCameraTap;
  final AppStrings s;
  const _HeroCaptureCard({
    required this.imageBytes,
    required this.onCameraTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return GestureDetector(
      onTap: onCameraTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 260,
        decoration: BoxDecoration(
          color: hasImage
              ? Colors.transparent
              : (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF131E17)
                  : Theme.of(context).colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasImage
                ? Colors.transparent
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            s.retake,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.healthyGreen.withAlpha(24),
                      border: Border.all(
                        color: AppTheme.healthyGreen.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.healthyGreen.withAlpha(230),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.tapToCapture,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.photoAnalyzedByAi,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Batch Section ────────────────────────────────────────────────────────────

class _BatchSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppStrings s;
  const _BatchSection({
    required this.controller,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.batchName,
          style: TextStyle(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF131E17)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.tag_rounded,
                size: 17,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.38),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppTheme.healthyGreen,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: s.batchNameHint,
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.24),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onDemo;
  final AppStrings s;
  const _ActionButtons({
    required this.onGallery,
    required this.onDemo,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineBtn(
            icon: Icons.photo_library_outlined,
            label: s.fromGallery,
            onTap: onGallery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OutlineBtn(
            icon: Icons.play_arrow_rounded,
            label: s.runDemo,
            onTap: onDemo,
            accent: true,
          ),
        ),
      ],
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;
  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = accent
        ? AppTheme.healthyGreen.withAlpha(22)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05);
    final border = accent
        ? AppTheme.healthyGreen.withAlpha(100)
        : Theme.of(context).colorScheme.outlineVariant;
    final iconColor = accent
        ? AppTheme.healthyGreen
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final textColor = accent
        ? AppTheme.healthyGreen
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tip card ─────────────────────────────────────────────────────────────────

class _Tip extends StatelessWidget {
  final AppStrings s;
  const _Tip({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF131E17)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 16, color: AppTheme.discoloredAmber.withAlpha(200)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.captureTip,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.47),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
