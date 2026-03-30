import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/constants/endpoints.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _dioClient.post(
      Endpoints.login,
      data: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Exchanges a refresh token for a fresh access token.
  /// Returns only the new access token string.
  Future<String> refreshAccessToken(String refreshToken) async {
    final response = await _dioClient.post(
      Endpoints.refreshToken,
      data: {'refresh': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    return data['access'] as String;
  }

  Future<UserModel> getMe() async {
    final response = await _dioClient.get(Endpoints.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
