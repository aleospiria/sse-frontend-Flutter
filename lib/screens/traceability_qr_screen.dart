import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';

class TraceabilityQrScreen extends StatelessWidget {
  final String processId;
  final String processName;

  const TraceabilityQrScreen({
    super.key,
    required this.processId,
    required this.processName,
  });

  // URL publica del web de verificacion
  String get _publicUrl =>
      'https://sse-sistema.com/verificar?codigo=${Uri.encodeComponent(processName)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Codigo QR de trazabilidad',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              children: [
                Text(processName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark)),
                SizedBox(height: 4),
                Text('Escanee para verificar la trazabilidad',
                    style:
                        TextStyle(fontSize: 12, color: AppTheme.textLight)),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: QrImageView(
                    data: _publicUrl,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1E293B),
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1E293B),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Apunta a: $_publicUrl',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppTheme.textLight),
                ),
                SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: _publicUrl)),
                      icon: Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copiar link'),
                    ),
                  ),
                ]),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ── View inside app ──
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.phone_android_rounded,
                      size: 20, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Ver trazabilidad sin login',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                  ),
                ]),
                SizedBox(height: 4),
                Text(
                  'Tambien puede consultar este proceso directamente desde la aplicacion, sin necesidad de iniciar sesion.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                        '/public/traceability/${Uri.encodeComponent(processName)}'),
                    icon: Icon(Icons.visibility_rounded, size: 18),
                    label: Text('Ver trazabilidad en la app'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
