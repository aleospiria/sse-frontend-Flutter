import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/attachment.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

final stepAttachmentsProvider =
    FutureProvider.family<List<Attachment>, ({String processId, String stepId})>(
  (ref, params) async {
    final api = ref.watch(apiClientProvider);
    final response = await api.get(
        '/uploads/${params.processId}/${params.stepId}');
    final body = jsonDecode(response.body);
    final list = body is List ? body : body['attachments'] ?? [];
    return (list as List)
        .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);
