import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/models/app_notification.dart';

abstract class NativeNotificationClient {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> show(AppNotification notification);
}

class NoopNativeNotificationClient implements NativeNotificationClient {
  const NoopNativeNotificationClient();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> show(AppNotification notification) async {}
}

class NativeNotificationService implements NativeNotificationClient {
  NativeNotificationService._();

  static final NativeNotificationService instance =
      NativeNotificationService._();

  static const String _channelId = 'chal_ai_analysis_alerts';
  static const String _channelName = 'Analysis alerts';
  static const String _channelDescription =
      'Notifications for Chal.AI analysis results and failures.';
  static const String _notificationIcon = 'ic_chal_ai_notification';

  // Foreground service — separate low-priority channel so the persistent
  // "Analyzing…" banner doesn't appear as a high-importance notification.
  static const int _foregroundNotificationId = 888;
  static const String _fgChannelId = 'chal_ai_fg_polling';
  static const String _fgChannelName = 'Background analysis';
  static const String _fgChannelDescription =
      'Shown while Chal.AI analyzes rice grains in the background.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initializing;

  @override
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    final pending = _initializing;
    if (pending != null) return pending;

    _initializing = _initializeSafely();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initializeSafely() async {
    try {
      const androidSettings = AndroidInitializationSettings(_notificationIcon);
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(settings: initializationSettings);
      await _createAndroidChannel();
      _initialized = true;
    } catch (e) {
      debugPrint('Native notification initialization failed: $e');
    }
  }

  Future<void> _createAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }

      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (macos != null) {
        return await macos.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }

    return false;
  }

  // ── Foreground service ───────────────────────────────────────────────────
  //
  // Call startForegroundPolling() as soon as a RunPod job is submitted.
  // This posts a persistent low-priority notification that prevents Android
  // from freezing / killing the Dart isolate while the Timer.periodic loop
  // runs in the background.
  //
  // Call stopForegroundPolling() once the job reaches a terminal state
  // (completed or failed) so the persistent notification is dismissed.

  Future<void> startForegroundPolling({String batchName = 'rice grains'}) async {
    if (kIsWeb) return;
    await initialize();
    if (!_initialized) return;

    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;

      // Ensure the foreground-service channel exists (idempotent).
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _fgChannelId,
          _fgChannelName,
          description: _fgChannelDescription,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
          showBadge: false,
        ),
      );

      await android.startForegroundService(
        id: _foregroundNotificationId,
        title: 'Analyzing $batchName\u2026',
        body: 'Rice grain analysis is running in the background.',
        notificationDetails: AndroidNotificationDetails(
          _fgChannelId,
          _fgChannelName,
          channelDescription: _fgChannelDescription,
          icon: _notificationIcon,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
        ),
        foregroundServiceTypes: {
          AndroidServiceForegroundType.foregroundServiceTypeDataSync,
        },
      );

      debugPrint('[NativeNotification] Foreground service started.');
    } catch (e) {
      debugPrint('[NativeNotification] startForegroundPolling failed: $e');
    }
  }

  Future<void> stopForegroundPolling() async {
    if (kIsWeb) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.stopForegroundService();
      debugPrint('[NativeNotification] Foreground service stopped.');
    } catch (e) {
      debugPrint('[NativeNotification] stopForegroundPolling failed: $e');
    }
  }

  @override
  Future<void> show(AppNotification notification) async {
    if (kIsWeb) return;
    await initialize();
    if (!_initialized) return;

    final content = _contentFor(notification);
    final notificationId =
        notification.createdAt.microsecondsSinceEpoch.remainder(1 << 31);

    try {
      await _plugin.show(
        id: notificationId,
        title: content.title,
        body: content.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: _notificationIcon,
            importance: Importance.high,
            priority: Priority.high,
            category: _categoryFor(notification.type),
            styleInformation: BigTextStyleInformation(content.body),
            ticker: content.title,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.id,
      );
    } catch (e) {
      debugPrint('Showing native notification failed: $e');
    }
  }

  AndroidNotificationCategory _categoryFor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.analysisCompleted =>
        AndroidNotificationCategory.status,
      AppNotificationType.analysisFailed => AndroidNotificationCategory.error,
      AppNotificationType.historySaveFailed =>
        AndroidNotificationCategory.error,
    };
  }

  ({String title, String body}) _contentFor(AppNotification notification) {
    return switch (notification.type) {
      AppNotificationType.analysisCompleted => (
          title: 'Analysis completed',
          body: _completedBody(notification),
        ),
      AppNotificationType.analysisFailed => (
          title: 'Analysis failed',
          body: _withOptionalError(
            '${notification.batchName} could not be analyzed.',
            notification.errorMessage,
          ),
        ),
      AppNotificationType.historySaveFailed => (
          title: 'Could not save analysis history',
          body: _withOptionalError(
            '${notification.batchName} was analyzed, but saving the record failed.',
            notification.errorMessage,
          ),
        ),
    };
  }

  String _completedBody(AppNotification notification) {
    final score = notification.integrityScore;
    if (score == null) {
      return '${notification.batchName} analysis is ready.';
    }
    return '${notification.batchName} analysis is ready. Integrity score: ${score.toStringAsFixed(1)}%.';
  }

  String _withOptionalError(String body, String? errorMessage) {
    final error = _shortError(errorMessage);
    if (error.isEmpty) return body;
    return '$body $error';
  }

  String _shortError(String? errorMessage) {
    final normalized = errorMessage?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized == null || normalized.isEmpty) return '';
    const maxLength = 120;
    if (normalized.length <= maxLength) return normalized;
    return '${normalized.substring(0, maxLength - 1)}...';
  }
}
