import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token store backed by flutter_secure_storage.
///
/// Tokens are NEVER stored in SharedPreferences or plain text.
/// All keys are private constants to prevent magic-string bugs.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Atomically persists both tokens in parallel.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
