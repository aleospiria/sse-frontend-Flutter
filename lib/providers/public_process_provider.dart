import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/public_process.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class PublicProcessData {
  final PublicProcess process;
  final List<PublicStep> steps;

  const PublicProcessData({required this.process, required this.steps});
}

final publicTraceabilityProvider =
    FutureProvider.family<PublicProcessData, String>((ref, code) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/public/process/$code');
  final body = jsonDecode(res.body) as Map<String, dynamic>;
  return PublicProcessData(
    process: PublicProcess.fromJson(body['process'] as Map<String, dynamic>),
    steps: (body['steps'] as List<dynamic>)
        .map((e) => PublicStep.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
