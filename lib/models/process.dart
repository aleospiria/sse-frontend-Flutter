class Process {
  final String id;
  final String name;
  final String? description;
  final String status;
  final String? industry;
  final String? clientName;
  final String? processHash;
  final String? closeTxHash;
  final String? closeBlock;
  final String? closedAt;
  final String? closedByUsername;
  final String? assignedName;
  final String createdAt;
  final String updatedAt;
  final int? totalSteps;
  final int? confirmedSteps;

  const Process({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.industry,
    this.clientName,
    this.processHash,
    this.closeTxHash,
    this.closeBlock,
    this.closedAt,
    this.closedByUsername,
    this.assignedName,
    required this.createdAt,
    required this.updatedAt,
    this.totalSteps,
    this.confirmedSteps,
  });

  factory Process.fromJson(Map<String, dynamic> json) {
    return Process(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      industry: json['industry'] as String?,
      clientName: json['client_name'] as String?,
      processHash: json['process_hash'] as String?,
      closeTxHash: json['close_tx_hash'] as String?,
      closeBlock: json['close_block'] as String?,
      closedAt: json['closed_at'] as String?,
      closedByUsername: json['closed_by_username'] as String?,
      assignedName: json['assigned_name'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      totalSteps: json['total_steps'] as int?,
      confirmedSteps: json['confirmed_steps'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'status': status,
        'industry': industry,
        'client_name': clientName,
        'process_hash': processHash,
        'close_tx_hash': closeTxHash,
        'close_block': closeBlock,
        'closed_at': closedAt,
        'closed_by_username': closedByUsername,
        'assigned_name': assignedName,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'total_steps': totalSteps,
        'confirmed_steps': confirmedSteps,
      };

  bool get isClosed => status == 'closed' || closedAt != null;

  double get progress =>
      totalSteps != null && totalSteps! > 0 && confirmedSteps != null
          ? confirmedSteps! / totalSteps!
          : 0.0;
}
