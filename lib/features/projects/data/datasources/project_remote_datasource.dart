import 'package:dio/dio.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/constants/endpoints.dart';
import '../../domain/entities/item.dart';
import '../models/project_model.dart';
import '../models/item_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel> getProjectDetail(String id);
  Future<List<ItemModel>> getProjectItems(String projectId);
  Future<ProjectModel> createProject(String name, String? description);
  Future<ProjectModel> renameProject(String projectId, String newName);
  Future<void> deleteProject(String projectId);
  Future<ItemModel> createFileItem({
    required String projectId,
    required String title,
    required String filePath,
    required String fileName,
  });
  Future<ItemModel> createItem({
    required String projectId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  });
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final DioClient _dioClient;

  ProjectRemoteDataSourceImpl(this._dioClient);

  @override
  Future<List<ProjectModel>> getProjects() async {
    final response = await _dioClient.get(Endpoints.projects);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProjectModel> getProjectDetail(String id) async {
    final response = await _dioClient.get(Endpoints.projectDetail(id));
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ItemModel>> getProjectItems(String projectId) async {
    final response = await _dioClient.get(Endpoints.projectItems(projectId));
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => ItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProjectModel> createProject(String name, String? description) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final response = await _dioClient.post(Endpoints.projects, data: body);
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProjectModel> renameProject(String projectId, String newName) async {
    final response = await _dioClient.patch(
      Endpoints.renameProject(projectId),
      data: {'name': newName.trim()},
    );
    return ProjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete(Endpoints.deleteProject(projectId));
  }

  @override
  Future<ItemModel> createFileItem({
    required String projectId,
    required String title,
    required String filePath,
    required String fileName,
  }) async {
    // The backend serializer uses `file_upload` (write-only FileField).
    // Sending `file` would be a no-op — it's a read-only SerializerMethodField.
    final formData = FormData.fromMap({
      'type': 'file',
      'title': title.trim(),
      'file_upload': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _dioClient.post(
      Endpoints.createItem(projectId),
      data: formData,
      // NOTE: Do NOT set Options(contentType: multipartFormDataContentType) here.
      // Dio detects FormData and sets the correct multipart/form-data boundary
      // automatically. Overriding it strips the boundary string AND Dio's built-in
      // JSON response decoder — causing response.data to come back as a raw String
      // instead of a Map<String, dynamic>, which would throw a TypeError on cast.
    );
    return ItemModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ItemModel> createItem({
    required String projectId,
    required ItemType type,
    required String title,
    String? content,
    String? url,
    String? description,
  }) async {
    // 'project' is NOT sent in the body — the nested URL path
    // (/projects/{id}/items/) already supplies project_pk to Django's
    // perform_create via URL kwargs. Sending it again triggers
    // validate_project ownership checks that can fail in dev/anon mode.
    final body = <String, dynamic>{
      'type': type.name, // 'note' | 'link' | 'file'
      'title': title.trim(),
      if (content != null && content.trim().isNotEmpty) 'content': content.trim(),
      if (url != null && url.trim().isNotEmpty) 'url': url.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
    final response =
        await _dioClient.post(Endpoints.createItem(projectId), data: body);
    return ItemModel.fromJson(response.data as Map<String, dynamic>);
  }
}
