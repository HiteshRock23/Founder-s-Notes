import 'package:flutter/foundation.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/data/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<void> login(String email, String password) async {
    debugPrint('[AuthRepository] Legacy login requested. stubbed.');
    await _authService.login(email, password);
  }

  @override
  Future<void> logout() async {
    debugPrint('[AuthRepository] Logout requested. No-op.');
    // In Firebase, we would call FirebaseAuth.instance.signOut();
  }

  @override
  Future<bool> isAuthenticated() async {
    debugPrint('[AuthRepository] isAuthenticated check. Returning false (Pre-Firebase).');
    return false;
  }

  @override
  Future<User> getMe() async {
    return await _authService.getMe();
  }

  @override
  Future<void> register(String name, String email, String password) async {
    await _authService.register(name, email, password);
  }
}
