import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const AppLogo({super.key, this.size = 90, this.showText = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: size,
        height: size,
      ),
    );

    if (!showText) return logo;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Chal',
                style: GoogleFonts.inter(
                  color: cs.onSurface,
                  fontSize: (size * 0.55).clamp(16.0, 30.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: '.AI',
                style: GoogleFonts.inter(
                  color: AppTheme.healthyGreen,
                  fontSize: (size * 0.55).clamp(16.0, 30.0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
