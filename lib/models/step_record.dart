enum StepRecordStatus { pending, confirmed, failed }

class StepRecord {
  final String id;
  final String stepId;
  final String processId;
  final Map<String, dynamic> data;
  final String? dataHash;
  final String? txHash;
  final String? blockNumber;
  final StepRecordStatus status;
  final String? completedAt;
  final String createdAt;
  final String? recordedByUsername;

  const StepRecord({
    required this.id,
    required this.stepId,
    required this.processId,
    required this.data,
    this.dataHash,
    this.txHash,
    this.blockNumber,
    required this.status,
    this.completedAt,
    required this.createdAt,
    this.recordedByUsername,
  });

  factory StepRecord.fromJson(Map<String, dynamic> json) {
    return StepRecord(
      id: json['id'] as String,
      stepId: json['step_id'] as String,
      processId: json['process_id'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      dataHash: json['data_hash'] as String?,
      txHash: json['tx_hash'] as String?,
      blockNumber: json['block_number'] as String?,
      status: StepRecordStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StepRecordStatus.pending,
      ),
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      recordedByUsername: json['recorded_by_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'step_id': stepId,
        'process_id': processId,
        'data': data,
        'data_hash': dataHash,
        'tx_hash': txHash,
        'block_number': blockNumber,
        'status': status.name,
        'completed_at': completedAt,
        'created_at': createdAt,
        'recorded_by_username': recordedByUsername,
      };

  bool get isConfirmed => status == StepRecordStatus.confirmed;
  bool get isPending => status == StepRecordStatus.pending;
  bool get isFailed => status == StepRecordStatus.failed;
}
