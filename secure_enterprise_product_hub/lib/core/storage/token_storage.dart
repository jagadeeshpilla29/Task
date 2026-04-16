import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      _memory = null;

  TokenStorage.memory() : _storage = null, _memory = <String, String>{};

  static const _tokenKey = 'secure_product_hub.access_token';
  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  Future<String?> readToken() async {
    final memory = _memory;
    if (memory != null) {
      return memory[_tokenKey];
    }
    return _storage!.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) {
    final memory = _memory;
    if (memory != null) {
      memory[_tokenKey] = token;
      return Future.value();
    }
    return _storage!.write(key: _tokenKey, value: token);
  }

  Future<void> clear() {
    final memory = _memory;
    if (memory != null) {
      memory.remove(_tokenKey);
      return Future.value();
    }
    return _storage!.delete(key: _tokenKey);
  }
}
