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
  final data = await api.get('/clients');
  return (data as List).map((j) => Client.fromJson(j)).toList();
});

final templatesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/templates');
  return (data as List).cast<Map<String, dynamic>>();
});

final templateDetailProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get('/templates/$id');
  return data as Map<String, dynamic>?;
});

final nextCodeProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, code) async {
  if (code.isEmpty) return null;
  final api = ref.read(apiClientProvider);
  final data = await api.get('/process/next-code/$code');
  return data as Map<String, dynamic>?;
});
