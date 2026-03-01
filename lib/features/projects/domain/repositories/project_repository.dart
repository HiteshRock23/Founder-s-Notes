import '../entities/project.dart';
import '../entities/item.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectDetail(String id);
  Future<List<Item>> getProjectItems(String projectId);
  Future<Project> createProject(String name, String? description);

  /// Renames [projectId] to [newName]. Returns the updated Project.
  Future<Project> renameProject(String projectId, String newName);

  /// Toggles the star status of a project. Returns the updated Project.
  Future<Project> toggleStar(String projectId, bool isStarred);

  /// Permanently deletes [projectId] from the backend.
  Future<void> deleteProject(String projectId);

  /// Permanently deletes multiple projects by ID.
  Future<void> deleteMultipleProjects(List<String> projectIds);

  /// Uploads a file item (PDF, image, doc) to [projectId].
  Future<Item> createFileItem({
    required String projectId,
    required String title,
    required String filePath,
    required String fileName,
  });

  /// PATCHes mutable fields on an existing item.
  Future<Item> updateItem({
    required String itemId,
    required String projectId,
    String? title,
    String? content,
    String? url,
    String? description,
  });

  /// DELETEs an item permanently from the backend.
  Future<void> deleteItem({
    required String itemId,
    required String projectId,
  });

  /// Permanently deletes multiple items by ID.
  Future<void> deleteMultipleItems({
    required List<String> itemIds,
    required String projectId,
  });

  /// Creates a new item inside [projectId].
  Future<Item> createItem({
    required String projectId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  });
}
