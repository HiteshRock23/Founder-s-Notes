import '../entities/project.dart';
import '../entities/item.dart';

abstract class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<Project> getProjectDetail(String id);
  Future<List<Item>> getProjectItems(String projectId);
  Future<Project> createProject(String name, String? description);

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
