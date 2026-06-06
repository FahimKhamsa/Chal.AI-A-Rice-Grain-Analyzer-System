import 'dart:typed_data';

import '../../../analysis/domain/models/analysis_result.dart';

/// Status of an analysis job submitted to RunPod asynchronously.
enum AnalysisStatus {
  analysing,
  completed,
  failed;

  String get storageValue => switch (this) {
        AnalysisStatus.analysing => 'analysing',
        AnalysisStatus.completed => 'completed',
        AnalysisStatus.failed => 'failed',
      };

  static AnalysisStatus fromStorageValue(String? value) => switch (value) {
        'analysing' => AnalysisStatus.analysing,
        'failed' => AnalysisStatus.failed,
        _ => AnalysisStatus.completed, // default / legacy records
      };
}

class AnalysisRecord {
  final String id;
  final String userId;
  final String batchName;
  final DateTime analyzedAt;
  final int processingTimeMs;
  final double integrityScore;
  final Map<String, dynamic> counts;
  final Map<String, dynamic> morphologyReport;
  final Map<String, dynamic> colorReport;
  final String? morphologyImageUrl;
  final String? colorImageUrl;
  final DateTime createdAt;

  // ── Async job tracking ───────────────────────────────────────────────────
  final AnalysisStatus status;
  final String? runpodJobId;
  final String? errorMessage;

  const AnalysisRecord({
    required this.id,
    required this.userId,
    required this.batchName,
    required this.analyzedAt,
    required this.processingTimeMs,
    required this.integrityScore,
    required this.counts,
    required this.morphologyReport,
    required this.colorReport,
    this.morphologyImageUrl,
    this.colorImageUrl,
    required this.createdAt,
    this.status = AnalysisStatus.completed,
    this.runpodJobId,
    this.errorMessage,
  });

  String get detectedVariety => colorReport['detectedVariety'] as String? ?? '';

  int get totalGrains {
    return (counts['healthy'] as num? ?? 0).toInt() +
        (counts['threeQuarterBroken'] as num? ?? 0).toInt() +
        (counts['halfBroken'] as num? ?? 0).toInt() +
        (counts['impurity'] as num? ?? 0).toInt() +
        (counts['discolored'] as num? ?? 0).toInt();
  }

