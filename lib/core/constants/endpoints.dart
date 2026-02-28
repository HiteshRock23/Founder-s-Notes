class Endpoints {
  Endpoints._();

  static const String baseUrl = 'http://10.226.177.227:8000/api/'; // Added trailing slash
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
}
