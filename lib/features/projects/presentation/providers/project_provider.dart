import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/providers/selection_provider.dart';
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
  /// Creates a project and inserts it at the top — no full refetch.
  Future<void> createProject(String name, String? description) async {
    final currentList = state.valueOrNull ?? [];
    try {
      final newProject = await _repository.createProject(name, description);
      state = AsyncValue.data([newProject, ...currentList]);
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }

  // ── Rename ────────────────────────────────
  /// PATCHes the backend and replaces only the renamed entry in the list.
  /// Uses the server's response as source of truth (avoids stale local state).
  Future<void> renameProject(String projectId, String newName) async {
    final currentList = state.valueOrNull ?? [];
    try {
      final updated = await _repository.renameProject(projectId, newName);
      state = AsyncValue.data([
        for (final p in currentList)
          if (p.id == projectId) updated else p,
      ]);
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }

  // ── Star Toggle ───────────────────────────
  /// PATCHes the backend and updates the star status immutably in the list.
  Future<void> toggleStar(String projectId, bool isStarred) async {
    final currentList = state.valueOrNull ?? [];
    try {
      final updated = await _repository.toggleStar(projectId, isStarred);
      state = AsyncValue.data([
        for (final p in currentList)
          if (p.id == projectId) updated else p,
      ]);
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }

  // ── Delete ────────────────────────────────
  /// DELETEs on the backend then filters the project out of the local list.
  Future<void> deleteProject(String projectId) async {
    final currentList = state.valueOrNull ?? [];
    try {
      await _repository.deleteProject(projectId);
      state = AsyncValue.data(
        currentList.where((p) => p.id != projectId).toList(),
      );
    } catch (e, stack) {
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }

  // ── Delete Multiple ───────────────────────
  Future<void> deleteMultiple(List<String> projectIds) async {
    final currentList = state.valueOrNull ?? [];
    try {
      await _repository.deleteMultipleProjects(projectIds);
      final idSet = Set<String>.from(projectIds);
      state = AsyncValue.data(
        currentList.where((p) => !idSet.contains(p.id)).toList(),
      );
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }
}


// ──────────────────────────────────────────────
// Project Items State
// ──────────────────────────────────────────────

final projectItemsProvider =
    StateNotifierProvider.family<ProjectItemsNotifier, AsyncValue<List<Item>>, String>((ref, projectId) {
  return ProjectItemsNotifier(ref.watch(projectRepositoryProvider), projectId);
});

class ProjectItemsNotifier extends StateNotifier<AsyncValue<List<Item>>> {
  final ProjectRepository _repository;
  final String _projectId;

  ProjectItemsNotifier(this._repository, this._projectId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getProjectItems(_projectId));
  }

  Future<void> updateItem(Item updatedItem) async {
    final currentList = state.valueOrNull ?? [];
    
    // 1) Call repository to perform PATCH
    await _repository.updateItem(
      itemId: updatedItem.id,
      projectId: updatedItem.projectId,
      title: updatedItem.title,
      content: updatedItem.content,
      url: updatedItem.url,
      description: updatedItem.description,
    );
    
    // 2) Replace item in state list immutably without refetching from network
    state = AsyncValue.data([
      for (final item in currentList)
        if (item.id == updatedItem.id) updatedItem else item
    ]);
  }

  /// Batch DELETEs on the backend then filters the items out of the local list.
  Future<void> deleteMultipleItems(List<String> itemIds) async {
    final currentList = state.valueOrNull ?? [];
    try {
      await _repository.deleteMultipleItems(itemIds: itemIds, projectId: _projectId);
      final idSet = Set<String>.from(itemIds);
      state = AsyncValue.data(
        currentList.where((i) => !idSet.contains(i.id)).toList(),
      );
    } catch (e, stack) {
      state = AsyncValue.data(currentList);
      Error.throwWithStackTrace(e, stack);
    }
  }
}

// ──────────────────────────────────────────────
// All Items (cross-project) — for Global Search
// ──────────────────────────────────────────────

/// Derives a flat list of every Item across all loaded projects.
///
/// Design: watches [projectsListProvider] so that if projects are added
/// or removed this provider re-evaluates automatically. For each project it
/// also watches [projectItemsProvider] so any item CRUD invalidation flows
/// through here to search without any extra wiring.
///
/// Cost: O(projects) provider subscriptions — negligible for SaaS-scale
/// project counts. When moving to backend search this provider is deleted
/// and SearchNotifier calls the API directly instead.
final allItemsProvider = Provider<List<Item>>((ref) {
  final projects = ref.watch(projectsListProvider).valueOrNull ?? [];
  return [
    for (final project in projects)
      ...ref.watch(projectItemsProvider(project.id)).valueOrNull ?? [],
  ];
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

  /// Uploads a file item via multipart form-data.
  Future<void> addFileItem({
    required String title,
    required String filePath,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createFileItem(
        projectId: _projectId,
        title: title,
        filePath: filePath,
        fileName: fileName,
      );
      _ref.invalidate(projectItemsProvider(_projectId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }

  /// PATCHes an existing item and refreshes the project items list.
  Future<void> editItem({
    required String itemId,
    String? title,
    String? content,
    String? url,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateItem(
        itemId: itemId,
        projectId: _projectId,
        title: title,
        content: content,
        url: url,
        description: description,
      );
      _ref.invalidate(projectItemsProvider(_projectId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }

  /// DELETEs an item and refreshes the project items list.
  Future<void> deleteItem(String itemId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteItem(itemId: itemId, projectId: _projectId);
      _ref.invalidate(projectItemsProvider(_projectId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      Error.throwWithStackTrace(e, stack);
    }
  }
}

final addItemProvider = StateNotifierProvider.family<AddItemNotifier, AsyncValue<void>, String>((ref, projectId) {
  return AddItemNotifier(
    ref.watch(projectRepositoryProvider),
    ref,
    projectId,
  );
});

