class Endpoints {
  Endpoints._();

  // Current connection strategy: Use adb reverse for physical devices via USB.
  // Command: adb reverse tcp:8000 tcp:8000
  // 127.0.0.1 works for physical devices (with adb reverse) and Simulators.
  // 10.0.2.2 is for Android Emulators.
  // 10.0.2.2 is Android Emulator's alias for the host machine's localhost.
  static const String baseUrl = "https://foundernotes.lyrprompt.cloud";
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
