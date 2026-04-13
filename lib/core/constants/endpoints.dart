class Endpoints {
  Endpoints._();

  // Current connection strategy: Use adb reverse for physical devices via USB.
  // Command: adb reverse tcp:8000 tcp:8000
  // 127.0.0.1 works for physical devices (with adb reverse) and Simulators.
  // 10.0.2.2 is for Android Emulators.
  //
  // ⚠️  Your IP changes every time you reconnect to Wi-Fi.
  //     Run `ipconfig` (Windows) to find your current IPv4 address.
  //     Or use `adb reverse tcp:8000 tcp:8000` and set baseUrl to 10.0.2.2 (emulator)
  //     or 127.0.0.1 (physical device with adb reverse) to avoid this problem.
  //
  // static const String baseUrl = "https://foundernotes.lyrprompt.cloud/";
  static const String baseUrl = "http://172.20.10.176:8000/";  // ← current Wi-Fi IP
  static const int receiveTimeout = 30000;
  static const int connectionTimeout = 30000;

  // Auth (Legacy JWT endpoints removed, replace with Firebase logic if needed)
  // static const String login = 'api/auth/login/';
  // static const String refreshToken = 'api/auth/token/refresh/';
  // static const String me = 'api/auth/me/';
  // static const String register = 'api/auth/register/';

  // Projects
  static const String projects = 'api/projects/';
  static String projectDetail(String id) => 'api/projects/$id/';
  static String projectItems(String projectId) =>
      'api/projects/$projectId/items/';
  // POST to the same URL as GET items — REST convention for list+create.
  static String createItem(String projectId) =>
      'api/projects/$projectId/items/';
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
