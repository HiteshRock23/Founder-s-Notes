import '../entities/project.dart';
import '../entities/item.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectDetail(String id);
  Future<List<Item>> getProjectItems(String projectId);
  Future<Project> createProject(String name, String? description);

  /// Renames [projectId] to [newName]. Returns the updated Project.
  Future<Project> renameProject(String projectId, String newName);

  /// Permanently deletes [projectId] from the backend.
  Future<void> deleteProject(String projectId);

  /// Uploads a file item (PDF, image, doc) to [projectId].
  /// [filePath] is the absolute path on the device returned by file_picker.
  Future<Item> createFileItem({
    required String projectId,
    required String title,
    required String filePath,
    required String fileName,
  });

  /// Creates a new item inside [projectId].
  /// Only [title] is required; all other fields are type-specific.
  Future<Item> createItem({
    required String projectId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  });
}
