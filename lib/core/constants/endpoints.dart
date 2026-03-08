class Endpoints {
  Endpoints._();

  // Current connection strategy: Use adb reverse for physical devices via USB.
  // Command: adb reverse tcp:8000 tcp:8000
  // 127.0.0.1 works for physical devices (with adb reverse) and Simulators.
  // 10.0.2.2 is for Android Emulators.
  // 10.0.2.2 is Android Emulator's alias for the host machine's localhost.
  static const String baseUrl = "https://foundernotes.lyrprompt.cloud/";
  static const int receiveTimeout = 30000;
  static const int connectionTimeout = 30000;

  // Auth
  static const String login = 'api/auth/login/';
  static const String refreshToken = 'api/auth/token/refresh/';

  // Projects
  static const String projects = 'api/projects/';
  static String projectDetail(String id) => 'api/projects/$id/';
  static String projectItems(String projectId) => 'api/projects/$projectId/items/';
  // POST to the same URL as GET items — REST convention for list+create.
  static String createItem(String projectId) => 'api/projects/$projectId/items/';
  // PATCH / DELETE use the same detail URL.
  static String renameProject(String id) => 'api/projects/$id/';
  static String deleteProject(String id) => 'api/projects/$id/';
  static const String batchDeleteProjects = 'api/projects/batch-delete/';

  // Items — flat endpoint for update/delete
  // PATCH /api/items/{id}/   DELETE /api/items/{id}/
  static String itemDetail(String itemId) => 'api/items/$itemId/';
  static const String batchDeleteItems = 'api/items/batch-delete/';

  // Metadata
  static const String extractMetadata = 'api/metadata/extract/';
}
