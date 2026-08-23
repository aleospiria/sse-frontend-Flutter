import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sse_frontend_mobil/models/attachment.dart';
import 'package:sse_frontend_mobil/models/field_def.dart';
import 'package:sse_frontend_mobil/providers/attachment_provider.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';
import 'package:sse_frontend_mobil/providers/process_detail_provider.dart';
import 'package:sse_frontend_mobil/services/api_client.dart';

class RecordStepScreen extends ConsumerStatefulWidget {
  final String processId;
  final String stepId;

  const RecordStepScreen({
    super.key,
    required this.processId,
    required this.stepId,
  });

  @override
  ConsumerState<RecordStepScreen> createState() => _RecordStepScreenState();
}

class _RecordStepScreenState extends ConsumerState<RecordStepScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;
  bool _submitted = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _initFromExistingRecord();
  }

  void _initFromExistingRecord() {
    final detail = ref.read(processDetailProvider(widget.processId));
    detail.whenData((d) {
      final step = d.steps.firstWhere(
        (s) => s.id == widget.stepId,
        orElse: () => d.steps.first,
      );
      final existingData = step.record?.data;
      if (existingData != null) {
        for (final field in step.fieldSchema) {
          final value = existingData[field.name];
          if (value != null) {
            _formData[field.name] = value;
            if (field.type == FieldType.texto ||
                field.type == FieldType.numero ||
                field.type == FieldType.parrafo) {
              _controllers[field.name] =
                  TextEditingController(text: value.toString());
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seleccionar fuente',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF2563EB)),
                title: const Text('Galería'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF16A34A)),
                title: const Text('Cámara'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (picked == null || !mounted) return;

      setState(() => _uploading = true);

      final api = ref.read(apiClientProvider);
      final file = File(picked.path);
      final ext = picked.path.split('.').last.toLowerCase();
      final contentType = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };
      final response = await api.multipart(
        '/uploads/${widget.processId}/${widget.stepId}',
        file: file,
        contentType: contentType,
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final attachment = Attachment.fromJson(body);

      ref.invalidate(
          stepAttachmentsProvider((processId: widget.processId, stepId: widget.stepId)));

      if (!mounted) return;
      setState(() => _uploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto "${attachment.originalName}" subida'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);

      String msg;
      if (e is ApiException) {
        msg = e.message;
      } else {
        msg = 'Error al subir foto';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: Text('¿Eliminar "${attachment.originalName}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.delete(
          '/uploads/${widget.processId}/${widget.stepId}/${attachment.id}');

      ref.invalidate(
          stepAttachmentsProvider((processId: widget.processId, stepId: widget.stepId)));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evidencia eliminada'),
          backgroundColor: const Color(0xFF64748B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo eliminar'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(processDetailProvider(widget.processId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text('Registrar etapa',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF1E293B)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text('Error: $e',
                  style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
        data: (detail) {
          final step = detail.steps.firstWhere(
            (s) => s.id == widget.stepId,
            orElse: () => detail.steps.first,
          );

          if (step.fieldSchema.isEmpty) {
            return _buildEmptySchema(step);
          }

          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStepHeader(step),
                      const SizedBox(height: 16),
                      ...step.fieldSchema.map((field) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildField(field),
                          )),
                      _buildAttachmentsSection(),
                      if (_submitted)
                        _buildSuccessBanner(step),
                    ],
                  ),
                ),
              ),
              _buildSubmitBar(step),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptySchema(dynamic step) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.description_outlined,
              size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text('Esta etapa no tiene campos configurados',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _submitData(step),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Registrar sin datos'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(dynamic step) {
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_rounded,
                size: 20, color: Color(0xFFF97316)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.name,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
                if (step.description != null && step.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(step.description!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(FieldDef field) {
    switch (field.type) {
      case FieldType.texto:
        return _buildTextField(field);
      case FieldType.numero:
        return _buildNumberField(field);
      case FieldType.parrafo:
        return _buildParagraphField(field);
      case FieldType.fecha:
        return _buildDateField(field);
      case FieldType.hora:
        return _buildTimeField(field);
      case FieldType.seleccion:
        return _buildSelectField(field);
      case FieldType.booleano:
        return _buildSwitchField(field);
    }
  }

  Widget _buildTextField(FieldDef field) {
    final controller =
        _controllers.putIfAbsent(field.name, () => TextEditingController());
    return _fieldCard(
      field: field,
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(field.label),
        onChanged: (v) => _formData[field.name] = v,
        validator: field.required
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'Campo obligatorio'
                : null
            : null,
      ),
    );
  }

  Widget _buildNumberField(FieldDef field) {
    final controller =
        _controllers.putIfAbsent(field.name, () => TextEditingController());
    return _fieldCard(
      field: field,
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(field.label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          final n = num.tryParse(v);
          _formData[field.name] = n ?? v;
        },
        validator: field.required
            ? (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obligatorio';
                if (num.tryParse(v) == null) return 'Ingrese un número válido';
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildParagraphField(FieldDef field) {
    final controller =
        _controllers.putIfAbsent(field.name, () => TextEditingController());
    return _fieldCard(
      field: field,
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(field.label),
        maxLines: 4,
        minLines: 2,
        onChanged: (v) => _formData[field.name] = v,
        validator: field.required
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'Campo obligatorio'
                : null
            : null,
      ),
    );
  }

  Widget _buildDateField(FieldDef field) {
    final current = _formData[field.name] as String?;
    return _fieldCard(
      field: field,
      child: GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: current != null ? DateTime.tryParse(current) ?? now : now,
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            locale: const Locale('es'),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1E293B)),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _formData[field.name] =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            });
          }
        },
        child: InputDecorator(
          decoration: _inputDecoration(field.label).copyWith(
            suffixIcon: const Icon(Icons.calendar_today_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ),
          child: Text(
            _formData[field.name]?.toString() ?? 'Seleccionar fecha',
            style: TextStyle(
              fontSize: 14,
              color: _formData[field.name] != null
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField(FieldDef field) {
    final current = _formData[field.name] as String?;
    return _fieldCard(
      field: field,
      child: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: current != null
                ? TimeOfDay(
                    hour: int.tryParse(current.split(':')[0]) ?? 0,
                    minute: int.tryParse(current.split(':')[1]) ?? 0,
                  )
                : TimeOfDay.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1E293B)),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              _formData[field.name] =
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            });
          }
        },
        child: InputDecorator(
          decoration: _inputDecoration(field.label).copyWith(
            suffixIcon: const Icon(Icons.schedule_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ),
          child: Text(
            _formData[field.name]?.toString() ?? 'Seleccionar hora',
            style: TextStyle(
              fontSize: 14,
              color: _formData[field.name] != null
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectField(FieldDef field) {
    final current = _formData[field.name] as String?;
    return _fieldCard(
      field: field,
      child: DropdownButtonFormField<String>(
        initialValue: current,
        decoration: _inputDecoration(field.label),
        items: (field.options ?? []).map((opt) {
          return DropdownMenuItem(value: opt, child: Text(opt));
        }).toList(),
        onChanged: (v) => setState(() => _formData[field.name] = v),
        validator: field.required
            ? (v) => (v == null || v.isEmpty) ? 'Campo obligatorio' : null
            : null,
      ),
    );
  }

  Widget _buildSwitchField(FieldDef field) {
    final current = _formData[field.name] as bool? ?? false;
    return _fieldCard(
      field: field,
      child: SwitchListTile(
        title: Text(field.label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B))),
        value: current,
        onChanged: (v) => setState(() => _formData[field.name] = v),
        activeThumbColor: const Color(0xFF16A34A),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _fieldCard({required FieldDef field, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.required)
            Row(children: [
              Text(field.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              const SizedBox(width: 4),
              const Text('*',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626))),
            ]),
          if (field.type != FieldType.booleano && field.required)
            const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626))),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildAttachmentsSection() {
    final params = (processId: widget.processId, stepId: widget.stepId);
    final attachmentsAsync = ref.watch(stepAttachmentsProvider(params));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_rounded,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              const Text('Evidencias',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              if (_uploading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFF97316)),
                )
              else
                TextButton.icon(
                  onPressed: _pickAndUploadPhoto,
                  icon: const Icon(Icons.add_photo_alternate_rounded,
                      size: 18),
                  label: const Text('Agregar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF97316),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          attachmentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Error: $err',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
            ),
            data: (attachments) {
              if (attachments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                      _uploading
                          ? 'Subiendo archivo...'
                          : 'Sin evidencias adjuntas',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFCBD5E1))),
                );
              }

              return Column(
                children: attachments.map((att) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (att.isImage)
                          att.url != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    att.url!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 44,
                                      height: 44,
                                      color: const Color(0xFFE2E8F0),
                                      child: const Icon(
                                          Icons.broken_image_rounded,
                                          size: 20,
                                          color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.image_rounded,
                                      size: 20, color: Color(0xFF94A3B8)),
                                )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.description_rounded,
                                size: 20, color: Color(0xFFF59E0B)),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(att.originalName,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1E293B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(att.sizeFormatted,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteAttachment(att),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(dynamic step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF16A34A).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded,
              size: 20, color: Color(0xFF16A34A)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Etapa registrada correctamente. La confirmación en blockchain es automática.',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar(dynamic step) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _submitting
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _submitData(step);
                    }
                  },
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_submitting
                ? 'Enviando...'
                : (_submitted ? 'Registrar otra vez' : 'Registrar etapa')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFF97316).withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitData(dynamic step) async {
    setState(() => _submitting = true);

    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{};

      for (final field in step.fieldSchema) {
        final value = _formData[field.name];
        if (value != null) {
          body[field.name] = value;
        }
      }

      await api.post(
        '/process/${widget.processId}/step/${widget.stepId}',
        body: {'data': body},
      );

      ref.invalidate(processDetailProvider(widget.processId));

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Etapa registrada correctamente'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.pop();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);

      String msg = 'Error al registrar';
      if (e.toString().contains('409')) {
        msg = 'Este registro ya fue confirmado y no puede modificarse';
      } else if (e.toString().contains('400')) {
        msg = 'Datos inválidos. Verifique los campos.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
