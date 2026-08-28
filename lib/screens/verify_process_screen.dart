import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/verify_provider.dart';

class VerifyProcessScreen extends ConsumerWidget {
  final String processId;
  final String processName;

  const VerifyProcessScreen(
      {super.key, required this.processId, required this.processName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verifyAsync = ref.watch(processVerifyProvider(processId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Verificar integridad', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(processVerifyProvider(processId)),
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: verifyAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(processVerifyProvider(processId)),
                child: Text('Reintentar'),
              ),
            ]),
          ),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VerifyData data) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // ── Status banner ──
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: data.allOk ? Color(0xFFECFDF5) : Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: data.allOk ? Color(0xFFA7F3D0) : Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                  data.allOk
                      ? Icons.verified_rounded
                      : Icons.gpp_bad_rounded,
                  size: 28,
                  color: data.allOk ? Color(0xFF10B981) : Color(0xFFEF4444),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.allOk
                        ? 'Todos los registros son integros'
                        : 'Se detectaron anomalias',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: data.allOk ? Color(0xFF065F46) : Color(0xFF991B1B)),
                  ),
                ),
              ]),
              SizedBox(height: 6),
              Text(data.processName,
                  style: TextStyle(
                      fontSize: 12,
                      color: data.allOk ? Color(0xFF047857) : Color(0xFF7F1D1D))),
            ],
          ),
        ),
        SizedBox(height: 16),

        // ── Summary stats ──
        _summaryRow(data),
        SizedBox(height: 16),

        // ── Steps ──
        Text('Detalle por registro',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        SizedBox(height: 8),
        if (data.steps.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Center(
              child: Text('No hay registros para verificar',
                  style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
            ),
          )
        else
          ...data.steps.map((s) => Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: _stepVerifyCard(s),
              )),
      ],
    );
  }

  Widget _summaryRow(VerifyData data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _summaryItem(Color(0xFF10B981), '${data.ok}', 'Integros'),
          _summaryDivider(),
          _summaryItem(Color(0xFFF59E0B), '${data.pending}', 'Pendientes'),
          _summaryDivider(),
          _summaryItem(Color(0xFFEF4444), '${data.tampered}', 'Anomalias'),
        ],
      ),
    );
  }

  Widget _summaryItem(Color color, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _summaryDivider() =>
      Container(width: 1, height: 34, color: Color(0xFFE2E8F0));

  Widget _stepVerifyCard(StepVerify s) {
    final (Color color, Color bg, String label) = _statusMeta(s.status);

    return Container(
      padding: EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(children: [
            Icon(s.status == 'ok'
                ? Icons.check_circle_rounded
                : s.status == 'tampered'
                    ? Icons.error_rounded
                    : Icons.hourglass_empty_rounded,
                size: 20,
                color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(s.stepName,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(6)),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
          ]),
          SizedBox(height: 10),
          // Detail message
          Text(s.detail,
              style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          // Hashes
          if (s.dbHash != null) ...[
            SizedBox(height: 8),
            _hashRow('Hash BD', s.dbHash!),
          ],
          if (s.recomputedHash != null) ...[
            SizedBox(height: 4),
            _hashRow('Hash recalculado', s.recomputedHash!),
          ],
          if (s.chainHash != null) ...[
            SizedBox(height: 4),
            _hashRow('Hash blockchain', s.chainHash!, color: Color(0xFF2563EB)),
          ],
          // TX
          if (s.txHash != null) ...[
            SizedBox(height: 8),
            _hashRow('Transaccion', s.txHash!, isTx: true,
                blockNumber: s.blockNumber),
          ],
        ],
      ),
    );
  }

  Widget _hashRow(String label, String value,
      {Color color = const Color(0xFF64748B),
      bool isTx = false,
      String? blockNumber}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 108,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: AppTheme.textLight))),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: color)),
              if (blockNumber != null)
                Text('Bloque #$blockNumber',
                    style:
                        TextStyle(fontSize: 10, color: AppTheme.textLight)),
            ],
          ),
        ),
      ],
    );
  }

  (Color, Color, String) _statusMeta(String status) {
    switch (status) {
      case 'ok':
        return (Color(0xFF10B981), Color(0xFFECFDF5), 'Integro');
      case 'tampered':
        return (Color(0xFFEF4444), Color(0xFFFEF2F2), 'Alterado');
      case 'not_found':
        return (Color(0xFFF59E0B), Color(0xFFFEF3C7), 'No encontrado');
      default:
        return (Color(0xFFF59E0B), Color(0xFFFEF3C7), 'Pendiente');
    }
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      );
}
