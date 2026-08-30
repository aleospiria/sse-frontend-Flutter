import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class SealVerifyData {
  final bool sealed;
  final bool? intact;
  final String? dbProcessHash;
  final String? recomputedProcessHash;
  final String? chainProcessHash;
  final String? closeTxHash;
  final String? closeBlock;
  final String? closedAt;
  final bool? dbMatchRecomputed;
  final bool? dbMatchChain;
  final bool? recomputedMatchChain;
  final String? totalStepsInDb;
  final String? chainTotalSteps;
  final String detail;

  SealVerifyData({
    required this.sealed,
    required this.detail,
    this.intact,
    this.dbProcessHash,
    this.recomputedProcessHash,
    this.chainProcessHash,
    this.closeTxHash,
    this.closeBlock,
    this.closedAt,
    this.dbMatchRecomputed,
    this.dbMatchChain,
    this.recomputedMatchChain,
    this.totalStepsInDb,
    this.chainTotalSteps,
  });

  factory SealVerifyData.fromJson(Map<String, dynamic> j) => SealVerifyData(
        sealed: j['sealed'] ?? false,
        intact: j['intact'] as bool?,
        dbProcessHash: j['dbProcessHash'] as String?,
        recomputedProcessHash: j['recomputedProcessHash'] as String?,
        chainProcessHash: j['chainProcessHash'] as String?,
        closeTxHash: j['closeTxHash'] as String?,
        closeBlock: j['closeBlock']?.toString(),
        closedAt: j['closedAt'] as String?,
        dbMatchRecomputed: j['dbMatchRecomputed'] as bool?,
        dbMatchChain: j['dbMatchChain'] as bool?,
        recomputedMatchChain: j['recomputedMatchChain'] as bool?,
        totalStepsInDb: j['totalStepsInDb']?.toString(),
        chainTotalSteps: j['chainTotalSteps']?.toString(),
        detail: j['detail'] ?? '',
      );
}

final processSealVerifyProvider =
    FutureProvider.family<SealVerifyData, String>((ref, processId) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/process/$processId/verify-seal');
  final body = jsonDecode(res.body);
  return SealVerifyData.fromJson(body as Map<String, dynamic>);
});
