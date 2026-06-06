import 'dart:convert';
import 'dart:typed_data';

import 'package:chal_ai/features/analysis/data/services/runpod_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RunPodAiService polls queued jobs until completed output arrives',
      () async {
    final requests = <Uri>[];
    var statusPolls = 0;

    final client = MockClient((request) async {
      requests.add(request.url);

      if (request.method == 'POST' &&
          request.url.path.contains('/storage/v1/object/')) {
        return http.Response('', 201);
      }

      if (request.method == 'POST' && request.url.path.endsWith('/runsync')) {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['input'], isA<Map<String, dynamic>>());
        return http.Response(
          jsonEncode({
            'id': 'queued-job-1',
            'status': 'IN_QUEUE',
          }),
          200,
        );
      }

      if (request.method == 'GET' &&
          request.url.path.endsWith('/status/queued-job-1')) {
        statusPolls += 1;
        if (statusPolls == 1) {
          return http.Response(
            jsonEncode({
              'id': 'queued-job-1',
              'status': 'IN_PROGRESS',
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'id': 'queued-job-1',
            'status': 'COMPLETED',
            'output': {
              'status': 'success',
              'output': {
                'id': 'analysis-1',
                'analyzed_at': '2026-06-06T12:00:00Z',
                'processing_time_ms': 1234,
                'integrity_score': 87.5,
                'counts': {
                  'healthy': 35,
                  'three_quarter_broken': 4,
                  'half_broken': 3,
                  'impurity': 1,
                  'discolored': 2,
                },
              },
            },
          }),
          200,
        );
      }

      fail('Unexpected request: ${request.method} ${request.url}');
    });

    final service = RunPodAiService(
      client: client,
      firstPollDelay: Duration.zero,
      pollInterval: Duration.zero,
    );
    final result = await service.analyzeImage(
      imageFile: XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'rice.jpg',
        mimeType: 'image/jpeg',
      ),
      batchName: 'Batch A',
    );

    expect(result.id, 'analysis-1');
    expect(result.batchName, 'Batch A');
    expect(result.integrityScore, 87.5);
    expect(result.counts.healthy, 35);
    expect(statusPolls, 2);
    expect(
      requests.any((uri) => uri.path.endsWith('/status/queued-job-1')),
      isTrue,
    );
  });
}
