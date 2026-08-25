import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/models/step.dart' as models;
import 'package:sse_frontend_mobil/models/user.dart';
import 'package:sse_frontend_mobil/providers/attachment_provider.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/process_detail_provider.dart';
import 'package:sse_frontend_mobil/providers/users_provider.dart';
import 'package:sse_frontend_mobil/widgets/progress_bar.dart';
import 'package:sse_frontend_mobil/widgets/status_badge.dart';

class ProcessDetailScreen extends ConsumerWidget {
  final String processId;

  const ProcessDetailScreen({super.key, required this.processId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(processDetailProvider(processId));
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
                        child: _StepCard(
                            step: s,
                            isClosed: isClosed,
                            user: user),
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

class _StepCard extends ConsumerWidget {
  final models.Step step;
  final bool isClosed;
  final User? user;

  const _StepCard({required this.step, required this.isClosed, this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = step.record;
    final hasRecord = record != null;
    final isConfirmed = record?.isConfirmed ?? false;
    final isFailed = record?.isFailed ?? false;
    final isAdmin = user?.isAdmin == true;
    final isCoord = user?.isCoordinador == true;
    final canManage = isAdmin || isCoord;
    final canRecord = !isClosed && step.isAssigned && !isConfirmed;

    final attachmentsAsync = ref.watch(
        stepAttachmentsProvider((processId: step.processId, stepId: step.id)));

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

          // Assigned user info
          if (step.isAssigned && step.assignedUsername != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.person_outline_rounded,
                  size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(step.assignedUsername!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF64748B))),
            ]),
          ],

          // Deadline
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

          // Attachments
          attachmentsAsync.when(
            data: (attachments) {
              if (attachments.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  const Icon(Icons.attach_file_rounded,
                      size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                      '${attachments.length} evidencia${attachments.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF2563EB))),
                ]),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Hash
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

          // ── Action buttons (role-aware) ──
          if (!isClosed) ...[
            const SizedBox(height: 12),
            // Admin/Coord: assign + deadline buttons
            if (canManage) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showAssignSheet(context, ref, step.processId, step.id),
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: Text(
                          step.isAssigned ? 'Cambiar operario' : 'Asignar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showDeadlinePicker(context, ref, step.processId, step.id),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(step.deadline != null ? 'Cambiar fecha' : 'Fecha limite'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Operario: record button
            if (canRecord && !canManage) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                      '/process/${step.processId}/step/${step.id}'),
                  icon: Icon(
                      hasRecord ? Icons.refresh_rounded : Icons.edit_rounded,
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

            // Admin/Coord: also show record button if step IS assigned
            if (canManage && canRecord) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                      '/process/${step.processId}/step/${step.id}'),
                  icon: Icon(
                      hasRecord ? Icons.refresh_rounded : Icons.edit_rounded,
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
        ],
      ),
    );
  }

  void _showAssignSheet(
      BuildContext context, WidgetRef ref, String processId, String stepId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AssignOperarioSheet(
          processId: processId, stepId: stepId),
    );
  }

  void _showDeadlinePicker(
      BuildContext context, WidgetRef ref, String processId, String stepId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: step.deadline != null
          ? DateTime.tryParse(step.deadline!) ?? now.add(Duration(days: 15))
          : now.add(Duration(days: 15)),
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      try {
        final api = ref.read(apiClientProvider);
        await api.put('/process/$processId/step/$stepId/deadline',
            body: {'deadline': picked.toUtc().toIso8601String()});
        ref.invalidate(processDetailProvider(processId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Fecha limite actualizada'),
              backgroundColor: Color(0xFF10B981)));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Color(0xFFEF4444)));
        }
      }
    }
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

// ─── Assign Operario Sheet ────────────────────────────────

class _AssignOperarioSheet extends ConsumerStatefulWidget {
  final String processId;
  final String stepId;

  const _AssignOperarioSheet({required this.processId, required this.stepId});

  @override
  ConsumerState<_AssignOperarioSheet> createState() =>
      _AssignOperarioSheetState();
}

class _AssignOperarioSheetState extends ConsumerState<_AssignOperarioSheet> {
  String? _selectedUserId;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final operariosAsync = ref.watch(operariosProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Asignar operario',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          SizedBox(height: 16),
          operariosAsync.when(
            loading: () => Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppTheme.primaryDark))),
            error: (e, _) => Text('Error: $e',
                style: TextStyle(color: Color(0xFFEF4444))),
            data: (operarios) {
              if (operarios.isEmpty) {
                return Text('No hay operarios disponibles',
                    style: TextStyle(color: AppTheme.textLight));
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: InputDecoration(
                    labelText: 'Operario',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                items: operarios
                    .map((o) => DropdownMenuItem(
                        value: o.id,
                        child: Text(o.name,
                            style: TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedUserId = v),
              );
            },
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : _assign,
                  child: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Asignar'),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _assign() async {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selecciona un operario'),
          backgroundColor: Color(0xFFF97316)));
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put(
          '/process/${widget.processId}/step/${widget.stepId}/assign',
          body: {'user_id': _selectedUserId});
      ref.invalidate(processDetailProvider(widget.processId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Operario asignado'),
            backgroundColor: Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
