import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../models/user.dart';

class AuthService {
  static const _tokenKey = 'access_token';
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<({String token, User user})> login(String email, String password) async {
    final api = ApiService();
    final data = await api.login(email, password);
    final token = data['access_token'] as String;
    await saveToken(token);
    final user = await ApiService(token: token).getMe();
    return (token: token, user: user);
  }

  Future<void> logout() => clearToken();
}
