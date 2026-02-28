import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/core/constants/endpoints.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';

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
    return AuthResponseModel.fromJson(response.data);
  }
}
