import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class StepVerify {
  final String stepRecordId;
  final String stepName;
  final String status; // ok | tampered | not_found | pending
  final String? dbHash;
  final String? recomputedHash;
  final String? chainHash;
  final String? txHash;
  final String? blockNumber;
  final bool? hashMatch;
  final bool? chainMatch;
  final String detail;

  StepVerify({
    required this.stepRecordId,
    required this.stepName,
    required this.status,
    this.dbHash,
    this.recomputedHash,
    this.chainHash,
    this.txHash,
    this.blockNumber,
    this.hashMatch,
    this.chainMatch,
    required this.detail,
  });

  factory StepVerify.fromJson(Map<String, dynamic> j) => StepVerify(
        stepRecordId: j['stepRecordId'] ?? '',
        stepName: j['stepName'] ?? '',
        status: j['status'] ?? 'pending',
        dbHash: j['dbHash'] as String?,
        recomputedHash: j['recomputedHash'] as String?,
        chainHash: j['chainHash'] as String?,
        txHash: j['txHash'] as String?,
        blockNumber: j['blockNumber']?.toString(),
        hashMatch: j['hashMatch'] as bool?,
        chainMatch: j['chainMatch'] as bool?,
        detail: j['detail'] ?? '',
      );
}

class VerifyData {
  final String processId;
  final String processName;
  final String integrity; // ok | compromised
  final int total;
  final int ok;
  final int pending;
  final int tampered;
  final List<StepVerify> steps;

  VerifyData({
    required this.processId,
    required this.processName,
    required this.integrity,
    required this.total,
    required this.ok,
    required this.pending,
    required this.tampered,
    required this.steps,
  });

  factory VerifyData.fromJson(Map<String, dynamic> j) {
    final summary = j['summary'] as Map<String, dynamic>? ?? {};
    return VerifyData(
      processId: j['processId'] ?? '',
      processName: j['processName'] ?? '',
      integrity: j['integrity'] ?? 'compromised',
      total: summary['total'] ?? 0,
      ok: summary['ok'] ?? 0,
      pending: summary['pending'] ?? 0,
      tampered: summary['tampered'] ?? 0,
      steps: (j['steps'] as List?)
              ?.map((e) => StepVerify.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get allOk => tampered == 0;
}

final processVerifyProvider =
    FutureProvider.family<VerifyData, String>((ref, processId) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/process/$processId/verify');
  final body = jsonDecode(res.body);
  return VerifyData.fromJson(body as Map<String, dynamic>);
});
