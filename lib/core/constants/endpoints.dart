class Endpoints {
  Endpoints._();

  // 10.0.2.2 is Android Emulator's alias for the host machine's localhost.
  // Change to your PC's LAN IP (e.g. 192.168.x.x) if testing on a physical device.
  static const String baseUrl = 'http://172.20.10.108:8000/api/';
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;

  // Auth
  static const String login = 'auth/login/';
  static const String refreshToken = 'auth/token/refresh/';

  // Projects
  static const String projects = 'projects/';
  static String projectDetail(String id) => 'projects/$id/';
  static String projectItems(String projectId) => 'projects/$projectId/items/';
  // POST to the same URL as GET items — REST convention for list+create.
  static String createItem(String projectId) => 'projects/$projectId/items/';
  // PATCH / DELETE use the same detail URL.
  static String renameProject(String id) => 'projects/$id/';
  static String deleteProject(String id) => 'projects/$id/';
  static const String batchDeleteProjects = 'projects/batch-delete/';

  // Items — flat endpoint for update/delete
  // PATCH /api/items/{id}/   DELETE /api/items/{id}/
  static String itemDetail(String itemId) => 'items/$itemId/';
  static const String batchDeleteItems = 'items/batch-delete/';

  // Metadata
  static const String extractMetadata = 'metadata/extract/';
}
