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
    // Data layer returns a ProjectModel which IS-A Project — clean domain boundary.
    return remoteDataSource.createProject(name, description);
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

