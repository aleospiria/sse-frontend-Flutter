import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';

class SealResult {
  final String processId;
  final String processHash;
  final String closeTxHash;
  final String closeBlock;
  final int totalSteps;
  final String message;

  const SealResult({
    required this.processId,
    required this.processHash,
    required this.closeTxHash,
    required this.closeBlock,
    required this.totalSteps,
    required this.message,
  });

  factory SealResult.fromJson(Map<String, dynamic> j) => SealResult(
        processId: j['processId'] as String,
        processHash: j['processHash'] as String,
        closeTxHash: j['closeTxHash'] as String,
        closeBlock: j['closeBlock'].toString(),
        totalSteps: (j['totalSteps'] as num?)?.toInt() ?? 0,
        message: j['message'] ?? 'Proceso sellado con exito',
      );
}

final sealProcessProvider = StateNotifierProvider<SealProcessNotifier,
    AsyncValue<SealResult?>>((ref) {
  return SealProcessNotifier(ref);
});

class SealProcessNotifier extends StateNotifier<AsyncValue<SealResult?>> {
  final Ref ref;

  SealProcessNotifier(this.ref) : super(const AsyncValue.data(null));

  ApiClient get _api => ref.read(apiClientProvider);

  Future<SealResult> seal(String processId) async {
    state = const AsyncValue.loading();
    try {
      final res = await _api.post('/process/$processId/close');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final result = SealResult.fromJson(body);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}