  AnalysisRecord copyWith({
    AnalysisStatus? status,
    String? runpodJobId,
    String? errorMessage,
    double? integrityScore,
    Map<String, dynamic>? counts,
    Map<String, dynamic>? morphologyReport,
    Map<String, dynamic>? colorReport,
    String? morphologyImageUrl,
    String? colorImageUrl,
    int? processingTimeMs,
  }) {
    return AnalysisRecord(
      id: id,
      userId: userId,
      batchName: batchName,
      analyzedAt: analyzedAt,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      integrityScore: integrityScore ?? this.integrityScore,
      counts: counts ?? this.counts,
      morphologyReport: morphologyReport ?? this.morphologyReport,
      colorReport: colorReport ?? this.colorReport,
      morphologyImageUrl: morphologyImageUrl ?? this.morphologyImageUrl,
      colorImageUrl: colorImageUrl ?? this.colorImageUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      runpodJobId: runpodJobId ?? this.runpodJobId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory AnalysisRecord.fromJson(Map<String, dynamic> json) {
    return AnalysisRecord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      batchName: json['batch_name'] as String? ?? '',
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'] as String)
          : DateTime.now(),
      processingTimeMs: (json['processing_time_ms'] as num? ?? 0).toInt(),
      integrityScore: (json['integrity_score'] as num? ?? 0).toDouble(),
      counts: Map<String, dynamic>.from(json['counts'] as Map? ?? {}),
      morphologyReport:
          Map<String, dynamic>.from(json['morphology_report'] as Map? ?? {}),
      colorReport:
          Map<String, dynamic>.from(json['color_report'] as Map? ?? {}),
      morphologyImageUrl: json['morphology_image_url'] as String?,
      colorImageUrl: json['color_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: AnalysisStatus.fromStorageValue(json['status'] as String?),
      runpodJobId: json['runpod_job_id'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  AnalysisResult toAnalysisResult({
    Uint8List? morphologyImageBytes,
    Uint8List? colorImageBytes,
  }) {
    final l =
        morphologyReport['lengthDistribution'] as Map<String, dynamic>? ?? {};
    final d =
        morphologyReport['defectBreakdown'] as Map<String, dynamic>? ?? {};
    return AnalysisResult(
      id: morphologyReport['analysisId'] as String? ?? id,
      batchName: batchName,
      imagePath: morphologyReport['imagePath'] as String? ?? '',
      analyzedAt: analyzedAt,
      counts: GrainCounts(
        healthy: (counts['healthy'] as num? ?? 0).toInt(),
        threeQuarterBroken:
            (counts['threeQuarterBroken'] as num? ?? 0).toInt(),
        halfBroken: (counts['halfBroken'] as num? ?? 0).toInt(),
        impurity: (counts['impurity'] as num? ?? 0).toInt(),
        discolored: (counts['discolored'] as num? ?? 0).toInt(),
      ),
      detectedVariety: colorReport['detectedVariety'] as String? ?? '',
      varietyConfidence:
          (colorReport['varietyConfidence'] as num? ?? 0).toDouble(),
      integrityScore: integrityScore,
      lengthDistribution: GrainLengthDistribution(
        shortPct: (l['shortPct'] as num? ?? 0).toDouble(),
        mediumPct: (l['mediumPct'] as num? ?? 0).toDouble(),
        longPct: (l['longPct'] as num? ?? 0).toDouble(),
      ),
      defectBreakdown: DefectBreakdown(
        chalkyPct: (d['chalkyPct'] as num? ?? 0).toDouble(),
        redStreakedPct: (d['redStreakedPct'] as num? ?? 0).toDouble(),
        immaturePct: (d['immaturePct'] as num? ?? 0).toDouble(),
        foreignMatterPct: (d['foreignMatterPct'] as num? ?? 0).toDouble(),
      ),
      processingTime: Duration(milliseconds: processingTimeMs),
      morphologyImageBytes: morphologyImageBytes,
      colorImageBytes: colorImageBytes,
    );
  }

  static Map<String, dynamic> toDatabaseMap(
    AnalysisResult r,
    String userId, {
    String? morphologyImagePath,
    String? colorImagePath,
    AnalysisStatus status = AnalysisStatus.completed,
    String? runpodJobId,
    String? errorMessage,
  }) {
    return {
      'user_id': userId,
      'batch_name': r.batchName,
      'analyzed_at': r.analyzedAt.toIso8601String(),
      'processing_time_ms': r.processingTime.inMilliseconds,
      'integrity_score': r.integrityScore,
      'counts': {
        'healthy': r.counts.healthy,
        'threeQuarterBroken': r.counts.threeQuarterBroken,
        'halfBroken': r.counts.halfBroken,
        'impurity': r.counts.impurity,
        'discolored': r.counts.discolored,
      },
      'morphology_report': {
        'analysisId': r.id,
        'imagePath': r.imagePath,
        'lengthDistribution': {
          'shortPct': r.lengthDistribution.shortPct,
          'mediumPct': r.lengthDistribution.mediumPct,
          'longPct': r.lengthDistribution.longPct,
        },
        'defectBreakdown': {
          'chalkyPct': r.defectBreakdown.chalkyPct,
          'redStreakedPct': r.defectBreakdown.redStreakedPct,
          'immaturePct': r.defectBreakdown.immaturePct,
          'foreignMatterPct': r.defectBreakdown.foreignMatterPct,
        },
      },
      'color_report': {
        'detectedVariety': r.detectedVariety,
        'varietyConfidence': r.varietyConfidence,
      },
      'status': status.storageValue,
      if (runpodJobId != null) 'runpod_job_id': runpodJobId,
      if (errorMessage != null) 'error_message': errorMessage,
      if (morphologyImagePath != null)
        'morphology_image_url': morphologyImagePath,
      if (colorImagePath != null) 'color_image_url': colorImagePath,
    };
  }

  /// Minimal placeholder map for a newly submitted async job
  /// (before results are available).
  static Map<String, dynamic> toPlaceholderMap({
    required String id,
    required String userId,
    required String batchName,
    required String runpodJobId,
  }) {
    final now = DateTime.now().toIso8601String();
    return {
      'id': id,
      'user_id': userId,
      'batch_name': batchName,
      'analyzed_at': now,
      'processing_time_ms': 0,
      'integrity_score': 0.0,
      'counts': {
        'healthy': 0,
        'threeQuarterBroken': 0,
        'halfBroken': 0,
        'impurity': 0,
        'discolored': 0,
      },
      'morphology_report': {},
      'color_report': {},
      'status': AnalysisStatus.analysing.storageValue,
      'runpod_job_id': runpodJobId,
    };
  }
}
