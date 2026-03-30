import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/entities/auth_tokens.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_service.dart';
import 'package:mobile/core/errors/api_exception.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._authService, this._tokenStorage);

  @override
  Future<AuthTokens> login(String email, String password) async {
    final response = await _authService.login(email, password);

    // Atomically persist both tokens
    await _tokenStorage.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    return response;
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User> getMe() async {
    return await _authService.getMe();
  }

  @override
  Future<String> refreshAccessToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw UnauthenticatedException();
    }

    final newAccessToken =
        await _authService.refreshAccessToken(refreshToken);
    await _tokenStorage.saveAccessToken(newAccessToken);
    return newAccessToken;
  }
}
