import '../entities/auth_tokens.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthTokens> login(String email, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<User> getMe();

  /// Reads the stored refresh token, exchanges it for a new access token,
  /// persists the new access token, and returns it.
  Future<String> refreshAccessToken();
}
