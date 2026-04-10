import 'package:flutter/foundation.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

/// Service for authentication. 
/// Legacy JWT methods have been stubbed out in preparation for Firebase Auth.
class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<AuthResponseModel> login(String email, String password) async {
    debugPrint('[AuthService] Legacy login called. No-op.');
    throw UnimplementedError('Legacy JWT login is disabled. Use Firebase Auth.');
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    debugPrint('[AuthService] Legacy token refresh called. No-op.');
    throw UnimplementedError('Legacy JWT refresh is disabled.');
  }

  Future<UserModel> getMe() async {
    debugPrint('[AuthService] Legacy getMe called. No-op.');
    throw UnauthenticatedException();
  }

  Future<void> register(String name, String email, String password) async {
    debugPrint('[AuthService] Legacy register called. No-op.');
    throw UnimplementedError('Legacy JWT registration is disabled. Use Firebase Auth.');
  }
}

class UnauthenticatedException implements Exception {}
