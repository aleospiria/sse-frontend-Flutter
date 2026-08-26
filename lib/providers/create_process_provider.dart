import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class Client {
  final String id;
  final String name;
  Client({required this.id, required this.name});
  factory Client.fromJson(Map<String, dynamic> j) =>
      Client(id: j['id'] as String, name: j['name'] as String);
}

final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/clients');
  final body = jsonDecode(res.body) as List;
  return body.map((j) => Client.fromJson(j as Map<String, dynamic>)).toList();
});

final templatesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/templates');
  final body = jsonDecode(res.body) as List;
  return body.cast<Map<String, dynamic>>();
});

final templateDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/templates/$id');
  final body = jsonDecode(res.body);
  if (body is Map<String, dynamic>) return body;
  return null;
});

final nextCodeProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, code) async {
  if (code.isEmpty) return null;
  final api = ref.read(apiClientProvider);
  final res = await api.get('/process/next-code/$code');
  final body = jsonDecode(res.body);
  if (body is Map<String, dynamic>) return body;
  return null;
});
