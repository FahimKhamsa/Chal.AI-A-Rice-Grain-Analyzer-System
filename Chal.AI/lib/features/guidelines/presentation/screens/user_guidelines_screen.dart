import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_sidebar.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';

class UserGuidelinesScreen extends ConsumerWidget {
  const UserGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sectionLabelStyle = GoogleFonts.inter(
      color: cs.onSurface.withValues(alpha: 0.5),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    return Scaffold(
      drawer: const AppSidebar(),
      appBar: AppBar(
        title: Text(
          s.userGuidelines,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [
          NotificationBellButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // ── Hero card ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: _HeroCard(s: s),
            ),
            const SizedBox(height: 8),

            // ── Getting Started (Timeline) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(s.guideGettingStarted.toUpperCase(),
                  style: sectionLabelStyle),
            ),
            const SizedBox(height: 16),
            _TimelineSection(
              cs: cs,
              isDark: isDark,
              steps: [
                _StepData(
                  number: 1,
                  title: s.guideStepOpenApp,
                  description: s.guideStepOpenAppDesc,
                  icon: Icons.apps_rounded,
                ),
                _StepData(
                  number: 2,
                  title: s.guideStepCreateAccount,
                  description: s.guideStepCreateAccDesc,
                  icon: Icons.person_add_outlined,
                ),
                _StepData(
                  number: 3,
                  title: s.guideStepSetupProfile,
                  description: s.guideStepSetupProfDesc,
                  icon: Icons.edit_outlined,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Capturing Rice Grains (Timeline) ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(s.guideCapturing.toUpperCase(),
                  style: sectionLabelStyle),
            ),
            const SizedBox(height: 16),
            _TimelineSection(
              cs: cs,
              isDark: isDark,
              steps: [
                _StepData(
                  number: 1,
                  title: s.guideStepPrepareSetup,
                  description: s.guideStepPrepareDesc,
                  icon: Icons.table_restaurant_outlined,
                ),
                _StepData(
                  number: 2,
                  title: s.guideStepTakePhoto,
                  description: s.guideStepTakePhotoDesc,
                  icon: Icons.camera_alt_outlined,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
                _StepData(
                  number: 3,
                  title: s.guideStepOrGallery,
                  description: s.guideStepOrGalleryDesc,
                  icon: Icons.photo_library_outlined,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
                _StepData(
                  number: 4,
                  title: s.guideStepNameBatch,
                  description: s.guideStepNameBatchDesc,
                  icon: Icons.label_outline_rounded,
                  tapHintIcon: Icons.keyboard_outlined,
                ),
                _StepData(
                  number: 5,
                  title: s.guideStepStartAnalysis,
                  description: s.guideStepStartAnalDesc,
                  icon: Icons.play_circle_outline_rounded,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _TipCallout(isDark: isDark, text: s.captureTip),
            ),
            const SizedBox(height: 32),

            // ── Understanding Results (Grid Boxes) ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child:
                  Text(s.guideResults.toUpperCase(), style: sectionLabelStyle),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ResultsSection(s: s, isDark: isDark),
            ),
            const SizedBox(height: 36),

            // ── History & Reports (Timeline) ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child:
                  Text(s.guideHistory.toUpperCase(), style: sectionLabelStyle),
            ),
            const SizedBox(height: 16),
            _TimelineSection(
              cs: cs,
              isDark: isDark,
              steps: [
                _StepData(
                  number: 1,
                  title: s.guideStepOpenHistory,
                  description: s.guideStepOpenHistDesc,
                  icon: Icons.menu_rounded,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
                _StepData(
                  number: 2,
                  title: s.guideStepViewRecord,
                  description: s.guideStepViewRecordDesc,
                  icon: Icons.history_rounded,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
                _StepData(
                  number: 3,
                  title: s.guideStepExportPdf,
                  description: s.guideStepExportPdfDesc,
                  icon: Icons.picture_as_pdf_outlined,
                  tapHintIcon: Icons.touch_app_rounded,
                ),
                _StepData(
                  number: 4,
                  title: s.guideStepDeleteRecord,
                  description: s.guideStepDeleteRecordDesc,
                  icon: Icons.delete_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Pro Tips (Horizontal Scroll) ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child:
                  Text(s.guideProTips.toUpperCase(), style: sectionLabelStyle),
            ),
            const SizedBox(height: 16),
            _ProTipsCarousel(s: s, isDark: isDark, cs: cs),
          ],
        ),
      ),
    );
  }
}

// ── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final AppStrings s;
  const _HeroCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.healthyGreen.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        gradient: LinearGradient(
          colors: [
            AppTheme.healthyGreen,
            const Color(0xFF1E8F4D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: const Text('🌾', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.userGuidelines,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.guidelinesSubtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Data Model ──────────────────────────────────────────────────────────

class _StepData {
  final int number;
  final String title;
  final String description;
  final IconData icon;
  final IconData? tapHintIcon;

  const _StepData({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.tapHintIcon,
  });
}

// ── Timeline UI Components ───────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  final List<_StepData> steps;

  const _TimelineSection({
    required this.cs,
    required this.isDark,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(steps.length, (index) {
          final isLast = index == steps.length - 1;
          return _TimelineStep(
            step: steps[index],
            isLast: isLast,
            cs: cs,
            isDark: isDark,
          );
        }),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final _StepData step;
  final bool isLast;
  final ColorScheme cs;
  final bool isDark;

  const _TimelineStep({
    required this.step,
    required this.isLast,
    required this.cs,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Line and Number
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.healthyGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.healthyGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '${step.number}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              if (isLast) const SizedBox(height: 16),
            ],
          ),
          const SizedBox(width: 16),
          // Right side: Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16221A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(step.icon, size: 18, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.title,
                            style: GoogleFonts.inter(
                              color: cs.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (step.tapHintIcon != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.healthyGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(step.tapHintIcon,
                                    size: 12, color: AppTheme.healthyGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.healthyGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tip Callout ──────────────────────────────────────────────────────────────

class _TipCallout extends StatelessWidget {
  final bool isDark;
  final String text;

  const _TipCallout({required this.isDark, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.discoloredAmber.withValues(alpha: 0.1)
            : AppTheme.discoloredAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.discoloredAmber.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.discoloredAmber.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lightbulb_outline_rounded,
                color:
                    isDark ? AppTheme.discoloredAmber : const Color(0xFFB45309),
                size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color:
                    isDark ? AppTheme.discoloredAmber : const Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results Section (Grid View with Fixed Height) ────────────────────────────

class _ResultsSection extends StatelessWidget {
  final AppStrings s;
  final bool isDark;

  const _ResultsSection({required this.s, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Exact mapping from analysis_result_screen.dart colors and icons.
    // Included inline translations to save you from having to modify AppStrings again.
    final tiles = [
      _ResultTile(
        color: AppTheme.healthyGreen,
        label: s.healthy,
        description: s.isBn
            ? 'পরিপূর্ণ ও অক্ষত দানা। সবুজ রঙে নির্দেশিত।'
            : 'Complete, intact grains. Shown in green.',
        icon: Icons.check_circle_rounded,
        isDark: isDark,
      ),
      _ResultTile(
        color: const Color(0xFFFFD600), // 3/4 Broken color
        label: s.threeQuarterBroken,
        description: s.isBn
            ? 'চার ভাগের তিন ভাগ অক্ষত থাকা দানা। হলুদ রঙে নির্দেশিত।'
            : 'Grains that are ¾ intact. Shown in yellow.',
        icon: Icons.broken_image_rounded,
        isDark: isDark,
      ),
      _ResultTile(
        color: AppTheme.brokenRed, // Half broken color
        label: s.halfBroken,
        description: s.isBn
            ? 'অর্ধেক বা তার বেশি ভাঙা দানা। লাল রঙে নির্দেশিত।'
            : 'Grains broken in half or more. Shown in red.',
        icon: Icons.broken_image_outlined,
        isDark: isDark,
      ),
      _ResultTile(
        color: const Color(0xFFDD44FF), // Impurity color
        label: s.impurity,
        description: s.isBn
            ? 'ধান, পাথর বা অন্যান্য অপদ্রব্য। বেগুনি রঙে নির্দেশিত।'
            : 'Paddy, stones, or other foreign matter. Shown in purple.',
        icon: Icons.warning_amber_rounded,
        isDark: isDark,
      ),
      _ResultTile(
        color: const Color(0xFF4488FF), // Discolored color
        label: s.discolored,
        description: s.isBn
            ? 'অস্বাভাবিক রং বা দাগযুক্ত দানা। নীল রঙে নির্দেশিত।'
            : 'Grains with unusual color or stains. Shown in blue.',
        icon: Icons.palette_rounded,
        isDark: isDark,
      ),
      _ResultTile(
        color: AppTheme.integrityBlue,
        label: s.integrityScore,
        description: s.isBn
            ? 'সামগ্রিক গুণমান (০–১০০%)। নীল গেজে নির্দেশিত।'
            : 'Overall quality (0–100%). Shown in blue gauge.',
        icon: Icons.speed_rounded,
        isDark: isDark,
      ),
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      // Using mainAxisExtent strictly enforces the card height, preventing overflow!
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 165,
      ),
      itemBuilder: (context, index) => tiles[index],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Color color;
  final String label;
  final String description;
  final IconData icon;
  final bool isDark;

  const _ResultTile({
    required this.color,
    required this.label,
    required this.description,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.05)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // Expanded guarantees the text will use exactly the remaining space inside the 165px height without breaking
          Expanded(
            child: Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pro Tips Carousel (Horizontal) ───────────────────────────────────────────

class _ProTipsCarousel extends StatelessWidget {
  final AppStrings s;
  final bool isDark;
  final ColorScheme cs;

  const _ProTipsCarousel(
      {required this.s, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    final tips = [s.guideTip1, s.guideTip2, s.guideTip3, s.guideTip4];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 260,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F2B) : const Color(0xFFF3F6fb),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.integrityBlue.withValues(alpha: 0.2),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: AppTheme.integrityBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tip #${index + 1}',
                      style: GoogleFonts.inter(
                        color: AppTheme.integrityBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    tips[index],
                    style: GoogleFonts.inter(
                      color: cs.onSurface.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
