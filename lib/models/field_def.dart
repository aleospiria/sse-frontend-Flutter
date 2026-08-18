enum FieldType { texto, numero, fecha, hora, seleccion, booleano, parrafo }

class FieldDef {
  final String name;
  final String label;
  final FieldType type;
  final bool required;
  final List<String>? options;

  const FieldDef({
    required this.name,
    required this.label,
    required this.type,
    required this.required,
    this.options,
  });

  factory FieldDef.fromJson(Map<String, dynamic> json) {
    return FieldDef(
      name: json['name'] as String,
      label: json['label'] as String,
      type: FieldType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FieldType.texto,
      ),
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'label': label,
        'type': type.name,
        'required': required,
        'options': options,
      };
}
