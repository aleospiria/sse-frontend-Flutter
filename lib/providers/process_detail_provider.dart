import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/step.dart' as models;
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class ProcessDetail {
  final Map<String, dynamic> process;
  final List<models.Step> steps;

  const ProcessDetail({required this.process, required this.steps});
}

final processDetailProvider = FutureProvider.family<ProcessDetail, String>(
  (ref, processId) async {
    final api = ref.watch(apiClientProvider);
    final response = await api.get('/process/$processId');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final stepsList = (body['steps'] as List)
        .map((e) => models.Step.fromJson(e as Map<String, dynamic>))
        .toList();
    return ProcessDetail(
      process: body['process'] as Map<String, dynamic>,
      steps: stepsList,
    );
  },
);
