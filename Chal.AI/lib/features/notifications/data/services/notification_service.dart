import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/app_notification.dart';

const _kNotificationsKey = 'app_notifications_v1';

class NotificationService {
  static const int maxNotifications = 50;

  final SharedPreferences? _prefs;

  NotificationService({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> get _store async {
    return _prefs ?? SharedPreferences.getInstance();
  }

  Future<List<AppNotification>> loadNotifications() async {
    try {
      final prefs = await _store;
      final raw = prefs.getString(_kNotificationsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final notifications = <AppNotification>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        try {
          notifications.add(
            AppNotification.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (e) {
          debugPrint('Skipping invalid notification: $e');
        }
      }
      return _sortedAndCapped(notifications);
    } catch (e) {
      debugPrint('loadNotifications failed: $e');
      return [];
    }
  }

  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final prefs = await _store;
    final normalized = _sortedAndCapped(notifications);
    final encoded = jsonEncode(normalized.map((n) => n.toJson()).toList());
    await prefs.setString(_kNotificationsKey, encoded);
  }

  Future<void> clearNotifications() async {
    final prefs = await _store;
    await prefs.remove(_kNotificationsKey);
  }

  List<AppNotification> _sortedAndCapped(
    List<AppNotification> notifications,
  ) {
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(maxNotifications).toList(growable: false);
  }
}
