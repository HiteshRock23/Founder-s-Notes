import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents the state of a multi-selection flow.
class SelectionState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  const SelectionState({
    this.isSelectionMode = false,
    this.selectedIds = const {},
  });

  SelectionState copyWith({
    bool? isSelectionMode,
    Set<String>? selectedIds,
  }) {
    return SelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

/// A generic notifier to manage a set of selected IDs and selection mode.
/// This keeps presentation-layer selection logic isolated from data providers.
class SelectionNotifier extends StateNotifier<SelectionState> {
  SelectionNotifier() : super(const SelectionState());

  void toggleSelectionMode() {
    state = state.copyWith(isSelectionMode: !state.isSelectionMode);
    if (!state.isSelectionMode) {
      clearSelection();
    }
  }

  void toggleSelection(String id) {
    if (!state.isSelectionMode) {
      state = state.copyWith(isSelectionMode: true, selectedIds: {id});
      return;
    }

    final currentSelected = Set<String>.from(state.selectedIds);
    if (currentSelected.contains(id)) {
      currentSelected.remove(id);
    } else {
      currentSelected.add(id);
    }

    state = state.copyWith(
      selectedIds: currentSelected,
      // Auto-exit selection mode if the last item is deselected
      isSelectionMode: currentSelected.isNotEmpty,
    );
  }

  void selectAll(List<String> ids) {
    state = state.copyWith(
      isSelectionMode: true,
      selectedIds: Set<String>.from(ids),
    );
  }

  void clearSelection() {
    state = const SelectionState();
  }
}

final projectSelectionProvider =
    StateNotifierProvider.autoDispose<SelectionNotifier, SelectionState>((ref) {
  return SelectionNotifier();
});

final itemSelectionProvider =
    StateNotifierProvider.autoDispose<SelectionNotifier, SelectionState>((ref) {
  return SelectionNotifier();
});
