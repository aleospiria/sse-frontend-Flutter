import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/process.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

final processListProvider =
    StateNotifierProvider<ProcessListNotifier, AsyncValue<List<Process>>>(
        (ref) {
  return ProcessListNotifier(ref.watch(apiClientProvider));
});

class ProcessListNotifier extends StateNotifier<AsyncValue<List<Process>>> {
  final ApiClient _api;

  ProcessListNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/process');
      final body = jsonDecode(response.body);
      final list = (body as List)
          .map((e) => Process.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();
}
