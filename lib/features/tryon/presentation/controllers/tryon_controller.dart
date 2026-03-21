import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/tryon/data/models/tryon_model.dart';
import 'package:virtual_tryon_app/features/tryon/data/camera_service.dart';
import 'package:virtual_tryon_app/core/network/api_service.dart';

part 'tryon_controller.g.dart';

@riverpod
class TryOnController extends _$TryOnController {
  @override
  TryOnState build() {
    return const TryOnState();
  }

  void setUserPhoto(PickedImage? photo) {
    state = state.copyWith(userPhoto: photo, error: null);
  }

  /// Size used when adding try-on results to cart (default M).
  void setTryOnCartSize(String size) {
    if (size.isEmpty) return;
    state = state.copyWith(tryOnCartSize: size);
  }

  /// Add dress to selection if not already selected (for deep-link / detail entry).
  void ensureDressSelected(Dress dress) {
    final selectedDresses = List<Dress>.from(state.selectedDresses);
    if (selectedDresses.any((d) => d.dressId == dress.dressId)) return;
    if (selectedDresses.length >= 5) {
      state = state.copyWith(
          error: 'You can select maximum 5 dresses at a time');
      return;
    }
    selectedDresses.add(dress);
    state = state.copyWith(selectedDresses: selectedDresses, error: null);
  }

  void toggleDressSelection(Dress dress) {
    final selectedDresses = List<Dress>.from(state.selectedDresses);
    final index = selectedDresses.indexWhere((d) => d.dressId == dress.dressId);

    if (index >= 0) {
      selectedDresses.removeAt(index);
      state = state.copyWith(selectedDresses: selectedDresses);
    } else {
      if (selectedDresses.length < 5) {
        selectedDresses.add(dress);
        state = state.copyWith(selectedDresses: selectedDresses, error: null);
      } else {
        state =
            state.copyWith(error: 'You can select maximum 5 dresses at a time');
      }
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedDresses: []);
  }

  void removeDress(int dressId) {
    final selectedDresses =
        state.selectedDresses.where((d) => d.dressId != dressId).toList();
    state = state.copyWith(selectedDresses: selectedDresses);
  }

  Future<bool> processTryOn() async {
    if (state.userPhoto == null || state.selectedDresses.isEmpty) {
      state = state.copyWith(
          error: 'Please capture a photo and select at least one dress');
      return false;
    }

    state = state.copyWith(
      isProcessing: true,
      hasProcessed: false,
      error: null,
      progress: 0.0,
      statusMessage: 'Preparing your photos...',
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final dressIds = state.selectedDresses.map((d) => d.dressId).toList();

      state = state.copyWith(
          progress: 0.2, statusMessage: 'Uploading to AI server...');

      final response = await apiService.processTryOn(
        userPhoto: state.userPhoto!,
        dressIds: dressIds,
      );

      // Parse the response using TryOnResponse
      final tryOnResponse = TryOnResponse.fromMap(response as Map<String, dynamic>);
      
      // Get successful results
      final results = tryOnResponse.results ?? [];
      final successfulResults = results.where((r) => r.success && r.displayUrl != null).toList();

      // Build status message
      String statusMessage;
      if (tryOnResponse.success) {
        statusMessage = 'Try-on completed for ${successfulResults.length}/${tryOnResponse.totalDresses ?? results.length} dresses';
      } else {
        statusMessage = tryOnResponse.message ?? 'Try-on failed';
      }

      state = state.copyWith(
        results: successfulResults,
        progress: 1.0,
        statusMessage: statusMessage,
        hasProcessed: true,
        isProcessing: false,
      );
      
      return successfulResults.isNotEmpty;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        statusMessage: 'Try-on failed',
        hasProcessed: false,
        isProcessing: false,
      );
      return false;
    }
  }

  void reset() {
    state = const TryOnState();
  }
}

class TryOnState {
  final PickedImage? userPhoto;
  final List<Dress> selectedDresses;
  final List<TryOnResult> results;
  final bool isProcessing;
  final bool hasProcessed;
  final String? error;
  final double progress;
  final String statusMessage;
  /// Cart line size when adding from try-on result flow.
  final String tryOnCartSize;

  const TryOnState({
    this.userPhoto,
    this.selectedDresses = const [],
    this.results = const [],
    this.isProcessing = false,
    this.hasProcessed = false,
    this.error,
    this.progress = 0.0,
    this.statusMessage = '',
    this.tryOnCartSize = 'M',
  });

  TryOnState copyWith({
    PickedImage? userPhoto,
    List<Dress>? selectedDresses,
    List<TryOnResult>? results,
    bool? isProcessing,
    bool? hasProcessed,
    String? error,
    double? progress,
    String? statusMessage,
    String? tryOnCartSize,
  }) {
    return TryOnState(
      userPhoto: userPhoto ?? this.userPhoto,
      selectedDresses: selectedDresses ?? this.selectedDresses,
      results: results ?? this.results,
      isProcessing: isProcessing ?? this.isProcessing,
      hasProcessed: hasProcessed ?? this.hasProcessed,
      error: error ?? this.error,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      tryOnCartSize: tryOnCartSize ?? this.tryOnCartSize,
    );
  }
}
