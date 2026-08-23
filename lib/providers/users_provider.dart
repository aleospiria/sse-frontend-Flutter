import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';

final usersProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<List<User>>>((ref) {
  return UsersNotifier(ref)..load();
});

class UsersNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final Ref ref;

  UsersNotifier(this.ref) : super(const AsyncValue.loading());

  ApiClient get _api => ref.read(apiClientProvider);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.get('/auth/users');
      final list = _api.parseList(res, User.fromJson);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();

  Future<User> create({
    required String username,
    required String email,
    String? name,
    String? password,
    UserRole role = UserRole.operario,
    String? industry,
  }) async {
    final res = await _api.post('/auth/users', body: {
      'username': username,
      'email': email,
      if (name != null && name.isNotEmpty) 'name': name,
      if (password != null && password.isNotEmpty) 'password': password,
      'role': role.name,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
    });
    final user = _api.parse(res, User.fromJson);
    load();
    return user;
  }

  Future<User> update(String id, {
    String? username,
    String? name,
    String? email,
    UserRole? role,
    String? industry,
    String? industrySpecialty,
    String? cedula,
    String? telefono,
    String? cargo,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (role != null) body['role'] = role.name;
    if (industry != null) body['industry'] = industry;
    if (industrySpecialty != null) body['industry_specialty'] = industrySpecialty;
    if (cedula != null) body['cedula'] = cedula;
    if (telefono != null) body['telefono'] = telefono;
    if (cargo != null) body['cargo'] = cargo;
    if (password != null && password.isNotEmpty) body['password'] = password;

    final res = await _api.put('/auth/users/$id', body: body);
    final user = _api.parse(res, User.fromJson);
    load();
    return user;
  }

  Future<void> delete(String id) async {
    await _api.delete('/auth/users/$id');
    load();
  }
}

// Operarios list for assignment pickers
final operariosProvider =
    FutureProvider<List<User>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/auth/operarios');
  return api.parseList(res, User.fromJson);
});

// User detail: assignments + activity
final userAssignmentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/auth/users/$userId/assignments');
  final body = jsonDecode(res.body) as List;
  return body.cast<Map<String, dynamic>>();
});

final userActivityProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/auth/users/$userId/activity');
  return jsonDecode(res.body) as Map<String, dynamic>;
});

// Audit log
final auditLogProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/auth/audit-log');
  final body = jsonDecode(res.body) as List;
  return body.cast<Map<String, dynamic>>();
});
