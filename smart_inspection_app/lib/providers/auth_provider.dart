import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  User? currentUser;
  String? token;
  String? error;

  ApiService get api => ApiService(token: token);

  Future<void> checkAuth() async {
    final saved = await _authService.getToken();
    if (saved == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final user = await ApiService(token: saved).getMe();
      token = saved;
      currentUser = user;
      status = AuthStatus.authenticated;
    } catch (_) {
      await _authService.clearToken();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    error = null;
    try {
      final result = await _authService.login(email, password);
      token = result.token;
      currentUser = result.user;
      status = AuthStatus.authenticated;
      ConnectivityService().init(ApiService(token: token));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      error = '서버에 연결할 수 없습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    token = null;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
