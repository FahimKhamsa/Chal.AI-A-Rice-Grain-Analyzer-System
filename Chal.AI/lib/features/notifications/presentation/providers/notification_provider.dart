import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analysis/domain/models/analysis_result.dart';
import '../../data/services/notification_service.dart';
import '../../domain/models/app_notification.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get isEmpty => notifications.isEmpty;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationServiceProvider));
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service)
      : super(const NotificationState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    try {
      final notifications = await _service.loadNotifications();
      if (!mounted) return;
      state = NotificationState(notifications: notifications);
    } catch (e) {
      debugPrint('Notification load failed: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> addAnalysisCompleted(AnalysisResult result) {
    return addNotification(
      AppNotification(
        id: _newId(AppNotificationType.analysisCompleted),
        type: AppNotificationType.analysisCompleted,
        createdAt: DateTime.now(),
        batchName: result.batchName,
        analysisId: result.id,
        integrityScore: result.integrityScore,
      ),
    );
  }

  Future<void> addAnalysisFailed({
    required String batchName,
    required String errorMessage,
  }) {
    return addNotification(
      AppNotification(
        id: _newId(AppNotificationType.analysisFailed),
        type: AppNotificationType.analysisFailed,
        createdAt: DateTime.now(),
        batchName: batchName,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> addHistorySaveFailed({
    required AnalysisResult result,
    required String errorMessage,
  }) {
    return addNotification(
      AppNotification(
        id: _newId(AppNotificationType.historySaveFailed),
        type: AppNotificationType.historySaveFailed,
        createdAt: DateTime.now(),
        batchName: result.batchName,
        analysisId: result.id,
        integrityScore: result.integrityScore,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> addNotification(AppNotification notification) async {
    final current = state.isLoading
        ? await _service.loadNotifications()
        : state.notifications;
    final next = [
      notification,
      ...current.where((n) => n.id != notification.id),
    ];
    await _persist(next);
  }

  Future<void> markRead(String id) async {
    final next = state.notifications
        .map((n) => n.id == id ? n.markRead() : n)
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    final next = state.notifications
        .map((n) => n.isRead ? n : n.copyWith(readAt: now))
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> delete(String id) async {
    final next =
        state.notifications.where((n) => n.id != id).toList(growable: false);
    await _persist(next);
  }

  Future<void> clearAll() async {
    await _service.clearNotifications();
    if (!mounted) return;
    state = const NotificationState();
  }

  Future<void> _persist(List<AppNotification> notifications) async {
    try {
      await _service.saveNotifications(notifications);
      final normalized = await _service.loadNotifications();
      if (!mounted) return;
      state = NotificationState(notifications: normalized);
    } catch (e) {
      debugPrint('Notification persist failed: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  String _newId(AppNotificationType type) {
    return '${type.storageValue}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
