import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/models/public_process.dart';
import 'package:sse_frontend_mobil/providers/public_process_provider.dart';
import 'package:sse_frontend_mobil/widgets/empty_state.dart';
import 'package:sse_frontend_mobil/widgets/skeleton.dart';

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
        loading: () => const _PublicTraceabilitySkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.search_off_rounded,
          title: 'No se encontro el proceso "$code"',
          message: '$e',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(publicTraceabilityProvider(code)),
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

        SizedBox(height: 12),

        // ── Public traceability explainer banner ──
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFBAE6FD)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 20, color: Color(0xFF0369A1)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cada etapa muestra aquí los resultados registrados y su '
                  'evidencia. Esta certificación nunca incluye datos '
                  'personales: protegemos siempre la identidad de las '
                  'personas involucradas.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF0C4A6E)),
                ),
              ),
            ],
          ),
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
                Row(children: [
                  Icon(Icons.verified_user_outlined,
                      size: 16, color: Color(0xFF0369A1)),
                  SizedBox(width: 6),
                  Text('Forensic digital del proceso',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0C4A6E))),
                ]),
                SizedBox(height: 4),
                Text(
                  'Todo el historial quedó sellado e inmutable en blockchain. '
                  'Esta huella global certifica que ninguna etapa fue alterada.',
                  style: TextStyle(
                      fontSize: 11, height: 1.35, color: Color(0xFF475569)),
                ),
                SizedBox(height: 8),
                SelectableText(p.processHash!,
                    style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Color(0xFF475569))),
                if (p.closeTxHash != null && p.closeBlock != null) ...[
                  SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(
                          'https://amoy.polygonscan.com/tx/${p.closeTxHash}');
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 14, color: Color(0xFF0369A1)),
                      SizedBox(width: 4),
                      Text('Ver transacción · bloque #${p.closeBlock}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0369A1))),
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
          // ── Header: number + name + status ──
          Row(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: confirmed ? Color(0xFF10B981) : Color(0xFFE2E8F0),
              ),
              child: Text('${step.orderIndex + 1}',
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

          // ── Resultados (real recorded data) ──
          if (step.results.isNotEmpty) ...[
            SizedBox(height: 10),
            Text('Resultados',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155))),
            SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < step.results.length; i++)
                    _resultRow(step.results[i], i.isOdd),
                ],
              ),
            ),
          ],

          // ── Nota de privacidad ──
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 13, color: Color(0xFF94A3B8)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Esta información nunca incluye datos personales — '
                  'protegemos siempre la identidad de las personas '
                  'involucradas.',
                  style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),

          // ── Evidencia digital (attachments) ──
          if (step.attachments.isNotEmpty) ...[
            SizedBox(height: 8),
            Text('Evidencia digital',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155))),
            SizedBox(height: 6),
            for (final att in step.attachments) _attachmentTile(att),
          ],

          // ── Blockchain proof (secondary) ──
          if (step.dataHash != null || step.txHash != null) ...[
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: confirmed ? Color(0xFFEFF6FF) : Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: confirmed
                          ? Color(0xFFBFDBFE)
                          : Color(0xFFFED7AA))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          confirmed
                              ? Icons.verified_rounded
                              : Icons.schedule_rounded,
                          size: 15,
                          color: confirmed
                              ? Color(0xFF0369A1)
                              : Color(0xFFEA580C)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          confirmed
                              ? 'Etapa certificada en blockchain'
                              : 'Etapa registrada, confirmando en blockchain...',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: confirmed
                                  ? Color(0xFF0C4A6E)
                                  : Color(0xFF9A3412)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Los resultados y la evidencia de arriba quedaron '
                    'sellados e inmutables. Nadie puede alterarlos.',
                    style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: Color(0xFF475569)),
                  ),
                  if (step.dataHash != null) ...[
                    SizedBox(height: 8),
                    Text('Huella digital (hash):',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B))),
                    SizedBox(height: 2),
                    SelectableText('SHA-256 ${step.dataHash}',
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Color(0xFF475569))),
                  ],
                  if (step.txHash != null) ...[
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse(
                            'https://amoy.polygonscan.com/tx/${step.txHash}');
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.open_in_new_rounded,
                            size: 13, color: Color(0xFF0369A1)),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Ver transacción en Polygonscan'
                            '${step.blockNumber != null ? ' · bloque #${step.blockNumber}' : ''}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0369A1)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(PublicResult r, bool shaded) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: shaded ? Color(0xFFF1F5F9) : Colors.transparent,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(r.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569))),
          ),
          SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(_formatValue(r),
                style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  String _formatValue(PublicResult r) {
    final v = r.value;
    if (v == null || v == '') return '—';
    if (v is bool) return v ? 'Sí' : 'No';
    return v.toString();
  }

  Widget _attachmentTile(PublicAttachment att) {
    final fileName = att.originalName ?? att.id ?? 'Adjunto';
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () async {
          final url = att.url;
          if (url == null) return;
          await launchUrl(Uri.parse(url),
              mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(6),
        child: Row(children: [
          Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF0369A1)),
          SizedBox(width: 6),
          Expanded(
            child: Text(fileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0369A1))),
          ),
          Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFF94A3B8)),
        ]),
      ),
    );
  }
}

/// Esqueleto de carga de la trazabilidad pública: header, etapas y sello.
class _PublicTraceabilitySkeleton extends StatelessWidget {
  const _PublicTraceabilitySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 200, height: 16, radius: 6),
              const SizedBox(height: 8),
              const SkeletonBox(width: 140, height: 12, radius: 6),
              const SizedBox(height: 20),
              Row(children: [
                const SkeletonBox(width: 24, height: 24, radius: 12),
                const SizedBox(width: 10),
                const Expanded(child: SkeletonBox(height: 15, radius: 6)),
                const SizedBox(width: 10),
                const SkeletonBox(width: 20, height: 20, radius: 6),
              ]),
              const SizedBox(height: 14),
              const SkeletonBox(height: 46, radius: 8),
              const SizedBox(height: 12),
              const SkeletonBox(height: 46, radius: 8),
              const SizedBox(height: 12),
              const SkeletonBox(height: 46, radius: 8),
              const SizedBox(height: 12),
              const SkeletonBox(height: 46, radius: 8),
              const SizedBox(height: 20),
              const SkeletonBox(width: 160, height: 14, radius: 6),
              const SizedBox(height: 10),
              const SkeletonBox(height: 76, radius: 10),
            ],
          ),
        ),
      ],
    );
  }
}
