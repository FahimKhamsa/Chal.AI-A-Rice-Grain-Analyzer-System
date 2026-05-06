// lib/features/analysis/data/services/real_ai_service.dart
//
// Concrete implementation of AiService that calls the FastAPI backend.
// Sends the image as multipart/form-data and parses the JSON response
// into an AnalysisResult domain object.
//
// Uses XFile (from image_picker) instead of dart:io File so this service
// works on Flutter web as well as native platforms.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../../../../core/config/api_config.dart';
import '../../domain/models/analysis_result.dart';
import 'mock_ai_service.dart'; // imports the abstract AiService

class RealAiService implements AiService {
  final http.Client _httpClient;

  RealAiService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<AnalysisResult> analyzeImage({
    required XFile imageFile,
    required String batchName,
  }) async {
    debugPrint('=== [RealAiService] Starting Analysis ===');
    debugPrint('--> Target backend URL: ${ApiConfig.analyzeEndpoint}');
    debugPrint('--> Batch Name: $batchName');

    // ── 1. Build multipart request ─────────────────────────────────────────
    final uri = Uri.parse(ApiConfig.analyzeEndpoint);
    final request = http.MultipartRequest('POST', uri);

    // Read bytes once — works on both web and native
    final imageBytes = await imageFile.readAsBytes();
    debugPrint('--> Image Size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');

    request.files.add(
      http.MultipartFile.fromBytes(
        'file', // must match the FastAPI parameter name
        imageBytes,
        filename: imageFile.name,
      ),
    );

    request.fields['batch_name'] = batchName;

    // Required when going through ngrok — skips the browser warning interstitial page
    request.headers['ngrok-skip-browser-warning'] = 'true';

    debugPrint('--> Sending HTTP POST request...');

    // ── 2. Send with timeout ───────────────────────────────────────────────
    final streamedResponse = await _httpClient
        .send(request)
        .timeout(
          ApiConfig.requestTimeout,
          onTimeout: () {
            debugPrint('*** ERROR: HTTP request timed out after ${ApiConfig.requestTimeout.inSeconds}s!');
            throw const _ApiException(
              'Request timed out. '
              'Check that the backend is running and reachable.',
            );
          },
        );

    final response = await http.Response.fromStream(streamedResponse);
    debugPrint('<-- Received response. Status code: ${response.statusCode}');

    // ── 3. Handle HTTP errors ─────────────────────────────────────────────
    if (response.statusCode != 200) {
      debugPrint('*** ERROR: Backend returned error body: ${response.body}');
      String detail = 'Unknown server error';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        detail = body['detail']?.toString() ?? detail;
      } catch (_) {}
      throw _ApiException(
        'Server returned ${response.statusCode}: $detail',
      );
    }

    debugPrint('<-- Successfully received 200 OK. Parsing JSON data...');

    // ── 4. Parse JSON → AnalysisResult ────────────────────────────────────
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    final result = _parseAnalysisResult(json: json, imagePath: imageFile.path);

    debugPrint('=== [RealAiService] Analysis Complete ===');
    debugPrint('--> Integrity Score: ${result.integrityScore}%');
    debugPrint(
        '--> Healthy: ${result.counts.healthy}, 3/4 Broken: ${result.counts.threeQuarterBroken}, Half Broken: ${result.counts.halfBroken}, Impurity: ${result.counts.impurity}, Discolored: ${result.counts.discolored}');

    return result;
  }

  // ── JSON → Domain model ──────────────────────────────────────────────────

  AnalysisResult _parseAnalysisResult({
    required Map<String, dynamic> json,
    required String imagePath,
  }) {
    final counts = json['counts'] as Map<String, dynamic>;
    final lengthDist = json['lengthDistribution'] as Map<String, dynamic>;
    final defectBreakdown = json['defectBreakdown'] as Map<String, dynamic>;

    final processingMs = (json['processingTimeMs'] as num?)?.toInt() ?? 0;

    // Decode annotated images from base64 so the UI can show them directly
    final morphB64 = json['morphology_image_b64'] as String?;
    final colorB64 = json['color_image_b64'] as String?;

    return AnalysisResult(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      batchName: json['batchName']?.toString() ?? 'Batch A',
      imagePath: imagePath,
      analyzedAt: json['analyzedAt'] != null
          ? DateTime.parse(json['analyzedAt'] as String)
          : DateTime.now(),
      counts: GrainCounts(
        healthy: (counts['healthy'] as num?)?.toInt() ?? 0,
        threeQuarterBroken:
            (counts['threeQuarterBroken'] as num?)?.toInt() ?? 0,
        halfBroken: (counts['halfBroken'] as num?)?.toInt() ?? 0,
        impurity: (counts['impurity'] as num?)?.toInt() ?? 0,
        discolored: (counts['discolored'] as num?)?.toInt() ?? 0,
      ),
      detectedVariety: json['detectedVariety']?.toString() ?? 'Unknown',
      varietyConfidence:
          (json['varietyConfidence'] as num?)?.toDouble() ?? 0.0,
      integrityScore:
          (json['integrityScore'] as num?)?.toDouble() ?? 0.0,
      lengthDistribution: GrainLengthDistribution(
        shortPct: (lengthDist['shortPct'] as num?)?.toDouble() ?? 0.0,
        mediumPct: (lengthDist['mediumPct'] as num?)?.toDouble() ?? 0.0,
        longPct: (lengthDist['longPct'] as num?)?.toDouble() ?? 0.0,
      ),
      defectBreakdown: DefectBreakdown(
        chalkyPct:
            (defectBreakdown['chalkyPct'] as num?)?.toDouble() ?? 0.0,
        redStreakedPct:
            (defectBreakdown['redStreakedPct'] as num?)?.toDouble() ?? 0.0,
        immaturePct:
            (defectBreakdown['immaturePct'] as num?)?.toDouble() ?? 0.0,
        foreignMatterPct:
            (defectBreakdown['foreignMatterPct'] as num?)?.toDouble() ?? 0.0,
      ),
      processingTime: Duration(milliseconds: processingMs),
      morphologyImageBytes:
          morphB64 != null ? base64Decode(morphB64) : null,
      colorImageBytes:
          colorB64 != null ? base64Decode(colorB64) : null,
    );
  }
}

// ── Private exception type ────────────────────────────────────────────────

class _ApiException implements Exception {
  final String message;
  const _ApiException(this.message);

  @override
  String toString() => message;
}
