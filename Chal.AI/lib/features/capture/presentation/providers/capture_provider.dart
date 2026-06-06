// features/capture/presentation/providers/capture_provider.dart
// Riverpod StateNotifier that manages all camera/capture state.
// Keeps UI code clean — screens just watch this notifier.
//
// Uses XFile (image_picker) + Uint8List bytes throughout so the code works
// on Flutter web and native without any dart:io File.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../analysis/data/services/mock_ai_service.dart';
import '../../../analysis/data/services/real_ai_service.dart';
import '../../../analysis/data/services/runpod_ai_service.dart';
import '../../../analysis/domain/models/analysis_result.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/data/services/history_service.dart';
import '../../../history/domain/models/analysis_record.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';

/// --dart-define=USE_MOCK=true   → MockAiService  (no backend, instant demo)
/// --dart-define=USE_RUNPOD=false → RealAiService (local FastAPI dev server)
/// default                        → RunPodAiService (production)
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);
const bool _useRunPod = bool.fromEnvironment('USE_RUNPOD', defaultValue: true);

enum CaptureStatus { idle, imageSelected, analyzing, done, error }

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
  final ImagePicker _picker;
  final HistoryService _historyService;
  final String? _userId;
  final NotificationNotifier _notifications;

  CaptureNotifier(
    this._aiService,
    this._picker,
    this._historyService,
    this._userId,
    this._notifications,
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

  Future<AnalysisResult?> startAnalysis() async {
    final xfile = state.selectedXFile;
    if (xfile == null) return null;
    state = state.copyWith(status: CaptureStatus.analyzing);
    return _runAnalysis(xfile);
  }

  Future<AnalysisResult?> _runAnalysis(XFile xfile) async {
    try {
      final result = await _aiService.analyzeImage(
        imageFile: xfile,
        batchName: state.batchName,
      );
      state = state.copyWith(status: CaptureStatus.done, result: result);
      await _notifications.addAnalysisCompleted(result);
      final userId = _userId;
      if (userId != null) {
        try {
          final morphPath = result.morphologyImageBytes != null
              ? await _historyService.uploadImage(
                  userId: userId,
                  analysisId: result.id,
                  bytes: result.morphologyImageBytes!,
                  filename: 'morphology.jpg')
              : null;
          final colorPath = result.colorImageBytes != null
              ? await _historyService.uploadImage(
                  userId: userId,
                  analysisId: result.id,
                  bytes: result.colorImageBytes!,
                  filename: 'color.jpg')
              : null;
          await _historyService.saveAnalysis(
            data: AnalysisRecord.toDatabaseMap(
              result,
              userId,
              morphologyImagePath: morphPath,
              colorImagePath: colorPath,
            ),
          );
        } catch (e) {
          final message = e.toString();
          debugPrint('History save failed: $message');
          await _notifications.addHistorySaveFailed(
            result: result,
            errorMessage: message,
          );
          state = state.copyWith(historySaveError: message);
        }
      }
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

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(
    ref.watch(aiServiceProvider),
    ref.watch(imagePickerProvider),
    ref.watch(historyServiceProvider),
    ref.watch(currentUserProvider)?.id,
    ref.read(notificationProvider.notifier),
  );
});
