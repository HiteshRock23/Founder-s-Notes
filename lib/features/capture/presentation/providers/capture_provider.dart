import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/metadata_repository.dart';
import '../../../../features/projects/domain/entities/item.dart';
import '../../../../features/projects/presentation/providers/project_provider.dart';

class CaptureState {
  final String url;
  final bool isLoading;
  final String? title;
  final String? description;
  final String? favicon;
  final String? error;
  final bool isSaved;
  final bool isSubmitting;

  const CaptureState({
    required this.url,
    this.isLoading = false,
    this.title,
    this.description,
    this.favicon,
    this.error,
    this.isSaved = false,
    this.isSubmitting = false,
  });

  CaptureState copyWith({
    String? url,
    bool? isLoading,
    String? title,
    String? description,
    String? favicon,
    String? error,
    bool? isSaved,
    bool? isSubmitting,
  }) {
    return CaptureState(
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      title: title ?? this.title,
      description: description ?? this.description,
      favicon: favicon ?? this.favicon,
      error: error, // Can be set to null specifically
      isSaved: isSaved ?? this.isSaved,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final captureProvider = StateNotifierProvider.family<CaptureNotifier, CaptureState, String>((ref, url) {
  return CaptureNotifier(
    ref.watch(metadataRepositoryProvider),
    ref,
    url,
  );
});

class CaptureNotifier extends StateNotifier<CaptureState> {
  final MetadataRepository _repository;
  final Ref _ref;
  bool _hasFetched = false;

  CaptureNotifier(this._repository, this._ref, String url)
      : super(CaptureState(url: url)) {
    // Automatically trigger metadata fetch on initialization
    _fetchMetadata(url);
  }

  Future<void> _fetchMetadata(String url) async {
    if (_hasFetched) return;
    _hasFetched = true;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final metadata = await _repository.extractMetadata(url);
      
      if (metadata.status == 'success') {
        state = state.copyWith(
          isLoading: false,
          title: metadata.title,
          description: metadata.description,
          favicon: metadata.favicon,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: metadata.errorMessage ?? 'Failed to extract metadata',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error or unable to parse metadata',
      );
    }
  }

  Future<void> saveToProject({
    required String projectId,
    required String title,
    required String description,
  }) async {
    if (state.isSubmitting) return; // Prevent double taps

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _ref.read(addItemProvider(projectId).notifier).addItem(
        type: ItemType.link,
        title: title,
        url: state.url,
        description: description,
      );
      state = state.copyWith(isSaved: true, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to save to project: ${e.toString()}',
      );
    }
  }
}
