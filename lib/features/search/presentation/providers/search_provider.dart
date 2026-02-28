import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/entities/item.dart';
import '../../../projects/presentation/providers/project_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SearchState
// ─────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of what the search screen should render.
///
/// [isSearching] is true only while the debounce timer is pending — the UI
/// can show a subtle activity indicator without blocking the results.
class SearchState {
  final String query;
  final List<Project> filteredProjects;
  final List<Item> filteredNotes;
  final List<Item> filteredLinks;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.filteredProjects = const [],
    this.filteredNotes = const [],
    this.filteredLinks = const [],
    this.isSearching = false,
  });

  /// True when the user has typed something (even while the timer fires).
  bool get hasQuery => query.trim().isNotEmpty;

  /// Total result count across all sections.
  int get totalResults =>
      filteredProjects.length + filteredNotes.length + filteredLinks.length;

  SearchState copyWith({
    String? query,
    List<Project>? filteredProjects,
    List<Item>? filteredNotes,
    List<Item>? filteredLinks,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      filteredProjects: filteredProjects ?? this.filteredProjects,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      filteredLinks: filteredLinks ?? this.filteredLinks,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchNotifier
// ─────────────────────────────────────────────────────────────────────────────

/// Owns all search logic. The UI layer only calls [updateQuery] / [clearSearch].
///
/// Architecture notes:
/// • Filtering runs OUTSIDE widget build() — no expensive work in the UI tree.
/// • A 300 ms debounce prevents filtering on every keystroke.
/// • Reads [projectsListProvider] and [allItemsProvider] via Ref so the search
///   index is always in sync with the live provider state.
/// • When graduating to backend search: replace [_runFilter] with an API call
///   and remove [allItemsProvider] — the public interface stays identical.
class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounce;

  static const _kDebounceMs = 300;

  SearchNotifier(this._ref) : super(const SearchState());

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  void updateQuery(String rawQuery) {
    final trimmed = rawQuery.trim();

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    // Show "searching" indicator while debounce is pending.
    state = state.copyWith(query: rawQuery, isSearching: true);

    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: _kDebounceMs),
      () => _runFilter(trimmed),
    );
  }

  void clearSearch() {
    _debounce?.cancel();
    state = const SearchState();
  }

  // ── Filtering ──────────────────────────────────────────────────────────────

  void _runFilter(String query) {
    final q = _normalize(query);

    // ── Projects ──────────────────────────────────────────────────────────
    final projects =
        (_ref.read(projectsListProvider).valueOrNull ?? []).where((p) {
      return _matchesAny(q, [p.name, p.description]);
    }).toList();

    // ── Items ─────────────────────────────────────────────────────────────
    final allItems = _ref.read(allItemsProvider);

    final notes = allItems.where((item) {
      if (item.type != ItemType.note) return false;
      return _matchesAny(q, [item.title, item.content ?? '']);
    }).toList();

    final links = allItems.where((item) {
      if (item.type != ItemType.link) return false;
      return _matchesAny(q, [
        item.title,
        item.description ?? '',
        item.url ?? '',
      ]);
    }).toList();

    state = state.copyWith(
      filteredProjects: projects,
      filteredNotes: notes,
      filteredLinks: links,
      isSearching: false,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Lowercase + trim for consistent comparison.
  String _normalize(String s) => s.toLowerCase().trim();

  /// Returns true if the normalised [query] appears in ANY of [fields].
  /// Null-safe: empty strings simply never match a non-empty query.
  bool _matchesAny(String query, List<String> fields) {
    for (final field in fields) {
      if (_normalize(field).contains(query)) return true;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// autoDispose: clears search state when the Search tab is not visible,
/// so returning to the tab always shows a clean idle state.
final searchProvider =
    StateNotifierProvider.autoDispose<SearchNotifier, SearchState>(
  (ref) => SearchNotifier(ref),
);
