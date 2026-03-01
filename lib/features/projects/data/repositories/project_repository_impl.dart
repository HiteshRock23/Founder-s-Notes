import '../../domain/entities/item.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_remote_datasource.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;

  ProjectRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Project>> getProjects() async {
    return remoteDataSource.getProjects();
  }

  @override
  Future<Project> getProjectDetail(String id) async {
    return remoteDataSource.getProjectDetail(id);
  }

  @override
  Future<List<Item>> getProjectItems(String projectId) async {
    return remoteDataSource.getProjectItems(projectId);
  }

  @override
  Future<Project> createProject(String name, String? description) async {
    return remoteDataSource.createProject(name, description);
  }

  @override
  Future<Project> renameProject(String projectId, String newName) async {
    return remoteDataSource.renameProject(projectId, newName);
  }

  @override
  Future<Project> toggleStar(String projectId, bool isStarred) async {
    return remoteDataSource.toggleStar(projectId, isStarred);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    return remoteDataSource.deleteProject(projectId);
  }

  @override
  Future<void> deleteMultipleProjects(List<String> projectIds) async {
    return remoteDataSource.deleteMultipleProjects(projectIds);
  }

  @override
  Future<Item> createFileItem({
    required String projectId,
    required String title,
    required String filePath,
    required String fileName,
  }) async {
    return remoteDataSource.createFileItem(
      projectId: projectId,
      title: title,
      filePath: filePath,
      fileName: fileName,
    );
  }

  @override
  Future<Item> updateItem({
    required String itemId,
    required String projectId,
    String? title,
    String? content,
    String? url,
    String? description,
  }) async {
    return remoteDataSource.updateItem(
      itemId: itemId,
      projectId: projectId,
      title: title,
      content: content,
      url: url,
      description: description,
    );
  }

  @override
  Future<void> deleteItem({
    required String itemId,
    required String projectId,
  }) async {
    return remoteDataSource.deleteItem(itemId: itemId, projectId: projectId);
  }

  @override
  Future<void> deleteMultipleItems({
    required List<String> itemIds,
    required String projectId,
  }) async {
    return remoteDataSource.deleteMultipleItems(itemIds: itemIds, projectId: projectId);
  }

  @override
  Future<Item> createItem({
    required String projectId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  }) async {
    return remoteDataSource.createItem(
      projectId: projectId,
      type: type,
      title: title,
      content: content,
      url: url,
      description: description,
    );
  }
}

