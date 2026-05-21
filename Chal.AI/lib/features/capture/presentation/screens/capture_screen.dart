// features/capture/presentation/screens/capture_screen.dart
// Screen A — Complete restructure.
// Layout: Logo header → Hero capture card → Batch field → Two action buttons
// No scan lines, no corner brackets, no overlapping overlays.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final mq = MediaQuery.of(context);

    ref.listen(captureProvider, (prev, next) {
      if (next.status == CaptureStatus.done && next.result != null) {
        context.push(AppRoutes.analysisResult, extra: next.result);
        Future.delayed(const Duration(milliseconds: 600), notifier.reset);
      } else if (next.status == CaptureStatus.error && next.errorMessage != null) {
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
            content: Text('Could not save record: ${next.historySaveError}'),
            backgroundColor: AppTheme.brokenRed,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0B1410),
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
                            ),

                            const SizedBox(height: 20),

                            // ── Batch name field ─────────────────────
                            _BatchSection(
                              controller: _batchController,
                              onChanged: notifier.setBatchName,
                            ),

                            const SizedBox(height: 20),

                            // ── Action buttons ───────────────────────
                            _ActionButtons(
                              onGallery: () => notifier.pickFromGallery(),
                              onDemo: () {
                                final name =
                                    _batchController.text.trim().isEmpty
                                        ? 'Batch A'
                                        : _batchController.text.trim();
                                context.push(
                                  AppRoutes.analysisResult,
                                  extra: AnalysisResult.mock(batchName: name),
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // ── Tip ──────────────────────────────────
                            _Tip(),

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

          if (state.status == CaptureStatus.analyzing)
            const AnalyzingOverlay(),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 20, 8),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          const AppLogo(size: 36, showText: true),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Hero Capture Card ────────────────────────────────────────────────────────
// Large tappable card — camera icon when empty, image preview when a photo
// has been picked. Uses Image.memory so it works on web and native.

class _HeroCaptureCard extends StatelessWidget {
  final Uint8List? imageBytes;
  final VoidCallback onCameraTap;
  const _HeroCaptureCard(
      {required this.imageBytes, required this.onCameraTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return GestureDetector(
      onTap: onCameraTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 260,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : const Color(0xFF131E17),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: hasImage
                ? Colors.transparent
                : Colors.white.withAlpha(18),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes!, fit: BoxFit.cover),
                  // Tap-to-retake overlay
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Retake',
                            style: TextStyle(
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
                  // Camera icon in a soft circle
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
                  const Text(
                    'Tap to capture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Photo will be analyzed by AI',
                    style: TextStyle(
                      color: Colors.white.withAlpha(100),
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
  const _BatchSection(
      {required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch name',
          style: TextStyle(
            color: Colors.white.withAlpha(130),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF131E17),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(18), width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(
                Icons.tag_rounded,
                size: 17,
                color: Colors.white.withAlpha(100),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppTheme.healthyGreen,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    hintText: 'e.g. Batch A, Field 3',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(60),
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
// Two equal-weight buttons side by side.

class _ActionButtons extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onDemo;
  const _ActionButtons(
      {required this.onGallery, required this.onDemo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OutlineBtn(
            icon: Icons.photo_library_outlined,
            label: 'From Gallery',
            onTap: onGallery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OutlineBtn(
            icon: Icons.play_arrow_rounded,
            label: 'Run Demo',
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
        : Colors.white.withAlpha(8);
    final border = accent
        ? AppTheme.healthyGreen.withAlpha(100)
        : Colors.white.withAlpha(20);
    final iconColor = accent ? AppTheme.healthyGreen : Colors.white60;
    final textColor = accent ? AppTheme.healthyGreen : Colors.white70;

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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131E17),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(12), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              size: 16,
              color: AppTheme.discoloredAmber.withAlpha(200)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'For best results, place grains on a white surface in good natural light.',
              style: TextStyle(
                color: Colors.white.withAlpha(120),
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
