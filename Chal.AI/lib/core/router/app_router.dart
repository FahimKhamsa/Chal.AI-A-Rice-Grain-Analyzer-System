// core/router/app_router.dart
// go_router setup. Uses a Riverpod provider so the router instance is
// accessible app-wide and can react to auth state changes in the future.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/presentation/screens/capture_screen.dart';
import '../../features/analysis/presentation/screens/analysis_result_screen.dart';
import '../../features/report/presentation/screens/detailed_report_screen.dart';
import '../../features/analysis/domain/models/analysis_result.dart';
import '../../features/splash/splash_screen.dart';

// Route name constants — use these instead of raw strings to prevent typos
class AppRoutes {
  static const String splash = '/splash';
  static const String capture = '/';
  static const String analysisResult = '/analysis';
  static const String report = '/report';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
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
          // Extra carries the AnalysisResult model (type-safe navigation)
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
