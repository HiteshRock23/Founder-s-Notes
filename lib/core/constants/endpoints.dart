class Endpoints {
  Endpoints._();

  // ── Connection Strategy ───────────────────────────────────────────────────
  // Physical device on same Wi-Fi → use machine's IPv4 (run ipconfig)
  // Physical device via USB       → adb reverse tcp:8000 tcp:8000 then use 127.0.0.1
  // Android Emulator              → use 10.0.2.2
  //
  // Run ipconfig on Windows to get your current IPv4.
  static const String baseUrl = 'http://10.132.244.227:8000/';

  // Reduced from 30s → 10s so a dead server fails fast instead of infinite-loading.
  static const int connectionTimeout = 10000; // 10 seconds
  static const int receiveTimeout = 15000;    // 15 seconds

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String me = 'api/auth/me/';

  // ── Projects ──────────────────────────────────────────────────────────────
  static const String projects = 'api/projects/';
  static String projectDetail(String id) => 'api/projects/$id/';
  static String projectItems(String projectId) =>
      'api/projects/$projectId/items/';
  static String createItem(String projectId) =>
      'api/projects/$projectId/items/';
  static String renameProject(String id) => 'api/projects/$id/';
  static String deleteProject(String id) => 'api/projects/$id/';
  static const String batchDeleteProjects = 'api/projects/batch-delete/';

  // ── Items ─────────────────────────────────────────────────────────────────
  static String itemDetail(String itemId) => 'api/items/$itemId/';
  static const String batchDeleteItems = 'api/items/batch-delete/';

  // ── Metadata ──────────────────────────────────────────────────────────────
  static const String extractMetadata = 'api/metadata/extract/';
}
