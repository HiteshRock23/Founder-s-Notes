class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  @override
  String toString() =>
      'AuthTokens(accessToken: $accessToken, refreshToken: $refreshToken)';
}
