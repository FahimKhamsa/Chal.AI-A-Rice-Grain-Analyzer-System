// features/analysis/data/services/mock_ai_service.dart
// Mock AI service that simulates network latency and returns realistic data.
// Replace this class's implementation with real ML inference (e.g. tflite_flutter)
// without changing any callers — the interface stays the same.
import 'dart:io';
import 'dart:math';
import '../../../analysis/domain/models/analysis_result.dart';

abstract class AiService {
  Future<AnalysisResult> analyzeImage({
    required File imageFile,
    required String batchName,
  });
}

class MockAiService implements AiService {
  final _rng = Random();

  @override
  Future<AnalysisResult> analyzeImage({
    required File imageFile,
    required String batchName,
  }) async {
    // Simulate 1.5–3s processing time
    final delay = 1500 + _rng.nextInt(1500);
    await Future.delayed(Duration(milliseconds: delay));

    // Randomize results slightly for demo variety
    final healthy = 280 + _rng.nextInt(60);
    final broken = 20 + _rng.nextInt(40);
    final discolored = 10 + _rng.nextInt(30);
    final total = healthy + broken + discolored;
    final integrityScore = (healthy / total * 100);

    final varieties = ['Basmati', 'Jasmine', 'Ponni', 'Sona Masuri', 'Arborio'];
    final variety = varieties[_rng.nextInt(varieties.length)];
    final confidence = 85.0 + _rng.nextDouble() * 12.0;

    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      batchName: batchName,
      imagePath: imageFile.path,
      analyzedAt: DateTime.now(),
      counts: GrainCounts(
        healthy: healthy,
        broken: broken,
        discolored: discolored,
      ),
      detectedVariety: variety,
      varietyConfidence: confidence,
      integrityScore: integrityScore,
      lengthDistribution: GrainLengthDistribution(
        shortPct: 5.0 + _rng.nextDouble() * 10,
        mediumPct: 20.0 + _rng.nextDouble() * 15,
        longPct: 60.0 + _rng.nextDouble() * 15,
      ),
      defectBreakdown: DefectBreakdown(
        chalkyPct: 2.0 + _rng.nextDouble() * 5,
        redStreakedPct: 1.0 + _rng.nextDouble() * 4,
        immaturePct: 2.0 + _rng.nextDouble() * 5,
        foreignMatterPct: 0.5 + _rng.nextDouble() * 3,
      ),
      processingTime: Duration(milliseconds: delay),
    );
  }
}
