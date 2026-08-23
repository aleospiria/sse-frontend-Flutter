import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/models/attachment.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

final stepAttachmentsProvider =
    FutureProvider.family<List<Attachment>, ({String processId, String stepId})>(
  (ref, params) async {
    final api = ref.watch(apiClientProvider);
    final response = await api.get(
        '/uploads/${params.processId}/${params.stepId}');
    debugPrint('ATTACHMENTS GET body: ${response.body}');
    final body = jsonDecode(response.body);
    final list = body is List ? body : body['attachments'] ?? [];
    final result = (list as List)
        .map((e) {
          debugPrint('ATTACHMENTS parsing: $e');
          return Attachment.fromJson(e as Map<String, dynamic>);
        })
        .toList();
    debugPrint('ATTACHMENTS parsed: ${result.length} items');
    return result;
  },
);
