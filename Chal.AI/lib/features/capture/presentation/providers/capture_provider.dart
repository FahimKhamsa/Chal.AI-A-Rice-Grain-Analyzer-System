// features/capture/presentation/providers/capture_provider.dart
// Riverpod StateNotifier that manages all camera/capture state.
// Keeps UI code clean — screens just watch this notifier.
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../analysis/data/services/mock_ai_service.dart';
import '../../../analysis/data/services/real_ai_service.dart';
import '../../../analysis/domain/models/analysis_result.dart';

/// Set to `true` to use MockAiService (no backend needed).
/// Set to `false` (default) to use the real FastAPI backend.
const bool _useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

enum CaptureStatus { idle, analyzing, done, error }

class CaptureState {
  final String batchName;
  final File? selectedImage;
  final CaptureStatus status;
  final AnalysisResult? result;
  final String? errorMessage;
  final bool isFlashOn;

  const CaptureState({
    this.batchName = 'Batch A',
    this.selectedImage,
    this.status = CaptureStatus.idle,
    this.result,
    this.errorMessage,
    this.isFlashOn = false,
  });

  CaptureState copyWith({
    String? batchName,
    File? selectedImage,
    CaptureStatus? status,
    AnalysisResult? result,
    String? errorMessage,
    bool? isFlashOn,
  }) {
    return CaptureState(
      batchName: batchName ?? this.batchName,
      selectedImage: selectedImage ?? this.selectedImage,
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      isFlashOn: isFlashOn ?? this.isFlashOn,
    );
  }
}

class CaptureNotifier extends StateNotifier<CaptureState> {
  final AiService _aiService;
  final ImagePicker _picker;

  CaptureNotifier(this._aiService, this._picker) : super(const CaptureState());

  void setBatchName(String name) {
    state = state.copyWith(batchName: name.isEmpty ? 'Batch A' : name);
  }

  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
  }

  Future<AnalysisResult?> pickFromGallery() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (xfile == null) return null;
    final file = File(xfile.path);
    state = state.copyWith(selectedImage: file, status: CaptureStatus.analyzing);
    return _runAnalysis(file);
  }

  Future<AnalysisResult?> captureFromCamera() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (xfile == null) return null;
    final file = File(xfile.path);
    state = state.copyWith(selectedImage: file, status: CaptureStatus.analyzing);
    return _runAnalysis(file);
  }

  Future<AnalysisResult?> _runAnalysis(File file) async {
    try {
      final result = await _aiService.analyzeImage(
        imageFile: file,
        batchName: state.batchName,
      );
      state = state.copyWith(status: CaptureStatus.done, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        status: CaptureStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const CaptureState();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

/// Provides the active AI service.
/// Switch to MockAiService by running Flutter with --dart-define=USE_MOCK=true
final aiServiceProvider = Provider<AiService>(
  (ref) => _useMock ? MockAiService() : RealAiService(),
);

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  return CaptureNotifier(
    ref.watch(aiServiceProvider),
    ref.watch(imagePickerProvider),
  );
});
