import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/models/step.dart' as models;
import 'package:sse_frontend_mobil/providers/process_detail_provider.dart';
import 'package:sse_frontend_mobil/widgets/progress_bar.dart';
import 'package:sse_frontend_mobil/widgets/status_badge.dart';

class ProcessDetailScreen extends ConsumerWidget {
  final String processId;

  const ProcessDetailScreen({super.key, required this.processId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(processDetailProvider(processId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Detalle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E293B)),
        ),
        error: (e, _) => _buildError(ref, e),
        data: (detail) {
          final process = detail.process;
          final steps = detail.steps;
          final status = process['status'] as String? ?? 'active';
          final isClosed = status == 'closed' || process['closed_at'] != null;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(processDetailProvider(processId)),
            color: const Color(0xFF1E293B),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(process, steps),
                if (isClosed) ...[
                  const SizedBox(height: 12),
                  _buildSealedBanner(process),
                ],
                const SizedBox(height: 20),
                _buildStepsHeader(steps.length),
                const SizedBox(height: 12),
                if (steps.isEmpty)
                  _buildEmptySteps()
                else
                  ...steps.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StepCard(step: s, isClosed: isClosed),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(WidgetRef ref, Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const Text('Error al cargar',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.invalidate(processDetailProvider(processId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> process, List<models.Step> steps) {
    final confirmed =
        steps.where((s) => s.record?.isConfirmed ?? false).length;
    final name = process['name'] as String? ?? '';
    final desc = process['description'] as String?;
    final client = process['client_name'] as String?;
    final industry = process['industry'] as String?;
    final status = process['status'] as String? ?? 'active';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
            ),
            StatusBadge.process(status),
          ]),
          if (desc != null && desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(desc,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (client != null) _chip(Icons.business_rounded, client),
            if (industry != null) _chip(Icons.category_rounded, industry),
          ]),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            ProgressBar(completed: confirmed, total: steps.length),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ]),
    );
  }

  Widget _buildSealedBanner(Map<String, dynamic> process) {
    final txHash = process['close_tx_hash'] as String?;
    final closedBy = process['closed_by_username'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.verified_rounded,
            size: 24, color: Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Proceso sellado en blockchain',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C3AED))),
                if (closedBy != null)
                  Text('Sellado por $closedBy',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                if (txHash != null) ...[
                  const SizedBox(height: 4),
                  Text('TX: ${txHash.substring(0, 16)}...',
                      style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF94A3B8))),
                ],
              ]),
        ),
      ]),
    );
  }

  Widget _buildStepsHeader(int count) {
    return Row(children: [
      const Text('Etapas',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B))),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(10)),
        child: Text('$count',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
      ),
    ]);
  }

  Widget _buildEmptySteps() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text('Este proceso no tiene etapas',
            style: TextStyle(color: Color(0xFF94A3B8))),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final models.Step step;
  final bool isClosed;

  const _StepCard({required this.step, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final record = step.record;
    final hasRecord = record != null;
    final isConfirmed = record?.isConfirmed ?? false;
    final isFailed = record?.isFailed ?? false;
    final canRecord = !isClosed && step.isAssigned && !isConfirmed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _number(step.orderIndex, isConfirmed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B))),
                    if (step.description != null &&
                        step.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(step.description!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
            ),
            if (hasRecord) _recordBadge(record.status.name),
          ]),
          if (step.isAssigned && step.assignedUsername != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(step.assignedUsername!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B))),
            ]),
          ],
          if (step.deadline != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.schedule_rounded,
                  size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('Limite: ${step.deadline!.substring(0, 10)}',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFF59E0B))),
            ]),
          ],
          if (hasRecord && record.dataHash != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 12, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                      'Hash: ${record.dataHash!.substring(0, 20)}...',
                      style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Color(0xFF94A3B8))),
                ),
              ]),
            ),
          ],
          if (canRecord) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(
                    '/process/${step.processId}/step/${step.id}'),
                icon: Icon(
                    hasRecord
                        ? Icons.refresh_rounded
                        : Icons.edit_rounded,
                    size: 16),
                label:
                    Text(hasRecord ? 'Re-registrar' : 'Registrar etapa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFailed
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFF97316),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _number(int order, bool confirmed) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: confirmed
            ? const Color(0xFF16A34A).withValues(alpha: 0.1)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: confirmed
            ? const Icon(Icons.check_rounded,
                size: 18, color: Color(0xFF16A34A))
            : Text('$order',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B))),
      ),
    );
  }

  Widget _recordBadge(String status) {
    return StatusBadge.record(status);
  }
}
