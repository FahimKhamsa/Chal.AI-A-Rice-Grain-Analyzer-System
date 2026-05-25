// lib/features/analysis/data/services/runpod_ai_service.dart
//
// Production AI service backed by RunPod Serverless (Grounding DINO + SAM).
//
// Full call flow for every analyzeImage() call:
//   1. Read XFile bytes → upload to Supabase Storage (rice-uploads bucket)
//   2. POST {image_url, confidence_threshold} to RunPod /runsync → wait for result
//   3. Download annotated images (morphology + color) from Supabase result URLs
//   4. Map snake_case RunPod output → AnalysisResult domain model
//
// RunPod /runsync response envelope from run_serverless.py:
//   { "status": "COMPLETED",
//     "output": { "status": "success",
//                 "output": { <inference.py dict> } } }
//
// Supabase upload bucket must have Public access enabled so RunPod can
// fetch the input image URL without auth headers.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/api_config.dart';
import '../../domain/models/analysis_result.dart';
import 'mock_ai_service.dart'; // exports the AiService interface

class RunPodAiService implements AiService {
  final http.Client _client;

  RunPodAiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<AnalysisResult> analyzeImage({
    required XFile imageFile,
    required String batchName,
  }) async {
    debugPrint('=== [RunPodAiService] Starting Analysis ===');
    debugPrint('--> File: ${imageFile.name}  Batch: $batchName');

    // 1. Upload to Supabase so RunPod can fetch it by URL
    final imageBytes = await imageFile.readAsBytes();
    final imageUrl = await _uploadToSupabase(imageBytes, imageFile.name);
    debugPrint('--> Supabase upload URL: $imageUrl');

    // 2. Submit to RunPod and wait synchronously for the result
    final output = await _submitJob(imageUrl);

    // 3. Download annotated images from the Supabase result URLs
    final morphUrl = output['morphology_image_url'] as String?;
    final colorUrl = output['color_image_url'] as String?;
    final morphBytes = morphUrl != null ? await _downloadBytes(morphUrl) : null;
    final colorBytes = colorUrl != null ? await _downloadBytes(colorUrl) : null;

    debugPrint('=== [RunPodAiService] Complete ===');
    debugPrint('--> Integrity Score: ${output['integrity_score']}%');

    // 5. Parse → domain model
    return _parseResult(
      output: output,
      imagePath: imageFile.path,
      batchName: batchName,
      morphBytes: morphBytes,
      colorBytes: colorBytes,
    );
  }

  // ── Supabase Storage upload ────────────────────────────────────────────────

  Future<String> _uploadToSupabase(Uint8List bytes, String filename) async {
    final ext = filename.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    final objectPath =
        'uploads/${DateTime.now().millisecondsSinceEpoch}_$filename';

    final uri = Uri.parse(
      '${ApiConfig.supabaseUrl}/storage/v1/object'
      '/${ApiConfig.supabaseUploadBucket}/$objectPath',
    );

    final response = await _client
        .post(
          uri,
          headers: {
            'apikey': ApiConfig.supabaseAnonKey,
            'Authorization': 'Bearer ${ApiConfig.supabaseAnonKey}',
            'Content-Type': contentType,
            'x-upsert': 'true',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Supabase upload failed (${response.statusCode}): ${response.body}',
      );
    }

    // Public URL — works because the bucket has public access enabled
    return '${ApiConfig.supabaseUrl}/storage/v1/object/public'
        '/${ApiConfig.supabaseUploadBucket}/$objectPath';
  }

  // ── RunPod job submission (synchronous) ──────────────────────────────────

  Future<Map<String, dynamic>> _submitJob(String imageUrl) async {
    final uri = Uri.parse(
      'https://api.runpod.ai/v2/${ApiConfig.runpodEndpointId}/runsync',
    );

    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.runpodApiKey}',
          },
          body: jsonEncode({
            'input': {
              'image_url': imageUrl,
              'confidence_threshold': 0.06,
            },
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'RunPod request failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String? ?? 'UNKNOWN';
    debugPrint('--> RunPod status: $status');

    if (status == 'FAILED') {
      throw Exception('RunPod job failed: ${body['error'] ?? 'unknown error'}');
    }
    if (status == 'TIMED_OUT') {
      throw Exception(
        'RunPod timed out — worker may be cold-starting. Please try again.',
      );
    }

    final wrapper = body['output'] as Map<String, dynamic>?;
    if (wrapper == null) {
      throw Exception('RunPod returned no output (status: $status).');
    }
    if (wrapper['status'] == 'error') {
      throw Exception('Worker error: ${wrapper['message']}');
    }
    return wrapper['output'] as Map<String, dynamic>;
  }

  // ── Annotated image download ───────────────────────────────────────────────

  Future<Uint8List?> _downloadBytes(String url) async {
    try {
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) return response.bodyBytes;
      debugPrint(
        '*** Annotated image download failed (${response.statusCode}): $url',
      );
    } catch (e) {
      debugPrint('*** Annotated image download error: $e');
    }
    return null;
  }

  // ── RunPod output dict → AnalysisResult ───────────────────────────────────
  //
  // RunPod returns snake_case keys from inference.py:
  //   three_quarter_broken, half_broken, processing_time_ms, integrity_score …
  // FastAPI (RealAiService) returns camelCase — they are handled separately.

  AnalysisResult _parseResult({
    required Map<String, dynamic> output,
    required String imagePath,
    required String batchName,
    required Uint8List? morphBytes,
    required Uint8List? colorBytes,
  }) {
    final counts = output['counts'] as Map<String, dynamic>? ?? {};
    final processingMs = (output['processing_time_ms'] as num?)?.toInt() ?? 0;

    return AnalysisResult(
      id: output['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      batchName: batchName,
      imagePath: imagePath,
      analyzedAt: output['analyzed_at'] != null
          ? DateTime.parse(output['analyzed_at'] as String)
          : DateTime.now(),
      counts: GrainCounts(
        healthy: (counts['healthy'] as num?)?.toInt() ?? 0,
        threeQuarterBroken:
            (counts['three_quarter_broken'] as num?)?.toInt() ?? 0,
        halfBroken: (counts['half_broken'] as num?)?.toInt() ?? 0,
        impurity: (counts['impurity'] as num?)?.toInt() ?? 0,
        discolored: (counts['discolored'] as num?)?.toInt() ?? 0,
      ),
      detectedVariety: 'Unknown',
      varietyConfidence: 0.0,
      integrityScore: (output['integrity_score'] as num?)?.toDouble() ?? 0.0,
      lengthDistribution: const GrainLengthDistribution(
        shortPct: 0.0,
        mediumPct: 0.0,
        longPct: 100.0,
      ),
      defectBreakdown: const DefectBreakdown(
        chalkyPct: 0.0,
        redStreakedPct: 0.0,
        immaturePct: 0.0,
        foreignMatterPct: 0.0,
      ),
      processingTime: Duration(milliseconds: processingMs),
      morphologyImageBytes: morphBytes,
      colorImageBytes: colorBytes,
    );
  }
}
