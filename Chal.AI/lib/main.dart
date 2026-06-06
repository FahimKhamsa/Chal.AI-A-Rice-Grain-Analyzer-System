// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/api_config.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/data/services/native_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NativeNotificationService.instance.initialize();

  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    const ProviderScope(
      child: ChalAiApp(),
    ),
  );
}

class ChalAiApp extends ConsumerStatefulWidget {
  const ChalAiApp({super.key});

  @override
  ConsumerState<ChalAiApp> createState() => _ChalAiAppState();
}

class _ChalAiAppState extends ConsumerState<ChalAiApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NativeNotificationService.instance.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final lang = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen(authEventStreamProvider, (_, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        router.go(AppRoutes.resetPassword);
      }
    });

    return MaterialApp.router(
      title: 'Chal.AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      locale: Locale(lang),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('bn'),
      ],
    );
  }
}
