// features/capture/presentation/providers/capture_provider.dart
// Riverpod StateNotifier that manages all camera/capture state.
// Keeps UI code clean — screens just watch this notifier.
//
// Uses XFile (image_picker) + Uint8List bytes throughout so the code works
// on Flutter web and native without any dart:io File.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../analysis/data/services/mock_ai_service.dart';
import '../../../analysis/data/services/real_ai_service.dart';
import '../../../analysis/data/services/runpod_ai_service.dart';
import '../../../analysis/data/services/runpod_poll_service.dart';
import '../../../analysis/domain/models/analysis_result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

/// --dart-define=USE_MOCK=true    → MockAiService  (no backend, instant demo)
/// --dart-define=USE_RUNPOD=false → RealAiService (local FastAPI dev server)
/// default                         → RunPodAiService async (production)
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
const bool _useRunPod = bool.fromEnvironment('USE_RUNPOD', defaultValue: true);

enum CaptureStatus {
  idle,
  imageSelected,
  analyzing,
  asyncSubmitted, // async job accepted — show popup & go to history
  done,           // (mock/real sync path only)
  error,
}

class CaptureState {
  final String batchName;

  /// Raw bytes for rendering — works on web and native via Image.memory.
  final Uint8List? imageBytes;

  /// Original XFile handle passed to the AI service.
  final XFile? selectedXFile;

  final CaptureStatus status;
  final AnalysisResult? result;
  final String? errorMessage;
  final String? historySaveError;
  final bool isFlashOn;

  const CaptureState({
    this.batchName = 'Batch A',
    this.imageBytes,
    this.selectedXFile,
    this.status = CaptureStatus.idle,
    this.result,
    this.errorMessage,
    this.historySaveError,
    this.isFlashOn = false,
  });

  bool get hasImage => imageBytes != null;

  CaptureState copyWith({
    String? batchName,
    Uint8List? imageBytes,
    XFile? selectedXFile,
    CaptureStatus? status,
    AnalysisResult? result,
    String? errorMessage,
    String? historySaveError,
    bool clearHistorySaveError = false,
    bool? isFlashOn,
  }) {
    return CaptureState(
      batchName: batchName ?? this.batchName,
      imageBytes: imageBytes ?? this.imageBytes,
      selectedXFile: selectedXFile ?? this.selectedXFile,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      historySaveError: clearHistorySaveError
          ? null
          : (historySaveError ?? this.historySaveError),
      isFlashOn: isFlashOn ?? this.isFlashOn,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final AiService _aiService;
  final RunPodAiService? _runpodService;
  final RunPodPollService? _pollService;
  final ImagePicker _picker;
  final String? _userId;
  final NotificationNotifier _notifications;
  final HistoryNotifier _historyNotifier;

  CaptureNotifier(
    this._aiService,
    this._runpodService,
    this._pollService,
    this._picker,
    this._userId,
    this._notifications,
    this._historyNotifier,
  ) : super(const CaptureState());

  void setBatchName(String name) {
    state = state.copyWith(batchName: name.isEmpty ? 'Batch A' : name);
  }

  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
  }

  Future<void> pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null) return;
    await _loadImage(xfile);
  }

  Future<void> captureFromCamera() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (xfile == null) return;
    await _loadImage(xfile);
  }

  Future<void> _loadImage(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    state = state.copyWith(
      imageBytes: bytes,
      selectedXFile: xfile,
      status: CaptureStatus.imageSelected,
      clearHistorySaveError: true,
    );
  }

  /// Submit an analysis. Uses async path (RunPod /run) in production,
  /// or falls back to sync path for mock / real FastAPI services.
  Future<AnalysisResult?> startAnalysis() async {
    final xfile = state.selectedXFile;
    if (xfile == null) return null;
    state = state.copyWith(status: CaptureStatus.analyzing);

    // Use the async RunPod path when the service is RunPodAiService
    if (_runpodService != null && _pollService != null && _userId != null) {
      return _runAnalysisAsync(xfile);
    }

    // Sync path (mock or local FastAPI)
    return _runAnalysisSync(xfile);
  }

  // ── Async RunPod path (/run endpoint) ────────────────────────────────────

  Future<AnalysisResult?> _runAnalysisAsync(XFile xfile) async {
    final batchName = state.batchName;
    final userId = _userId!;
    final recordId = const Uuid().v4();

    try {
      final imageBytes = await xfile.readAsBytes();

      // 1. Submit to RunPod /run → get jobId immediately
      final (:jobId, :imageUrl) = await _runpodService!.submitJobAsync(
        imageBytes: imageBytes,
        filename: xfile.name,
      );
      debugPrint('[CaptureNotifier] Async job submitted: $jobId');

      // 2. Insert placeholder record in Supabase (status = analysing)
      await _historyNotifier.savePlaceholder(
        recordId: recordId,
        batchName: batchName,
        runpodJobId: jobId,
      );

      // 3. Register job with the background poller
      _pollService!.track(
        jobId: jobId,
        recordId: recordId,
        batchName: batchName,
        imagePath: imageUrl,
        userId: userId,
      );

      // 4. Signal the UI to show the "analysis started" popup
      state = state.copyWith(status: CaptureStatus.asyncSubmitted);
      return null; // no result yet — comes via push notification later
    } catch (e) {
      final message = e.toString();
      debugPrint('[CaptureNotifier] Async submission failed: $message');
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: message,
      );
      await _notifications.addAnalysisFailed(
        batchName: batchName,
        errorMessage: message,
      );
      return null;
    }
  }

  // ── Sync path (mock / local FastAPI) ─────────────────────────────────────

  Future<AnalysisResult?> _runAnalysisSync(XFile xfile) async {
    try {
      final result = await _aiService.analyzeImage(
        imageFile: xfile,
        batchName: state.batchName,
      );
      state = state.copyWith(status: CaptureStatus.done, result: result);
      await _notifications.addAnalysisCompleted(result);
      return result;
    } catch (e) {
      final message = e.toString();
      final failedBatchName = state.batchName;
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: message,
      );
      await _notifications.addAnalysisFailed(
        batchName: failedBatchName,
        errorMessage: message,
      );
      return null;
    }
  }

  void reset() {
    state = const CaptureState();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final aiServiceProvider = Provider<AiService>((ref) {
  if (_useMock) return MockAiService();
  if (!_useRunPod) return RealAiService();
  return RunPodAiService();
});

/// Provides a RunPodAiService instance only when USE_RUNPOD is true.
final runpodAiServiceProvider = Provider<RunPodAiService?>((ref) {
  if (_useMock || !_useRunPod) return null;
  return ref.watch(aiServiceProvider) as RunPodAiService;
});

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(
    ref.watch(aiServiceProvider),
    ref.watch(runpodAiServiceProvider),
    _useMock || !_useRunPod ? null : ref.watch(runPodPollServiceProvider),
    ref.watch(imagePickerProvider),
    ref.watch(currentUserProvider)?.id,
    ref.read(notificationProvider.notifier),
    ref.read(historyProvider.notifier),
  );
});
