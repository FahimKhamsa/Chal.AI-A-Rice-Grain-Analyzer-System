import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final s = ref.read(appStringsProvider);
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = s.enterEmailAndPassword);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signIn(email: email, password: password);
      if (mounted) context.go(AppRoutes.capture);
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyError(e.toString(), s));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String raw, AppStrings s) {
    if (raw.contains('Invalid login credentials')) {
      return s.invalidEmailOrPassword;
    }
    if (raw.contains('network')) return s.networkError;
    return s.somethingWentWrong;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Center(child: AppLogo(size: 50, showText: true)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  s.signInToContinue,
                  style: GoogleFonts.inter(
                    color: cs.onSurface.withValues(alpha: 0.54),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _ThemedTextField(
                controller: _emailCtrl,
                label: s.email,
                hint: s.emailPlaceholder,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _ThemedTextField(
                controller: _passCtrl,
                label: s.password,
                hint: s.passwordPlaceholder,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleEmailLogin(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: cs.onSurface.withValues(alpha: 0.38),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.brokenRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.brokenRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: GoogleFonts.inter(
                        color: AppTheme.brokenRed, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleEmailLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.healthyGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppTheme.healthyGreen.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(s.signIn,
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: Text(
                    s.forgotPassword,
                    style: GoogleFonts.inter(
                        color: AppTheme.healthyGreen, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${s.dontHaveAccount} ',
                    style: GoogleFonts.inter(
                        color: cs.onSurface.withValues(alpha: 0.38),
                        fontSize: 14)),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.signup),
                  child: Text(s.signUp,
                      style: GoogleFonts.inter(
                          color: AppTheme.healthyGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _ThemedTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: GoogleFonts.inter(color: cs.onSurface, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withValues(alpha: 0.24), fontSize: 15),
            filled: true,
            fillColor: isDark ? const Color(0xFF131E17) : Colors.white,
            suffixIcon: suffixIcon,
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
      ],
    );
  }
}
