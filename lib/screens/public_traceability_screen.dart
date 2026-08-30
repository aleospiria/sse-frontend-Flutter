import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/models/public_process.dart';
import 'package:sse_frontend_mobil/providers/public_process_provider.dart';

class PublicTraceabilityScreen extends ConsumerWidget {
  final String code;

  const PublicTraceabilityScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(publicTraceabilityProvider(code));

    return Scaffold(
      appBar: AppBar(
        title: Text('Trazabilidad publica',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: dataAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              SizedBox(height: 12),
              Text('No se encontro el proceso "$code"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.textDark)),
              SizedBox(height: 4),
              Text('$e',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(publicTraceabilityProvider(code)),
                child: Text('Reintentar'),
              ),
            ]),
          ),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PublicProcessData data) {
    final p = data.process;
    final sealed = p.isSealed;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // ── Process header card ──
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.fact_check_outlined,
                    size: 20, color: AppTheme.primaryDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(p.name,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark)),
                ),
              ]),
              if (p.description != null && p.description!.isNotEmpty) ...[
                SizedBox(height: 6),
                Text(p.description!,
                    style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
              ],
              SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _chip('Estatus: ${p.status ?? '—'}',
                    sealed ? Color(0xFF10B981) : Color(0xFFF59E0B)),
                if (p.industry != null)
                  _chip('Industria: ${p.industry}', Color(0xFF64748B)),
              ]),
            ],
          ),
        ),

        // ── Seal banner ──
        Container(
          margin: EdgeInsets.only(top: 12),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sealed ? Color(0xFFECFDF5) : Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sealed ? Color(0xFFA7F3D0) : Color(0xFFFDE68A)),
          ),
          child: Row(children: [
            Icon(sealed ? Icons.verified_rounded : Icons.auto_mode_rounded,
                size: 20,
                color: sealed ? Color(0xFF10B981) : Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  sealed
                      ? 'Proceso sellado e inmutable en blockchain'
                      : 'Proceso en curso (no sellado aun)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sealed
                          ? Color(0xFF065F46)
                          : Color(0xFF92400E))),
            ),
          ]),
        ),

        SizedBox(height: 16),
        Text('Etapas del proceso',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        SizedBox(height: 8),

        if (data.steps.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('Sin etapas registradas',
                  style: TextStyle(color: AppTheme.textLight)),
            ),
          ),

        for (var i = 0; i < data.steps.length; i++) ...[
          _stepCard(data.steps[i], data.steps.length, sealed),
          SizedBox(height: 8),
        ],

        // ── Seal hash (public) ──
        if (p.processHash != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hash global del sello',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight)),
                SizedBox(height: 4),
                SelectableText(p.processHash!,
                    style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFF64748B))),
                if (p.closeTxHash != null && p.closeBlock != null) ...[
                  SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                          'https://amoy.polygonscan.com/tx/${p.closeTxHash}');
                      await launchUrl(url);
                    },
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Text('Bloque #${p.closeBlock} en Polygonscan',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB))),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      );

  Widget _stepCard(PublicStep step, int total, bool sealed) {
    final confirmed = step.isConfirmed;
    final Color statusColor =
        confirmed ? Color(0xFF10B981) : Color(0xFFF59E0B);
    final IconData statusIcon = confirmed
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: confirmed ? Color(0xFF10B981) : Color(0xFFE2E8F0),
              ),
              child: Text('${step.orderIndex}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: confirmed ? Colors.white : Color(0xFF64748B))),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(step.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ),
            Icon(statusIcon, size: 18, color: statusColor),
          ]),
          if (step.description != null && step.description!.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(step.description!,
                style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ],
          if (step.recordedByName != null) ...[
            SizedBox(height: 6),
            Text('Registrado por: ${step.recordedByName}',
                style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ],
          if (step.dataHash != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: confirmed ? Color(0xFFEFF6FF) : Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                        confirmed
                            ? Icons.verified_rounded
                            : Icons.lock_outline_rounded,
                        size: 13,
                        color: confirmed
                            ? Color(0xFF2563EB)
                            : Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                          'SHA-256: ${step.dataHash!.substring(0, 18)}...',
                          style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Color(0xFF64748B))),
                    ),
                  ]),
                  if (step.txHash != null) ...[
                    SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.link_rounded,
                          size: 13, color: Color(0xFF2563EB)),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'TX: ${step.txHash!.substring(0, 12)}...',
                          style: TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Color(0xFF2563EB))),
                      ),
                      if (step.blockNumber != null)
                        Text('Blk #${step.blockNumber}',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF64748B))),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
