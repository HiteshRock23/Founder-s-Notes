import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/entities/auth_tokens.dart';
import 'package:mobile/core/storage/token_storage.dart';
import 'package:mobile/features/auth/data/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  AuthRepositoryImpl(this._authService, this._tokenStorage);

  @override
  Future<AuthTokens> login(String email, String password) async {
    final response = await _authService.login(email, password);
    
    await _tokenStorage.saveAccessToken(response.accessToken);
    await _tokenStorage.saveRefreshToken(response.refreshToken);
    
    return response;
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clearTokens();
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _tokenStorage.getAccessToken();
    return token != null;
  }
}
