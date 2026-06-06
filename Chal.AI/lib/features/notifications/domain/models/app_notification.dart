enum AppNotificationType {
  analysisCompleted,
  analysisFailed,
  historySaveFailed,
}

extension AppNotificationTypeStorage on AppNotificationType {
  String get storageValue {
    return switch (this) {
      AppNotificationType.analysisCompleted => 'analysis_completed',
      AppNotificationType.analysisFailed => 'analysis_failed',
      AppNotificationType.historySaveFailed => 'history_save_failed',
    };
  }

  static AppNotificationType fromStorageValue(String value) {
    return switch (value) {
      'analysis_completed' => AppNotificationType.analysisCompleted,
      'analysis_failed' => AppNotificationType.analysisFailed,
      'history_save_failed' => AppNotificationType.historySaveFailed,
      _ => throw FormatException('Unknown notification type: $value'),
    };
  }
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final DateTime createdAt;
  final DateTime? readAt;
  final String batchName;
  final String? analysisId;
  final double? integrityScore;
  final String? errorMessage;

  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.batchName,
    this.readAt,
    this.analysisId,
    this.integrityScore,
    this.errorMessage,
  });

  bool get isRead => readAt != null;

  AppNotification markRead({DateTime? at}) {
    if (isRead) return this;
    return copyWith(readAt: at ?? DateTime.now());
  }

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    DateTime? createdAt,
    DateTime? readAt,
    String? batchName,
    String? analysisId,
    double? integrityScore,
    String? errorMessage,
    bool clearReadAt = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      batchName: batchName ?? this.batchName,
      analysisId: analysisId ?? this.analysisId,
      integrityScore: integrityScore ?? this.integrityScore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.storageValue,
      'created_at': createdAt.toUtc().toIso8601String(),
      'read_at': readAt?.toUtc().toIso8601String(),
      'batch_name': batchName,
      'analysis_id': analysisId,
      'integrity_score': integrityScore,
      'error_message': errorMessage,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: AppNotificationTypeStorage.fromStorageValue(
        json['type'] as String,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] == null
          ? null
          : DateTime.parse(json['read_at'] as String),
      batchName: json['batch_name'] as String,
      analysisId: json['analysis_id'] as String?,
      integrityScore: (json['integrity_score'] as num?)?.toDouble(),
      errorMessage: json['error_message'] as String?,
    );
  }
}
