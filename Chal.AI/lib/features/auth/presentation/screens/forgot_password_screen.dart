import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _sentEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final s = ref.read(appStringsProvider);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.enterEmailAddress, style: GoogleFonts.inter()),
          backgroundColor: AppTheme.brokenRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _sent = true;
          _sentEmail = email;
        });
      }
    } catch (e) {
      if (mounted) {
        final errS = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(errS.couldNotSendResetEmail, style: GoogleFonts.inter()),
            backgroundColor: AppTheme.brokenRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _sent
              ? _SuccessView(email: _sentEmail!, s: s)
              : _FormView(
                  emailCtrl: _emailCtrl,
                  loading: _loading,
                  onSend: _handleSend,
                  s: s,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  final AppStrings s;

  const _FormView({
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Center(child: AppLogo(size: 50, showText: true)),
        const SizedBox(height: 24),
        Text(
          s.resetYourPassword,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: cs.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          s.forgotPasswordSubtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 14,
              height: 1.5),
        ),
        const SizedBox(height: 36),
        Text(s.email,
            style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSend(),
          style: GoogleFonts.inter(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: s.emailPlaceholder,
            hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.24), fontSize: 15),
            filled: true,
            fillColor: isDark ? const Color(0xFF131E17) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.healthyGreen, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : onSend,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.healthyGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppTheme.healthyGreen.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(s.sendResetLink,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final AppStrings s;
  const _SuccessView({required this.email, required this.s});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.healthyGreen.withValues(alpha: 0.12),
            border:
                Border.all(color: AppTheme.healthyGreen.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppTheme.healthyGreen, size: 32),
        ),
        const SizedBox(height: 28),
        Text(
          s.checkYourInbox,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: cs.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          '${s.resetLinkSentTo}\n$email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: cs.onSurface.withValues(alpha: 0.54),
              fontSize: 14,
              height: 1.6),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF131E17) : cs.surfaceContainerHighest,
              foregroundColor: cs.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant),
              ),
              elevation: 0,
            ),
            child: Text(s.backToLogin,
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
