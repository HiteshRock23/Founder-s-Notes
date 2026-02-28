import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<AuthTokens> login(String email, String password);
  Future<void> logout();
  Future<bool> isAuthenticated();
}
