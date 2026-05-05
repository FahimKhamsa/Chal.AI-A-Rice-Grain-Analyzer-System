// lib/features/analysis/data/services/real_ai_service.dart
//
// Concrete implementation of AiService that calls the FastAPI backend.
// Sends the image as multipart/form-data and parses the JSON response
// into an AnalysisResult domain object.

import 'dart:io';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:http/http.dart' as http;
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
    required File imageFile,
    required String batchName,
  }) async {
    debugPrint('=== [RealAiService] Starting Analysis ===');
    debugPrint('--> Target backend URL: ${ApiConfig.analyzeEndpoint}');
    debugPrint('--> Batch Name: $batchName');
    
    final fileSize = await imageFile.length();
    debugPrint('--> Image Size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

    // ── 1. Build multipart request ─────────────────────────────────────────
    final uri = Uri.parse(ApiConfig.analyzeEndpoint);
    final request = http.MultipartRequest('POST', uri);

    // Attach the image file
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        // Let the server determine content type from file extension
      ),
    );

    // Attach the batch name as a form field
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

    final result = _parseAnalysisResult(
      json: json,
      imagePath: imageFile.path,
    );
    
    debugPrint('=== [RealAiService] Analysis Complete ===');
    debugPrint('--> Integrity Score: ${result.integrityScore}%');
    debugPrint('--> Healthy: ${result.counts.healthy}, Broken: ${result.counts.broken}, Discolored: ${result.counts.discolored}');
    
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
        broken: (counts['broken'] as num?)?.toInt() ?? 0,
        discolored: (counts['discolored'] as num?)?.toInt() ?? 0,
      ),
      detectedVariety:
          json['detectedVariety']?.toString() ?? 'Unknown',
      varietyConfidence:
          (json['varietyConfidence'] as num?)?.toDouble() ?? 0.0,
      integrityScore:
          (json['integrityScore'] as num?)?.toDouble() ?? 0.0,
      lengthDistribution: GrainLengthDistribution(
        shortPct:
            (lengthDist['shortPct'] as num?)?.toDouble() ?? 0.0,
        mediumPct:
            (lengthDist['mediumPct'] as num?)?.toDouble() ?? 0.0,
        longPct:
            (lengthDist['longPct'] as num?)?.toDouble() ?? 0.0,
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
