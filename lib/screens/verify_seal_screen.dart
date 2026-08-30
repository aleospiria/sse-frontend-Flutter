import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/seal_verify_provider.dart';

const _polygonscan = 'https://amoy.polygonscan.com/tx';

class VerifySealScreen extends ConsumerWidget {
  final String processId;
  final String processName;

  const VerifySealScreen(
      {super.key, required this.processId, required this.processName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sealAsync = ref.watch(processSealVerifyProvider(processId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Verificar sello', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(processSealVerifyProvider(processId)),
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: sealAsync.when(
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
                    ref.invalidate(processSealVerifyProvider(processId)),
                child: Text('Reintentar'),
              ),
            ]),
          ),
        ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SealVerifyData data) {
    // ── No sealed ──
    if (!data.sealed) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.radio_button_unchecked_rounded,
                  size: 64, color: Color(0xFFCBD5E1)),
              SizedBox(height: 16),
              Text('El proceso no esta sellado aun',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              SizedBox(height: 4),
              Text(data.detail.isEmpty
                  ? 'Completa todas las etapas para sellarlo'
                  : data.detail,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textLight)),
            ],
          ),
        ),
      );
    }

    final intact = data.intact ?? false;
    final allGood = intact && data.dbMatchRecomputed == true;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // ── Status banner ──
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: allGood ? Color(0xFFECFDF5) : Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: allGood ? Color(0xFFA7F3D0) : Color(0xFFFECACA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(
                    allGood
                        ? Icons.verified_rounded
                        : Icons.gpp_bad_rounded,
                    size: 28,
                    color:
                        allGood ? Color(0xFF10B981) : Color(0xFFEF4444)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    allGood ? 'Sello verificado e integro' : 'Sello comprometido',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            allGood ? Color(0xFF065F46) : Color(0xFF991B1B)),
                  ),
                ),
              ]),
              SizedBox(height: 6),
              Text(processName,
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          allGood ? Color(0xFF047857) : Color(0xFF7F1D1D))),
            ],
          ),
        ),
        SizedBox(height: 16),

        // ── Checks ──
        _checkRow('Hash BD == hash recalculado', data.dbMatchRecomputed),
        _checkRow('Hash BD == hash en blockchain', data.dbMatchChain),
        _checkRow('Hash recalculado == blockchain', data.recomputedMatchChain),
        _checkRow('Sello integro (intact)', data.intact),
        SizedBox(height: 16),

        // ── Block info ──
        if (data.closeTxHash != null) ...[
          _infoCard(
            icon: Icons.block_rounded,
            title: 'Transaccion blockchain',
            value: data.closeTxHash!,
            isTx: true,
            blockNumber: data.closeBlock,
          ),
          SizedBox(height: 12),
        ],

        // ── Hashes ──
        if (data.dbProcessHash != null) ...[
          _infoCard(
              icon: Icons.storage_rounded,
              title: 'Hash global (BD)',
              value: data.dbProcessHash!),
          SizedBox(height: 12),
        ],
        if (data.recomputedProcessHash != null) ...[
          _infoCard(
              icon: Icons.calculate_rounded,
              title: 'Hash recalculado',
              value: data.recomputedProcessHash!),
          SizedBox(height: 12),
        ],
        if (data.chainProcessHash != null) ...[
          _infoCard(
              icon: Icons.link_rounded,
              title: 'Hash en blockchain',
              value: data.chainProcessHash!),
          SizedBox(height: 12),
        ],

        // ── Steps count ──
        if (data.totalStepsInDb != null || data.chainTotalSteps != null) ...[
          _infoCard(
              icon: Icons.list_alt_rounded,
              title: 'Etapas',
              value:
                  '${data.totalStepsInDb ?? '?'} en BD · ${data.chainTotalSteps ?? '?'} en blockchain'),
        ],
        SizedBox(height: 24),

        // ── Polygon link ──
        if (data.closeTxHash != null)
          InkWell(
            onTap: () async {
              final url = Uri.parse('$_polygonscan/${data.closeTxHash}');
              await launchUrl(url);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFBFDBFE)),
              ),
              child: Row(children: [
                Icon(Icons.open_in_new_rounded,
                    size: 18, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Ver en Polygonscan (Amoy)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB))),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _checkRow(String label, bool? ok) {
    final (Color color, IconData icon) = ok == null
        ? (Color(0xFF94A3B8), Icons.remove_circle_outline_rounded)
        : ok
            ? (Color(0xFF10B981), Icons.check_circle_rounded)
            : (Color(0xFFEF4444), Icons.cancel_rounded);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark)),
        ),
      ]),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    bool isTx = false,
    String? blockNumber,
  }) {
    final valueColor = isTx ? Color(0xFF2563EB) : Color(0xFF64748B);
    return Container(
      padding: EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: AppTheme.textLight),
            SizedBox(width: 6),
            Text(title,
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ]),
          SizedBox(height: 8),
          SelectableText(value,
              style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: valueColor)),
          if (blockNumber != null)
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Bloque #$blockNumber',
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ),
        ],
      ),
    );
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
