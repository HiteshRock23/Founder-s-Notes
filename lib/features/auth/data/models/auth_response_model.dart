import '../../domain/entities/auth_tokens.dart';

class AuthResponseModel extends AuthTokens {
  const AuthResponseModel({
    required super.accessToken,
    required super.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
    );
  }

  // Map to entity
  AuthTokens toEntity() => AuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
}
