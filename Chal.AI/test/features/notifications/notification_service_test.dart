import 'package:chal_ai/features/notifications/data/services/native_notification_service.dart';
import 'package:chal_ai/features/notifications/data/services/notification_service.dart';
import 'package:chal_ai/features/notifications/domain/models/app_notification.dart';
import 'package:chal_ai/features/notifications/presentation/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeNativeNotificationClient implements NativeNotificationClient {
  final shownNotifications = <AppNotification>[];
  bool permissionRequested = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<void> show(AppNotification notification) async {
    shownNotifications.add(notification);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('AppNotification serializes and deserializes optional fields', () {
    final createdAt = DateTime.utc(2026, 6, 4, 10, 30);
    final readAt = DateTime.utc(2026, 6, 4, 10, 45);
    final notification = AppNotification(
      id: 'n1',
      type: AppNotificationType.analysisCompleted,
      createdAt: createdAt,
      readAt: readAt,
      batchName: 'Batch A',
      analysisId: 'analysis-1',
      integrityScore: 84.7,
      errorMessage: 'non-fatal',
    );

    final decoded = AppNotification.fromJson(notification.toJson());

    expect(decoded.id, 'n1');
    expect(decoded.type, AppNotificationType.analysisCompleted);
    expect(decoded.createdAt, createdAt);
    expect(decoded.readAt, readAt);
    expect(decoded.batchName, 'Batch A');
    expect(decoded.analysisId, 'analysis-1');
    expect(decoded.integrityScore, 84.7);
    expect(decoded.errorMessage, 'non-fatal');
  });

  test('NotificationNotifier updates unread count after read actions',
      () async {
    final service = NotificationService();
    final notifier = NotificationNotifier(service);
    await Future<void>.delayed(Duration.zero);

    await notifier.addAnalysisFailed(
      batchName: 'Batch A',
      errorMessage: 'network error',
    );
    await notifier.addAnalysisFailed(
      batchName: 'Batch B',
      errorMessage: 'timeout',
    );

    expect(notifier.state.notifications.length, 2);
    expect(notifier.state.unreadCount, 2);

    await notifier.markRead(notifier.state.notifications.first.id);
    expect(notifier.state.unreadCount, 1);

    await notifier.markAllRead();
    expect(notifier.state.unreadCount, 0);
  });

  test('NotificationNotifier dispatches phone notification when added',
      () async {
    final nativeNotifications = FakeNativeNotificationClient();
    final service = NotificationService(
      nativeNotifications: nativeNotifications,
    );
    final notifier = NotificationNotifier(service);
    await Future<void>.delayed(Duration.zero);

    await notifier.addAnalysisFailed(
      batchName: 'Batch A',
      errorMessage: 'network error',
    );

    expect(nativeNotifications.shownNotifications, hasLength(1));
    expect(
      nativeNotifications.shownNotifications.single.type,
      AppNotificationType.analysisFailed,
    );
    expect(nativeNotifications.shownNotifications.single.batchName, 'Batch A');
  });

  test('NotificationService keeps newest notifications within cap', () async {
    final service = NotificationService();
    final base = DateTime.utc(2026, 6, 4);
    final notifications = List.generate(55, (index) {
      return AppNotification(
        id: 'n$index',
        type: AppNotificationType.analysisFailed,
        createdAt: base.add(Duration(minutes: index)),
        batchName: 'Batch $index',
        errorMessage: 'error $index',
      );
    });

    await service.saveNotifications(notifications);
    final loaded = await service.loadNotifications();

    expect(loaded.length, NotificationService.maxNotifications);
    expect(loaded.first.id, 'n54');
    expect(loaded.last.id, 'n5');
  });
}
