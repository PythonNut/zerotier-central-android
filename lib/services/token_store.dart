import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _tokenKey = 'legacy_central_api_token';
  final FlutterSecureStorage _storage;

  TokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() async {
    final value = await _storage.read(key: _tokenKey);
    final token = value?.trim();
    return token == null || token.isEmpty ? null : token;
  }

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token.trim());

  Future<void> clear() => _storage.delete(key: _tokenKey);
}
