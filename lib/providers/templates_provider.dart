import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sse_frontend_mobil/providers/auth_provider.dart';

// ── Models ──

class TemplateItem {
  final String id;
  final String name;
  final String? description;
  final String? industry;
  final String? code;
  final int totalSteps;
  final String? createdAt;

  TemplateItem({
    required this.id,
    required this.name,
    this.description,
    this.industry,
    this.code,
    this.totalSteps = 0,
    this.createdAt,
  });

  factory TemplateItem.fromJson(Map<String, dynamic> j) => TemplateItem(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        industry: j['industry'] as String?,
        code: j['code'] as String?,
        totalSteps: j['total_steps'] ?? 0,
        createdAt: j['created_at'] as String?,
      );
}

class TemplateField {
  String name;
  String label;
  String type;
  bool required;
  List<String> options;

  TemplateField({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'type': type,
        'required': required,
        if (type == 'seleccion' && options.isNotEmpty) 'options': options,
      };

  factory TemplateField.empty() =>
      TemplateField(name: '', label: '', type: 'texto');
}

class TemplateStepDraft {
  String name;
  String description;
  int orderIndex;
  List<TemplateField> fields;

  TemplateStepDraft({
    required this.name,
    this.description = '',
    required this.orderIndex,
    this.fields = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description.isEmpty ? null : description,
        'order_index': orderIndex,
        'field_schema': fields.map((f) => f.toJson()).toList(),
      };
}

class TemplateDetail {
  final TemplateItem template;
  final List<Map<String, dynamic>> steps;

  TemplateDetail({required this.template, required this.steps});

  factory TemplateDetail.fromJson(Map<String, dynamic> j) => TemplateDetail(
        template: TemplateItem.fromJson(j['template']),
        steps: (j['steps'] as List).cast<Map<String, dynamic>>(),
      );
}

// ── Provider ──

final templatesListProvider =
    StateNotifierProvider<TemplatesNotifier, AsyncValue<List<TemplateItem>>>(
        (ref) {
  return TemplatesNotifier(ref)..load();
});

class TemplatesNotifier extends StateNotifier<AsyncValue<List<TemplateItem>>> {
  final Ref ref;
  TemplatesNotifier(this.ref) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/templates');
      final body = jsonDecode(res.body) as List;
      final list =
          body.map((j) => TemplateItem.fromJson(j as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();

  Future<TemplateDetail?> getDetail(String id) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/templates/$id');
    final body = jsonDecode(res.body);
    return TemplateDetail.fromJson(body as Map<String, dynamic>);
  }

  Future<void> create({
    required String name,
    String? description,
    String? industry,
    String? code,
    required List<TemplateStepDraft> steps,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/templates', body: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (code != null && code.isNotEmpty) 'code': code,
      'steps': steps.map((s) => s.toJson()).toList(),
    });
    await load();
  }

  Future<void> update({
    required String id,
    required String name,
    String? description,
    String? industry,
    String? code,
    required List<TemplateStepDraft> steps,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.put('/templates/$id', body: {
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (industry != null && industry.isNotEmpty) 'industry': industry,
      if (code != null && code.isNotEmpty) 'code': code,
      'steps': steps.map((s) => s.toJson()).toList(),
    });
    await load();
  }

  Future<bool> delete(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.delete('/templates/$id');
      await load();
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
