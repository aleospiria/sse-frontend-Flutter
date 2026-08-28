import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/config/app_theme.dart';
import 'package:sse_frontend_mobil/providers/templates_provider.dart';

class ManageTemplatesScreen extends ConsumerStatefulWidget {
  const ManageTemplatesScreen({super.key});

  @override
  ConsumerState<ManageTemplatesScreen> createState() =>
      _ManageTemplatesScreenState();
}

class _ManageTemplatesScreenState
    extends ConsumerState<ManageTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(templatesListProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(templatesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Plantillas', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => ref.read(templatesListProvider.notifier).refresh(),
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: templatesAsync.when(
        loading: () => Center(
            child: CircularProgressIndicator(color: AppTheme.primaryDark)),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444)),
            SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(templatesListProvider.notifier).refresh(),
              child: Text('Reintentar'),
            ),
          ]),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.description_outlined,
                    size: 64, color: Color(0xFFCBD5E1)),
                SizedBox(height: 12),
                Text('No hay plantillas',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                SizedBox(height: 4),
                Text('Crea la primera desde el boton +',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textLight)),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(templatesListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (_, i) => _TemplateCard(
                template: templates[i],
                onTap: () => _openDetail(templates[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreate(),
        backgroundColor: AppTheme.primaryDark,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _openDetail(TemplateItem t) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _TemplateDetailScreen(template: t)),
    );
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _TemplateFormScreen()),
    );
  }
}

