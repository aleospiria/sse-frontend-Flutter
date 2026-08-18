import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';

class AuthService {
  ApiClient? _apiClient;
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'sse_token';
  static const _userKey = 'sse_user';

  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  void setApiClient(ApiClient client) {
    _apiClient = client;
  }

  ApiClient get client {
    assert(_apiClient != null, 'ApiClient not set. Call setApiClient first.');
    return _apiClient!;
  }

  Future<LoginResult> login(String username, String password) async {
    final response = await client.post('/auth/login', body: {
      'username': username,
      'password': password,
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (body['requires_password_change'] == true) {
      return LoginResult.requiresPasswordChange(
        username: body['username'] as String,
        session: body['session'] as String,
      );
    }

    final token = body['token'] as String;
    final user = User.fromJson(body['user'] as Map<String, dynamic>);

    await _saveAuth(token, user);

    return LoginResult.success(token: token, user: user);
  }

  Future<LoginResult> completePasswordChange({
    required String username,
    required String newPassword,
    required String session,
  }) async {
    final response = await client.post('/auth/complete-password-change', body: {
      'username': username,
      'new_password': newPassword,
      'session': session,
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    final user = User.fromJson(body['user'] as Map<String, dynamic>);

    await _saveAuth(token, user);

    return LoginResult.success(token: token, user: user);
  }

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<User?> getStoredUser() async {
    final json = await _storage.read(key: _userKey);
    if (json == null) return null;
    return User.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<User> fetchCurrentUser() async {
    final response = await client.get('/auth/me');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final user = User.fromJson(body['user'] as Map<String, dynamic>);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    return user;
  }

  Future<void> _saveAuth(String token, User user) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }
}

sealed class LoginResult {
  const LoginResult();

  factory LoginResult.success({
    required String token,
    required User user,
  }) = LoginSuccess;

  factory LoginResult.requiresPasswordChange({
    required String username,
    required String session,
  }) = LoginRequiresPasswordChange;
}

class LoginSuccess extends LoginResult {
  final String token;
  final User user;

  const LoginSuccess({required this.token, required this.user});
}

class LoginRequiresPasswordChange extends LoginResult {
  final String username;
  final String session;

  const LoginRequiresPasswordChange({
    required this.username,
    required this.session,
  });
}
