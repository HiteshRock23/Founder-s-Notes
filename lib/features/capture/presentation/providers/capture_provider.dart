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

final captureProvider =
    StateNotifierProvider.family<CaptureNotifier, CaptureState, String>(
        (ref, rawText) {
  return CaptureNotifier(
    ref.watch(metadataRepositoryProvider),
    ref,
    rawText,
  );
});

class CaptureNotifier extends StateNotifier<CaptureState> {
  final MetadataRepository _repository;
  final Ref _ref;
  bool _hasFetched = false;

  static final _urlRegex =
      RegExp(r'(https?://[^\s]+)|([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?)');

  CaptureNotifier(this._repository, this._ref, String rawText)
      : super(CaptureState(url: _extractUrl(rawText))) {
    final normalizedUrl = state.url;
    // Extract a fallback title from the original text if there was extra context provided
    String cleanRaw = rawText;
    final match = _urlRegex.firstMatch(rawText);
    if (match != null) {
      cleanRaw = rawText.replaceAll(match.group(0)!, '').trim();
    }

    _fetchMetadata(normalizedUrl,
        fallbackTitle: cleanRaw.isNotEmpty ? cleanRaw : null);
  }

  static String _extractUrl(String raw) {
    final match = _urlRegex.firstMatch(raw);
    String extracted = match != null ? match.group(0)! : raw.trim();

    if (!extracted.startsWith('http') &&
        extracted.contains('.') &&
        !extracted.contains(' ')) {
      extracted = 'https://$extracted';
    } else if (!extracted.startsWith('http') && match != null) {
      extracted = 'https://$extracted';
    }
    return extracted;
  }

  Future<void> _fetchMetadata(String url, {String? fallbackTitle}) async {
    if (_hasFetched) return;
    _hasFetched = true;

    // Preserving fallback title while loading
    state = state.copyWith(isLoading: true, error: null, title: fallbackTitle);

    try {
      final metadata = await _repository.extractMetadata(url);

      if (metadata.status == 'success') {
        state = state.copyWith(
          isLoading: false,
          title: (metadata.title != null && metadata.title!.isNotEmpty)
              ? metadata.title
              : state.title,
          description: metadata.description,
          favicon: metadata.favicon,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              metadata.errorMessage ?? 'Failed to extract metadata server-side',
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