// ─── Template Card ────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final TemplateItem template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFFF97316).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                    template.code ?? template.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF97316))),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  SizedBox(height: 2),
                  Row(children: [
                    if (template.industry != null) ...[
                      Icon(Icons.factory_rounded,
                          size: 12, color: AppTheme.textLight),
                      SizedBox(width: 3),
                      Text(template.industry!,
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textLight)),
                      SizedBox(width: 10),
                    ],
                    Icon(Icons.list_alt_rounded,
                        size: 12, color: AppTheme.textLight),
                    SizedBox(width: 3),
                    Text('${template.totalSteps} pasos',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ─── Template Detail Screen ────────────────────────────────

class _TemplateDetailScreen extends ConsumerWidget {
  final TemplateItem template;
  const _TemplateDetailScreen({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(template.name, style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            onPressed: () => _openEdit(context, ref),
            icon: Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: FutureBuilder<TemplateDetail?>(
        future: ref.read(templatesListProvider.notifier).getDetail(template.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryDark));
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Error al cargar detalle'));
          }
          final detail = snap.data!;
          final steps = detail.steps;
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Header info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.description_outlined,
                          size: 20, color: Color(0xFFF97316)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(template.name,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark)),
                      ),
                    ]),
                    if (template.description != null &&
                        template.description!.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Text(template.description!,
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textLight)),
                    ],
                    SizedBox(height: 8),
                    Row(children: [
                      if (template.code != null) ...[
                        _tag(template.code!, Color(0xFFF97316)),
                        SizedBox(width: 8),
                      ],
                      if (template.industry != null)
                        _tag(template.industry!, Color(0xFF2563EB)),
                    ]),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Steps
              Text('${steps.length} etapas',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark)),
              SizedBox(height: 8),
              ...steps.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final fields = (s['field_schema'] as List?) ?? [];
                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryDark))),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(s['name'] ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark)),
                        ),
                      ]),
                      if (s['description'] != null &&
                          (s['description'] as String).isNotEmpty) ...[
                        SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.only(left: 32),
                          child: Text(s['description'],
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textLight)),
                        ),
                      ],
                      if (fields.isNotEmpty) ...[
                        SizedBox(height: 8),
                        ...fields.map((f) => Padding(
                              padding:
                                  EdgeInsets.only(left: 32, bottom: 3),
                              child: Row(
                                children: [
                                  Icon(_fieldIcon(f['type']),
                                      size: 13,
                                      color: AppTheme.textLight),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                        f['label'] ?? f['name'] ?? '',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textDark)),
                                  ),
                                  if (f['required'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                          color: Color(0xFFFEF2F2),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: Text('req',
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEF4444))),
                                    ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  IconData _fieldIcon(String? type) {
    switch (type) {
      case 'numero':
        return Icons.numbers_rounded;
      case 'fecha':
        return Icons.calendar_today_rounded;
      case 'hora':
        return Icons.access_time_rounded;
      case 'seleccion':
        return Icons.arrow_drop_down_circle_outlined;
      case 'booleano':
        return Icons.toggle_on_rounded;
      case 'parrafo':
        return Icons.notes_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }

  void _openEdit(BuildContext context, WidgetRef ref) async {
    final detail =
        await ref.read(templatesListProvider.notifier).getDetail(template.id);
    if (detail == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _TemplateFormScreen(
              editTemplate: template, editDetail: detail)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Eliminar plantilla'),
        content: Text(
            'Eliminar "${template.name}"? Si tiene procesos asociados no se podra eliminar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(templatesListProvider.notifier).delete(template.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Plantilla eliminada'),
              backgroundColor: Color(0xFF10B981)));
          Navigator.pop(context);
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
}

// ─── Template Form Screen (Create / Edit) ─────────────────

class _TemplateFormScreen extends ConsumerStatefulWidget {
  final TemplateItem? editTemplate;
  final TemplateDetail? editDetail;

  const _TemplateFormScreen({this.editTemplate, this.editDetail});

  @override
  ConsumerState<_TemplateFormScreen> createState() =>
      _TemplateFormScreenState();
}

class _TemplateFormScreenState extends ConsumerState<_TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _codeController = TextEditingController();
  final _industryController = TextEditingController();
  final List<TemplateStepDraft> _steps = [];
  bool _loading = false;

  bool get _isEdit => widget.editTemplate != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.editTemplate!;
      _nameController.text = t.name;
      _descController.text = t.description ?? '';
      _codeController.text = t.code ?? '';
      _industryController.text = t.industry ?? '';
      // Load steps from detail
      for (final s in widget.editDetail!.steps) {
        final fields = (s['field_schema'] as List?)
                ?.map((f) => TemplateField(
                      name: f['name'] ?? '',
                      label: f['label'] ?? '',
                      type: f['type'] ?? 'texto',
                      required: f['required'] ?? false,
                      options: (f['options'] as List?)
                              ?.map((o) => o.toString())
                              .toList() ??
                          [],
                    ))
                .toList() ??
            [];
        _steps.add(TemplateStepDraft(
          name: s['name'] ?? '',
          description: s['description'] ?? '',
          orderIndex: s['order_index'] ?? _steps.length + 1,
          fields: fields,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _codeController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar plantilla' : 'Nueva plantilla',
            style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryDark,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // ── Basic info ──
            _label('Nombre *'),
            SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: 'Nombre de la plantilla',
                  prefixIcon: Icon(Icons.description_rounded, size: 20)),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            SizedBox(height: 14),
            _label('Codigo (abreviatura)'),
            SizedBox(height: 6),
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                  labelText: 'Ej: TMB, INS, CAL',
                  prefixIcon: Icon(Icons.tag_rounded, size: 20)),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 14),
            _label('Industria'),
            SizedBox(height: 6),
            TextFormField(
              controller: _industryController,
              decoration: InputDecoration(
                  labelText: 'Industria (opcional)',
                  prefixIcon: Icon(Icons.factory_rounded, size: 20)),
            ),
            SizedBox(height: 14),
            _label('Descripcion'),
            SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: 'Descripcion (opcional)',
                  alignLabelWithHint: true),
            ),
            SizedBox(height: 24),

            // ── Steps ──
            Row(
              children: [
                _label('Etapas'),
                Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: Icon(Icons.add_rounded, size: 18),
                  label: Text('Agregar'),
                ),
              ],
            ),
            SizedBox(height: 6),
            if (_steps.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0))),
                child: Text('Agrega al menos una etapa',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
              ),
            ..._steps.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return _StepEditor(
                step: s,
                index: i,
                onRemove: () => setState(() => _steps.removeAt(i)),
                onFieldsChanged: () => setState(() {}),
              );
            }),

            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Guardar cambios' : 'Crear plantilla',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark));
  }

  void _addStep() {
    setState(() {
      _steps.add(TemplateStepDraft(
        name: '',
        orderIndex: _steps.length + 1,
      ));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Agrega al menos una etapa'),
          backgroundColor: Color(0xFFF97316)));
      return;
    }
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].name.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('La etapa ${i + 1} necesita nombre'),
            backgroundColor: Color(0xFFF97316)));
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final notifier = ref.read(templatesListProvider.notifier);
      if (_isEdit) {
        await notifier.update(
          id: widget.editTemplate!.id,
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          industry: _industryController.text.trim(),
          code: _codeController.text.trim(),
          steps: _steps,
        );
      } else {
        await notifier.create(
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          industry: _industryController.text.trim(),
          code: _codeController.text.trim(),
          steps: _steps,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEdit ? 'Plantilla actualizada' : 'Plantilla creada'),
            backgroundColor: Color(0xFF10B981)));
        Navigator.pop(context);
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

// ─── Step Editor Widget ──────────────────────────────────

class _StepEditor extends StatefulWidget {
  final TemplateStepDraft step;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onFieldsChanged;

  const _StepEditor({
    required this.step,
    required this.index,
    required this.onRemove,
    required this.onFieldsChanged,
  });

