import 'package:sse_frontend_mobil/models/field_def.dart';
import 'package:sse_frontend_mobil/models/step_record.dart';

class Step {
  final String id;
  final String processId;
  final String name;
  final String? description;
  final int orderIndex;
  final String? assignedTo;
  final String? assignedUsername;
  final List<FieldDef> fieldSchema;
  final String? deadline;
  final StepRecord? record;

  const Step({
    required this.id,
    required this.processId,
    required this.name,
    this.description,
    required this.orderIndex,
    this.assignedTo,
    this.assignedUsername,
    required this.fieldSchema,
    this.deadline,
    this.record,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      id: json['id'] as String,
      processId: json['process_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int,
      assignedTo: json['assigned_to'] as String?,
      assignedUsername: json['assigned_username'] as String?,
      fieldSchema: (json['field_schema'] as List<dynamic>?)
              ?.map((e) => FieldDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      deadline: json['deadline'] as String?,
      record: json['record'] != null
          ? StepRecord.fromJson(json['record'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'process_id': processId,
        'name': name,
        'description': description,
        'order_index': orderIndex,
        'assigned_to': assignedTo,
        'assigned_username': assignedUsername,
        'field_schema': fieldSchema.map((f) => f.toJson()).toList(),
        'deadline': deadline,
        'record': record?.toJson(),
      };

  bool get isCompleted => record != null;
  bool get isAssigned => assignedTo != null;
}
