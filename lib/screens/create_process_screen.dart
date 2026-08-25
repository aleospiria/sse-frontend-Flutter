import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/create_process_provider.dart';

class CreateProcessScreen extends ConsumerStatefulWidget {
  const CreateProcessScreen({super.key});

  @override
  ConsumerState<CreateProcessScreen> createState() =>
      _CreateProcessScreenState();
}

class _CreateProcessScreenState extends ConsumerState<CreateProcessScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  String? _selectedTemplateId;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _manualStepControllers = <_ManualStep>[];
  bool _loading = false;
  bool _useTemplate = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final s in _manualStepControllers) {
      s.name.dispose();
      s.desc.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final templatesAsync = ref.watch(templatesProvider);

    // Auto-fill name when template selected and nextCode loads
    if (_selectedTemplateId != null && _useTemplate) {
      final tmpl = ref.watch(templatesProvider).maybeWhen(
          data: (list) => list.where((t) => t['id'] == _selectedTemplateId).firstOrNull,
          orElse: () => null);
      final code = tmpl?['code'] as String? ?? '';
      if (code.isNotEmpty) {
        final nextAsync = ref.watch(nextCodeProvider(code));
        nextAsync.whenData((data) {
          if (data != null && _nameController.text.isEmpty) {
            _nameController.text = data['name'] as String;
          }
        });
      }
    }

    const labelStyle = TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B));

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear proceso', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // ── Client ──
            Text('Cliente / Empresa', style: labelStyle),
            SizedBox(height: 8),
            clientsAsync.when(
              loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryDark)),
              error: (e, _) => Text('Error cargando clientes: $e',
                  style: TextStyle(color: Color(0xFFEF4444))),
              data: (clients) => DropdownButtonFormField<String>(
                initialValue: _selectedClientId,
                decoration: InputDecoration(
                    labelText: 'Seleccionar cliente',
                    prefixIcon: Icon(Icons.business_rounded, size: 20)),
                items: clients
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClientId = v),
                validator: (v) => v == null ? 'Selecciona un cliente' : null,
              ),
            ),
            SizedBox(height: 24),

            // ── Template toggle ──
            Text('Metodo', style: labelStyle),
            SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text('Plantilla')),
                ButtonSegment(value: false, label: Text('Personalizado')),
              ],
              selected: {_useTemplate},
              onSelectionChanged: (s) => setState(() {
                _useTemplate = s.first;
                if (!_useTemplate) {
                  _selectedTemplateId = null;
                  _nameController.clear();
                }
              }),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.primaryDark,
                selectedForegroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // ── Template picker ──
            if (_useTemplate)
              templatesAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: AppTheme.primaryDark)),
                error: (e, _) => Text('Error: $e', style: TextStyle(color: Color(0xFFEF4444))),
                data: (templates) {
                  if (templates.isEmpty) {
                    return Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFFDE68A))),
                      child: Text('No hay plantillas disponibles.\nUsa modo personalizado.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E))),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedTemplateId,
                    decoration: InputDecoration(
                        labelText: 'Plantilla',
                        prefixIcon: Icon(Icons.description_outlined, size: 20)),
                    items: templates
                        .map((t) => DropdownMenuItem(
                            value: t['id'] as String,
                            child: Text('${t['name']} (${t['total_steps'] ?? '?'} pasos)',
                                style: TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedTemplateId = v;
                        _nameController.clear();
                      });
                    },
                    validator: (v) =>
                        _useTemplate && v == null ? 'Selecciona una plantilla' : null,
                  );
                },
              ),

            // ── Process name ──
            SizedBox(height: 20),
            Text('Nombre del proceso', style: labelStyle),
            SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: _useTemplate && _selectedTemplateId != null
                      ? 'Generado automaticamente'
                      : 'Ej: TMB-2026-001',
                  prefixIcon: Icon(Icons.tag_rounded, size: 20)),
              readOnly: _useTemplate && _selectedTemplateId != null,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            SizedBox(height: 20),

            // ── Description ──
            Text('Descripcion (opcional)', style: labelStyle),
            SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: 'Descripcion del proceso',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.notes_rounded, size: 20))),
            ),

            // ── Inline steps (manual mode only) ──
            if (!_useTemplate) ...[
              SizedBox(height: 24),
              Row(
                children: [
                  Text('Etapas', style: labelStyle),
                  Spacer(),
                  TextButton.icon(
                    onPressed: _addStep,
                    icon: Icon(Icons.add_rounded, size: 18),
                    label: Text('Agregar'),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_manualStepControllers.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE2E8F0))),
                  child: Text('Agrega al menos una etapa',
                      style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
                ),
              ..._manualStepControllers.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE2E8F0))),
                  child: Column(
                    children: [
                      Row(children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: AppTheme.primaryDark.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Center(
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark))),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: s.name,
                            decoration: InputDecoration(
                                labelText: 'Nombre de la etapa',
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeStep(i),
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20, color: Color(0xFFEF4444)),
                        ),
                      ]),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: s.desc,
                        decoration: InputDecoration(
                            labelText: 'Descripcion (opcional)',
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                      ),
                    ],
                  ),
                );
              }),
            ],

            // ── Submit ──
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Crear proceso',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _addStep() {
    setState(() => _manualStepControllers.add(_ManualStep()));
  }

  void _removeStep(int i) {
    setState(() {
      _manualStepControllers[i].name.dispose();
      _manualStepControllers[i].desc.dispose();
      _manualStepControllers.removeAt(i);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_useTemplate && _selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Selecciona una plantilla'),
          backgroundColor: Color(0xFFF97316)));
      return;
    }
    if (!_useTemplate && _manualStepControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Agrega al menos una etapa'),
          backgroundColor: Color(0xFFF97316)));
      return;
    }

    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);

      // Resolve client name from selected ID
      final clients = ref.read(clientsProvider).valueOrNull ?? [];
      final clientName = clients
          .where((c) => c.id == _selectedClientId)
          .map((c) => c.name)
          .firstOrNull;

      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'client_name': clientName ?? _selectedClientId,
      };
      if (_descController.text.trim().isNotEmpty) {
        body['description'] = _descController.text.trim();
      }
      if (_useTemplate && _selectedTemplateId != null) {
        body['template_id'] = _selectedTemplateId;
      }
      if (!_useTemplate) {
        body['steps'] = _manualStepControllers.asMap().entries.map((e) {
          return <String, dynamic>{
            'name': e.value.name.text.trim(),
            if (e.value.desc.text.trim().isNotEmpty)
              'description': e.value.desc.text.trim(),
            'order_index': e.key + 1,
          };
        }).toList();
      }

      await api.post('/process', body: body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Proceso creado'),
            backgroundColor: Color(0xFF10B981)));
        context.go('/home');
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

class _ManualStep {
  final name = TextEditingController();
  final desc = TextEditingController();
}