  @override
  State<_StepEditor> createState() => _StepEditorState();
}

class _StepEditorState extends State<_StepEditor> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7)),
                    child: Center(
                        child: Text('${widget.index + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark))),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            s.name.isEmpty ? 'Sin nombre' : s.name,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: s.name.isEmpty
                                    ? AppTheme.textLight
                                    : AppTheme.textDark)),
                        Text('${s.fields.length} campos',
                            style: TextStyle(
                                fontSize: 11, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: Color(0xFFEF4444)),
                  ),
                  Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppTheme.textLight),
                ],
              ),
            ),
          ),

          // Expanded body
          if (_expanded) ...[
            Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: s.name,
                    decoration: InputDecoration(
                        labelText: 'Nombre de la etapa *',
                        isDense: true),
                    onChanged: (v) {
                      s.name = v;
                      widget.onFieldsChanged();
                    },
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    initialValue: s.description,
                    decoration: InputDecoration(
                        labelText: 'Descripcion (opcional)',
                        isDense: true),
                    onChanged: (v) {
                      s.description = v;
                    },
                  ),
                  SizedBox(height: 14),

                  // Fields
                  Row(
                    children: [
                      Text('Campos del formulario',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                      Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            s.fields.add(TemplateField.empty());
                          });
                          widget.onFieldsChanged();
                        },
                        icon: Icon(Icons.add_rounded, size: 16),
                        label: Text('Campo',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ...s.fields.asMap().entries.map((e) {
                    final fi = e.key;
                    final f = e.value;
                    return _FieldEditor(
                      field: f,
                      onRemove: () {
                        setState(() => s.fields.removeAt(fi));
                        widget.onFieldsChanged();
                      },
                      onChanged: () {
                        widget.onFieldsChanged();
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Field Editor Widget ──────────────────────────────────

class _FieldEditor extends StatefulWidget {
  final TemplateField field;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _FieldEditor({
    required this.field,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  final _optController = TextEditingController();

  @override
  void dispose() {
    _optController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.field;
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Color(0xFFE2E8F0))),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: f.name,
                  decoration: InputDecoration(
                      labelText: 'ID campo *',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onChanged: (v) {
                    f.name = v;
                    widget.onChanged();
                  },
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  initialValue: f.label,
                  decoration: InputDecoration(
                      labelText: 'Etiqueta *',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  onChanged: (v) {
                    f.label = v;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: f.type,
                  isDense: true,
                  decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: [
                    DropdownMenuItem(value: 'texto', child: Text('Texto')),
                    DropdownMenuItem(value: 'numero', child: Text('Numero')),
                    DropdownMenuItem(value: 'fecha', child: Text('Fecha')),
                    DropdownMenuItem(value: 'hora', child: Text('Hora')),
                    DropdownMenuItem(
                        value: 'seleccion', child: Text('Seleccion')),
                    DropdownMenuItem(
                        value: 'booleano', child: Text('Booleano')),
                    DropdownMenuItem(
                        value: 'parrafo', child: Text('Parrafo')),
                  ],
                  onChanged: (v) {
                    setState(() => f.type = v ?? 'texto');
                    widget.onChanged();
                  },
                ),
              ),
              SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Req', style: TextStyle(fontSize: 12)),
                Switch(
                  value: f.required,
                  onChanged: (v) {
                    setState(() => f.required = v);
                    widget.onChanged();
                  },
                  activeThumbColor: AppTheme.primaryDark,
                ),
              ]),
              IconButton(
                onPressed: widget.onRemove,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: Color(0xFFEF4444)),
              ),
            ],
          ),

          // Options for 'seleccion'
          if (f.type == 'seleccion') ...[
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...f.options.asMap().entries.map((e) {
                  final oi = e.key;
                  return Chip(
                    label: Text(e.value, style: TextStyle(fontSize: 11)),
                    deleteIcon: Icon(Icons.close, size: 14),
                    onDeleted: () {
                      setState(() => f.options.removeAt(oi));
                      widget.onChanged();
                    },
                    backgroundColor: Color(0xFFEFF6FF),
                    side: BorderSide(color: Color(0xFFBFDBFE)),
                  );
                }),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optController,
                    decoration: InputDecoration(
                        hintText: 'Agregar opcion...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8)),
                  ),
                ),
                SizedBox(width: 6),
                IconButton(
                  onPressed: () {
                    final val = _optController.text.trim();
                    if (val.isNotEmpty) {
                      setState(() => f.options.add(val));
                      _optController.clear();
                      widget.onChanged();
                    }
                  },
                  icon: Icon(Icons.add_circle_rounded,
                      size: 22, color: AppTheme.primaryDark),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
