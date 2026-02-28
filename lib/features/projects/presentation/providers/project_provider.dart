import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/item.dart';
import '../../domain/repositories/project_repository.dart';
import '../../data/datasources/project_remote_datasource.dart';
import '../../data/repositories/project_repository_impl.dart';

// ──────────────────────────────────────────────
// Dependency Injection Graph
// ──────────────────────────────────────────────

final projectRemoteDataSourceProvider = Provider<ProjectRemoteDataSource>((ref) {
  return ProjectRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(
    remoteDataSource: ref.watch(projectRemoteDataSourceProvider),
  );
});

// ──────────────────────────────────────────────
// Projects List State
// ──────────────────────────────────────────────

final projectsListProvider =
    StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  return ProjectsNotifier(ref.watch(projectRepositoryProvider));
});

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  final ProjectRepository _repository;

  ProjectsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  // ── Load ──────────────────────────────────
  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getProjects());
  }

  // ── Create ────────────────────────────────
  /// Creates a project on the backend and inserts it at the top of the
  /// local list — no full refetch. Throws on error so the UI can handle it.
  Future<void> createProject(String name, String? description) async {
    // Capture current list before mutating state.
    final currentList = state.valueOrNull ?? [];

    try {
      final newProject = await _repository.createProject(name, description);

      // Immutably prepend new project — O(n) copy, acceptable for SaaS lists.
      state = AsyncValue.data([newProject, ...currentList]);
    } catch (e, stack) {
      // Restore previous state so the list is not left in a broken condition.
      state = AsyncValue.data(currentList);
      // Re-throw so the UI layer can show a localized error in the sheet.
      Error.throwWithStackTrace(e, stack);
    }
  }
}

// ──────────────────────────────────────────────
// Project Items State
// ──────────────────────────────────────────────

final projectItemsProvider =
    FutureProvider.family<List<Item>, String>((ref, projectId) async {
  return ref.watch(projectRepositoryProvider).getProjectItems(projectId);
});

// ──────────────────────────────────────────────
// Add Item State
// ──────────────────────────────────────────────

/// Scoped to a single [projectId]. Exposes an [addItem] method that POSTs
/// to the backend and then invalidates [projectItemsProvider] so the items
/// list refreshes automatically.
class AddItemNotifier extends StateNotifier<AsyncValue<void>> {
  final ProjectRepository _repository;
  final Ref _ref;
  final String _projectId;

  AddItemNotifier(this._repository, this._ref, this._projectId)
      : super(const AsyncValue.data(null));

  Future<void> addItem({
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createItem(
        projectId: _projectId,
        type: type,
        title: title,
        content: content,
        url: url,
        description: description,
      );
      // Invalidate so projectItemsProvider re-fetches silently.
      _ref.invalidate(projectItemsProvider(_projectId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Re-throw so the sheet can display a human-readable error.
      Error.throwWithStackTrace(e, stack);
    }
  }
}

final addItemProvider = StateNotifierProvider.autoDispose
    .family<AddItemNotifier, AsyncValue<void>, String>((ref, projectId) {
  return AddItemNotifier(
    ref.watch(projectRepositoryProvider),
    ref,
    projectId,
  );
});

