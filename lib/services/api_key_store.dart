import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Anthropic API key in the platform keychain / keystore.
class ApiKeyStore {
  static const _key = 'anthropic_api_key';
  final FlutterSecureStorage _storage;

  ApiKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> read() => _storage.read(key: _key);
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  Future<void> clear() => _storage.delete(key: _key);
}
