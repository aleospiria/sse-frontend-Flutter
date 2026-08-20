import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';
import 'package:sse_frontend_mobil/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(authServiceProvider).client;
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  const AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _authService.getToken();
    if (token != null) {
      final user = await _authService.getStoredUser();
      if (user != null) {
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: user,
        );
        return;
      }
    }
    state = const AuthState(isLoading: false);
  }

  Future<LoginResult> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(username, password);
      if (result is LoginSuccess) {
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
      }
      return result;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexion',
      );
      rethrow;
    }
  }

  Future<void> completePasswordChange({
    required String username,
    required String newPassword,
    required String session,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.completePasswordChange(
        username: username,
        newPassword: newPassword,
        session: session,
      );
      if (result is LoginSuccess) {
        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          user: result.user,
        );
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      rethrow;
    }
  }

  Future<void> clearSession() async {
    await _authService.logout();
    state = const AuthState(isLoading: false);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isLoading: false);
  }
}
