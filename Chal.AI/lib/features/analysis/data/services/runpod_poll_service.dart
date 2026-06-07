// lib/features/analysis/data/services/runpod_poll_service.dart
//
// Background polling service for RunPod async jobs.
//
// After the user submits an analysis job via /run, this service is responsible
// for periodically querying /status/{jobId} until the job reaches a terminal
// state (COMPLETED or FAILED). It then:
//   1. Downloads annotated images from Supabase
//   2. Updates the placeholder record in Supabase (status → completed/failed)
//   3. Fires a native push notification
//   4. Invalidates the historyProvider so the UI refreshes automatically

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/data/services/history_service.dart';
import '../../../history/domain/models/analysis_record.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../notifications/data/services/native_notification_service.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import 'runpod_ai_service.dart';

/// Represents a single pending job being tracked.
class _PendingJob {
  final String recordId;
  final String batchName;
  final String imagePath;
  final String userId;
  Timer? _timer;

  _PendingJob({
    required this.recordId,
    required this.batchName,
    required this.imagePath,
    required this.userId,
  });

  void cancel() => _timer?.cancel();
}

class RunPodPollService {
  final RunPodAiService _runpodService;
  final HistoryService _historyService;
  final Ref _ref;

  static const Duration _pollInterval = Duration(seconds: 8);
  static const Duration _maxPollDuration = Duration(minutes: 15);

  final Map<String, _PendingJob> _jobs = {};

  RunPodPollService({
    required RunPodAiService runpodService,
    required HistoryService historyService,
    required Ref ref,
  })  : _runpodService = runpodService,
        _historyService = historyService,
        _ref = ref;

  /// Start polling for [jobId]. The [recordId] is the Supabase row to update.
  void track({
    required String jobId,
    required String recordId,
    required String batchName,
    required String imagePath,
    required String userId,
  }) {
    if (_jobs.containsKey(jobId)) return; // already tracking

    debugPrint('[PollService] Tracking job: $jobId (record: $recordId)');

    final job = _PendingJob(
      recordId: recordId,
      batchName: batchName,
      imagePath: imagePath,
      userId: userId,
    );
    _jobs[jobId] = job;

    // Start the Android foreground service so the Dart isolate is kept alive
    // even when the user backgrounds or exits the app.
    NativeNotificationService.instance
        .startForegroundPolling(batchName: batchName);

    final startedAt = DateTime.now();

    // Kick off a repeating timer
    job._timer = Timer.periodic(_pollInterval, (timer) async {
      // Safety timeout
      if (DateTime.now().difference(startedAt) > _maxPollDuration) {
        debugPrint('[PollService] Max poll duration exceeded for job $jobId');
        timer.cancel();
        _jobs.remove(jobId);
        await _markFailed(
          job,
          'Analysis timed out after ${_maxPollDuration.inMinutes} minutes.',
        );
        return;
      }

      await _tick(jobId, job, timer);
    });
  }

  Future<void> _tick(
    String jobId,
    _PendingJob job,
    Timer timer,
  ) async {
    try {
      final result = await _runpodService.pollJobOnce(jobId);

      switch (result.state) {
        case RunPodJobState.pending:
          debugPrint('[PollService] Job $jobId still pending…');
          return;

        case RunPodJobState.completed:
          timer.cancel();
          _jobs.remove(jobId);
          debugPrint('[PollService] Job $jobId COMPLETED');
          await _handleCompleted(job, result.output!);

        case RunPodJobState.failed:
          timer.cancel();
          _jobs.remove(jobId);
          debugPrint('[PollService] Job $jobId FAILED: ${result.errorMessage}');
          await _markFailed(job, result.errorMessage ?? 'Unknown error');
      }
    } catch (e) {
      debugPrint('[PollService] Poll error for job $jobId: $e');
      // Non-fatal — will retry on the next tick
    }
  }

