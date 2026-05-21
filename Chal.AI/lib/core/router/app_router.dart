import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/capture/presentation/screens/capture_screen.dart';
import '../../features/analysis/presentation/screens/analysis_result_screen.dart';
import '../../features/report/presentation/screens/detailed_report_screen.dart';
import '../../features/analysis/domain/models/analysis_result.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/splash/splash_screen.dart';

// Route path constants — use these instead of raw strings to prevent typos
class AppRoutes {
  static const String splash = '/splash';
  static const String capture = '/';
  static const String analysisResult = '/analysis';
  static const String report = '/report';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String history = '/history';
}

// Bridges the Riverpod authStateProvider stream to GoRouter's ChangeNotifier-
// based refreshListenable so redirects re-run on every auth state change.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      // Don't redirect while auth state is still loading
      if (authState.isLoading) return null;

      final isAuthenticated = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      // Splash manages its own navigation after the delay
      if (loc == AppRoutes.splash) return null;

      final onAuthScreen = loc == AppRoutes.login || loc == AppRoutes.signup || loc == AppRoutes.forgotPassword;

      if (!isAuthenticated && !onAuthScreen) return AppRoutes.login;
      if (isAuthenticated && onAuthScreen) return AppRoutes.capture;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.capture,
        name: 'capture',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const CaptureScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.analysisResult,
        name: 'analysis',
        pageBuilder: (context, state) {
          final result = state.extra as AnalysisResult;
          return _buildPage(
            key: state.pageKey,
            child: AnalysisResultScreen(result: result),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.report,
        name: 'report',
        pageBuilder: (context, state) {
          final result = state.extra as AnalysisResult;
          return _buildPage(
            key: state.pageKey,
            child: DetailedReportScreen(result: result),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const SignupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => _buildPage(
          key: state.pageKey,
          child: const HistoryScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.error}')),
    ),
  );
});

// Custom slide-up page transition for a polished feel
CustomTransitionPage<void> _buildPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurveTween(curve: Curves.easeOutCubic);
      final slide = Tween(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).chain(curve);
      final fade = Tween(begin: 0.0, end: 1.0).chain(curve);
      return SlideTransition(
        position: animation.drive(slide),
        child: FadeTransition(
          opacity: animation.drive(fade),
          child: child,
        ),
      );
    },
  );
}
