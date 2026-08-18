import 'package:sse_frontend_mobil/models/field_def.dart';

class Template {
  final String id;
  final String name;
  final String? description;
  final List<TemplateStep> steps;
  final String createdAt;

  const Template({
    required this.id,
    required this.name,
    this.description,
    required this.steps,
    required this.createdAt,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => TemplateStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'created_at': createdAt,
      };
}

class TemplateStep {
  final String name;
  final String? description;
  final int orderIndex;
  final List<FieldDef> fieldSchema;

  const TemplateStep({
    required this.name,
    this.description,
    required this.orderIndex,
    required this.fieldSchema,
  });

  factory TemplateStep.fromJson(Map<String, dynamic> json) {
    return TemplateStep(
      name: json['name'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int,
      fieldSchema: (json['field_schema'] as List<dynamic>?)
              ?.map((e) => FieldDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'order_index': orderIndex,
        'field_schema': fieldSchema.map((f) => f.toJson()).toList(),
      };
}
