// features/analysis/domain/models/analysis_result.dart
// Core domain model for an AI analysis result.
// Passed between screens via go_router's `extra` parameter.
// All fields have sensible defaults for mock/demo purposes.

class GrainCounts {
  final int healthy;
  final int broken;
  final int discolored;

  const GrainCounts({
    required this.healthy,
    required this.broken,
    required this.discolored,
  });

  int get total => healthy + broken + discolored;
  double get healthyPct => total == 0 ? 0 : healthy / total * 100;
  double get brokenPct => total == 0 ? 0 : broken / total * 100;
  double get discoloredPct => total == 0 ? 0 : discolored / total * 100;
}

class GrainLengthDistribution {
  final double shortPct; // < 5mm
  final double mediumPct; // 5–6.5mm
  final double longPct; // > 6.5mm

  const GrainLengthDistribution({
    required this.shortPct,
    required this.mediumPct,
    required this.longPct,
  });
}

class DefectBreakdown {
  final double chalkyPct;
  final double redStreakedPct;
  final double immaturePct;
  final double foreignMatterPct;

  const DefectBreakdown({
    required this.chalkyPct,
    required this.redStreakedPct,
    required this.immaturePct,
    required this.foreignMatterPct,
  });
}

class AnalysisResult {
  final String id;
  final String batchName;
  final String imagePath; // local file path or asset path
  final DateTime analyzedAt;

  // Core counts
  final GrainCounts counts;

  // Variety detection
  final String detectedVariety;
  final double varietyConfidence; // 0–100

  // Integrity score — main "hero" metric
  final double integrityScore; // 0–100 (= healthyPct essentially)

  // Charts data
  final GrainLengthDistribution lengthDistribution;
  final DefectBreakdown defectBreakdown;

  // Processing time for UI display
  final Duration processingTime;

  const AnalysisResult({
    required this.id,
    required this.batchName,
    required this.imagePath,
    required this.analyzedAt,
    required this.counts,
    required this.detectedVariety,
    required this.varietyConfidence,
    required this.integrityScore,
    required this.lengthDistribution,
    required this.defectBreakdown,
    required this.processingTime,
  });

  // ── Mock factory for instant UI testing ──────────────────────────────────
  factory AnalysisResult.mock({
    String batchName = 'Batch A',
    String imagePath = '',
  }) {
    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batchName: batchName,
      imagePath: imagePath,
      analyzedAt: DateTime.now(),
      counts: const GrainCounts(healthy: 312, broken: 38, discolored: 22),
      detectedVariety: 'Basmati',
      varietyConfidence: 92.4,
      integrityScore: 84.7,
      lengthDistribution: const GrainLengthDistribution(
        shortPct: 8.0,
        mediumPct: 24.0,
        longPct: 68.0,
      ),
      defectBreakdown: const DefectBreakdown(
        chalkyPct: 5.2,
        redStreakedPct: 2.8,
        immaturePct: 4.1,
        foreignMatterPct: 3.1,
      ),
      processingTime: const Duration(seconds: 2, milliseconds: 340),
    );
  }
}
