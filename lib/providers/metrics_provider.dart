import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

class MetricsData {
  final Totals totals;
  final List<IndustryMetric> byIndustry;
  final List<StatusMetric> byStatus;
  final List<MonthMetric> byMonth;
  final List<ClientMetric> topClients;
  final List<CompletionRate> completionRate;

  MetricsData({
    required this.totals,
    required this.byIndustry,
    required this.byStatus,
    required this.byMonth,
    required this.topClients,
    required this.completionRate,
  });

  factory MetricsData.fromJson(Map<String, dynamic> j) => MetricsData(
        totals: Totals.fromJson(j['totals']),
        byIndustry: (j['by_industry'] as List)
            .map((e) => IndustryMetric.fromJson(e))
            .toList(),
        byStatus: (j['by_status'] as List)
            .map((e) => StatusMetric.fromJson(e))
            .toList(),
        byMonth: (j['by_month'] as List)
            .map((e) => MonthMetric.fromJson(e))
            .toList(),
        topClients: (j['top_clients'] as List)
            .map((e) => ClientMetric.fromJson(e))
            .toList(),
        completionRate: (j['completion_rate'] as List)
            .map((e) => CompletionRate.fromJson(e))
            .toList(),
      );
}

class Totals {
  final int processes;
  final int open;
  final int closed;
  final int confirmedSteps;
  final int pendingSteps;
  final int txBlockchain;
  final int users;
  final int overdueSteps;

  Totals({
    required this.processes,
    required this.open,
    required this.closed,
    required this.confirmedSteps,
    required this.pendingSteps,
    required this.txBlockchain,
    required this.users,
    required this.overdueSteps,
  });

  factory Totals.fromJson(Map<String, dynamic> j) => Totals(
        processes: j['processes'] ?? 0,
        open: j['open'] ?? 0,
        closed: j['closed'] ?? 0,
        confirmedSteps: j['confirmed_steps'] ?? 0,
        pendingSteps: j['pending_steps'] ?? 0,
        txBlockchain: j['tx_blockchain'] ?? 0,
        users: j['users'] ?? 0,
        overdueSteps: j['overdue_steps'] ?? 0,
      );
}

class IndustryMetric {
  final String industry;
  final int total;
  final int closed;
  final int confirmedSteps;

  IndustryMetric(
      {required this.industry,
      required this.total,
      required this.closed,
      required this.confirmedSteps});

  factory IndustryMetric.fromJson(Map<String, dynamic> j) => IndustryMetric(
        industry: j['industry'] ?? 'Sin industria',
        total: j['total'] ?? 0,
        closed: j['closed'] ?? 0,
        confirmedSteps: j['confirmed_steps'] ?? 0,
      );
}

class StatusMetric {
  final String status;
  final int count;

  StatusMetric({required this.status, required this.count});

  factory StatusMetric.fromJson(Map<String, dynamic> j) =>
      StatusMetric(status: j['status'] ?? '', count: j['count'] ?? 0);
}

class MonthMetric {
  final String month;
  final int created;
  final int closed;

  MonthMetric(
      {required this.month, required this.created, required this.closed});

  factory MonthMetric.fromJson(Map<String, dynamic> j) => MonthMetric(
        month: j['month'] ?? '',
        created: j['created'] ?? 0,
        closed: j['closed'] ?? 0,
      );
}

class ClientMetric {
  final String clientName;
  final int total;
  final int closed;

  ClientMetric(
      {required this.clientName, required this.total, required this.closed});

  factory ClientMetric.fromJson(Map<String, dynamic> j) => ClientMetric(
        clientName: j['client_name'] ?? 'Sin cliente',
        total: j['total'] ?? 0,
        closed: j['closed'] ?? 0,
      );
}

class CompletionRate {
  final String label;
  final int value;

  CompletionRate({required this.label, required this.value});

  factory CompletionRate.fromJson(Map<String, dynamic> j) =>
      CompletionRate(label: j['label'] ?? '', value: j['value'] ?? 0);
}

final metricsProvider = FutureProvider<MetricsData>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/metrics');
  final body = jsonDecode(res.body);
  return MetricsData.fromJson(body as Map<String, dynamic>);
});