  Future<void> _handleCompleted(
    _PendingJob job,
    Map<String, dynamic> output,
  ) async {
    try {
      // Download annotated images
      final morphUrl = output['morphology_image_url'] as String?;
      final colorUrl = output['color_image_url'] as String?;
      final morphBytes =
          morphUrl != null ? await _runpodService.downloadResultImage(morphUrl) : null;
      final colorBytes =
          colorUrl != null ? await _runpodService.downloadResultImage(colorUrl) : null;

      // Build the full AnalysisResult
      final analysisResult = _runpodService.buildAnalysisResult(
        output: output,
        imagePath: job.imagePath,
        batchName: job.batchName,
        morphBytes: morphBytes,
        colorBytes: colorBytes,
      );

      // Upload annotated images to Supabase storage
      String? morphPath;
      String? colorPath;
      if (morphBytes != null) {
        morphPath = await _historyService.uploadImage(
          userId: job.userId,
          analysisId: job.recordId,
          bytes: morphBytes,
          filename: 'morphology.jpg',
        );
      }
      if (colorBytes != null) {
        colorPath = await _historyService.uploadImage(
          userId: job.userId,
          analysisId: job.recordId,
          bytes: colorBytes,
          filename: 'color.jpg',
        );
      }

      // Update the Supabase placeholder record with real data
      final countsMap = {
        'healthy': analysisResult.counts.healthy,
        'threeQuarterBroken': analysisResult.counts.threeQuarterBroken,
        'halfBroken': analysisResult.counts.halfBroken,
        'impurity': analysisResult.counts.impurity,
        'discolored': analysisResult.counts.discolored,
      };

      final morphReport = {
        'analysisId': analysisResult.id,
        'imagePath': analysisResult.imagePath,
        'lengthDistribution': {
          'shortPct': analysisResult.lengthDistribution.shortPct,
          'mediumPct': analysisResult.lengthDistribution.mediumPct,
          'longPct': analysisResult.lengthDistribution.longPct,
        },
        'defectBreakdown': {
          'chalkyPct': analysisResult.defectBreakdown.chalkyPct,
          'redStreakedPct': analysisResult.defectBreakdown.redStreakedPct,
          'immaturePct': analysisResult.defectBreakdown.immaturePct,
          'foreignMatterPct': analysisResult.defectBreakdown.foreignMatterPct,
        },
      };

      final colorReport = {
        'detectedVariety': analysisResult.detectedVariety,
        'varietyConfidence': analysisResult.varietyConfidence,
      };

      final updateData = <String, dynamic>{
        'status': AnalysisStatus.completed.storageValue,
        'integrity_score': analysisResult.integrityScore,
        'processing_time_ms': analysisResult.processingTime.inMilliseconds,
        'counts': countsMap,
        'morphology_report': morphReport,
        'color_report': colorReport,
        'analyzed_at': analysisResult.analyzedAt.toIso8601String(),
        if (morphPath != null) 'morphology_image_url': morphPath,
        if (colorPath != null) 'color_image_url': colorPath,
      };

      // Retry Supabase update up to 3 times with a 5 s delay between attempts.
      // This handles transient DNS / network failures that can occur when Android
      // briefly suspends and resumes the process around app backgrounding.
      await _withRetry(() => _historyService.updateRecord(job.recordId, updateData));

      // Stop the foreground service — analysis is done.
      await NativeNotificationService.instance.stopForegroundPolling();

      // Fire push notification
      await _ref
          .read(notificationProvider.notifier)
          .addAnalysisCompleted(analysisResult);

      // Invalidate history so the UI refreshes
      _ref.invalidate(historyProvider);

      debugPrint(
        '[PollService] Record ${job.recordId} updated — integrity: '
        '${analysisResult.integrityScore}%',
      );
    } catch (e) {
      debugPrint('[PollService] _handleCompleted error: $e');
      await _markFailed(job, e.toString());
    }
  }

  Future<void> _markFailed(_PendingJob job, String errorMessage) async {
    // Stop foreground service whether we succeeded or failed.
    await NativeNotificationService.instance.stopForegroundPolling();
    try {
      await _withRetry(
        () => _historyService.updateRecord(job.recordId, {
          'status': AnalysisStatus.failed.storageValue,
          'error_message': errorMessage,
        }),
      );

      await _ref
          .read(notificationProvider.notifier)
          .addAnalysisFailed(batchName: job.batchName, errorMessage: errorMessage);

      _ref.invalidate(historyProvider);
    } catch (e) {
      debugPrint('[PollService] _markFailed error: $e');
    }
  }

  /// Retries [fn] up to 3 times with a 5-second gap on failure.
  /// Handles transient network / DNS errors that occur when Android
  /// resumes the app process after a short suspension.
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  Future<void> _withRetry(Future<void> Function() fn) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await fn();
        return;
      } catch (e) {
        if (attempt == _maxRetries) rethrow;
        debugPrint(
          '[PollService] Retry $attempt/$_maxRetries after error: $e',
        );
        await Future<void>.delayed(_retryDelay);
      }
    }
  }

  /// Returns true if [jobId] is currently being tracked.
  bool isTracking(String jobId) => _jobs.containsKey(jobId);

  /// Cancel all active timers (call on app dispose if needed).
  void dispose() {
    for (final job in _jobs.values) {
      job.cancel();
    }
    _jobs.clear();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final runPodPollServiceProvider = Provider<RunPodPollService>((ref) {
  final runpodService = RunPodAiService();
  final historyService = ref.watch(historyServiceProvider);
  final service = RunPodPollService(
    runpodService: runpodService,
    historyService: historyService,
    ref: ref,
  );
  ref.onDispose(service.dispose);
  return service;
});
