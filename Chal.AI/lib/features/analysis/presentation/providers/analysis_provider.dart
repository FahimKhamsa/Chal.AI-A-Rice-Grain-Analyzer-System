// features/analysis/presentation/providers/analysis_provider.dart
// Manages the toggle state for the bounding-box layer filter chips
// on the Analysis Result screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LayerVisibilityState {
  final bool showHealthy;
  final bool showBroken;
  final bool showDiscolored;

  const LayerVisibilityState({
    this.showHealthy = true,
    this.showBroken = true,
    this.showDiscolored = true,
  });

  LayerVisibilityState copyWith({
    bool? showHealthy,
    bool? showBroken,
    bool? showDiscolored,
  }) {
    return LayerVisibilityState(
      showHealthy: showHealthy ?? this.showHealthy,
      showBroken: showBroken ?? this.showBroken,
      showDiscolored: showDiscolored ?? this.showDiscolored,
    );
  }
}

class LayerVisibilityNotifier extends StateNotifier<LayerVisibilityState> {
  LayerVisibilityNotifier() : super(const LayerVisibilityState());

  void toggleHealthy() =>
      state = state.copyWith(showHealthy: !state.showHealthy);
  void toggleBroken() =>
      state = state.copyWith(showBroken: !state.showBroken);
  void toggleDiscolored() =>
      state = state.copyWith(showDiscolored: !state.showDiscolored);
}

final layerVisibilityProvider =
    StateNotifierProvider<LayerVisibilityNotifier, LayerVisibilityState>(
  (ref) => LayerVisibilityNotifier(),
);
