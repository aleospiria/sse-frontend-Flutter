enum PublicStepStatus { pending, confirmed, failed }

class PublicResult {
  final String label;
  final dynamic value;
  final String type;

  const PublicResult({
    required this.label,
    required this.value,
    required this.type,
  });

  factory PublicResult.fromJson(Map<String, dynamic> json) => PublicResult(
        label: json['label'] as String? ?? '',
        value: json['value'],
        type: json['type'] as String? ?? 'texto',
      );
}

class PublicAttachment {
  final String? id;
  final String? originalName;
  final String? mimetype;
  final String? url;

  const PublicAttachment({
    this.id,
    this.originalName,
    this.mimetype,
    this.url,
  });

  factory PublicAttachment.fromJson(Map<String, dynamic> json) =>
      PublicAttachment(
        id: json['id'] as String?,
        originalName: json['original_name'] as String?,
        mimetype: json['mimetype'] as String?,
        url: json['url'] as String?,
      );
}

class PublicProcess {
  final String id;
  final String name;
  final String? description;
  final String? industry;
  final String? status;
  final String? createdAt;
  final String? closedAt;
  final String? processHash;
  final String? closeTxHash;
  final String? closeBlock;
  final String? closedByUsername;

  const PublicProcess({
    required this.id,
    required this.name,
    this.description,
    this.industry,
    this.status,
    this.createdAt,
    this.closedAt,
    this.processHash,
    this.closeTxHash,
    this.closeBlock,
    this.closedByUsername,
  });

  factory PublicProcess.fromJson(Map<String, dynamic> json) => PublicProcess(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        industry: json['industry'] as String?,
        status: json['status'] as String?,
        createdAt: json['created_at'] as String?,
        closedAt: json['closed_at'] as String?,
        processHash: json['process_hash'] as String?,
        closeTxHash: json['close_tx_hash'] as String?,
        closeBlock: json['close_block']?.toString(),
        closedByUsername: json['closed_by_username'] as String?,
      );

  bool get isSealed => closeTxHash != null || closedAt != null;
}

class PublicStep {
  final String? stepId;
  final int orderIndex;
  final String name;
  final String? description;
  final String? recordedByName;
  final PublicStepStatus status;
  final String? dataHash;
  final String? txHash;
  final String? blockNumber;
  final String? recordedAt;
  final String? completedAt;
  final List<PublicResult> results;
  final List<PublicAttachment> attachments;

  const PublicStep({
    this.stepId,
    required this.orderIndex,
    required this.name,
    this.description,
    this.recordedByName,
    required this.status,
    this.dataHash,
    this.txHash,
    this.blockNumber,
    this.recordedAt,
    this.completedAt,
    this.results = const [],
    this.attachments = const [],
  });

  factory PublicStep.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    final rawAttachments = json['attachments'];

    List<PublicResult> results;
    if (rawResults is List) {
      results = rawResults
          .whereType<Map<String, dynamic>>()
          .map(PublicResult.fromJson)
          .toList();
    } else {
      results = const [];
    }

    List<PublicAttachment> attachments;
    if (rawAttachments is List) {
      attachments = rawAttachments
          .whereType<Map<String, dynamic>>()
          .map(PublicAttachment.fromJson)
          .toList();
    } else {
      attachments = const [];
    }

    return PublicStep(
      stepId: json['step_id'] as String?,
      orderIndex: json['order_index'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      recordedByName: json['recorded_by_name'] as String?,
      status: PublicStepStatus.values.firstWhere(
        (s) => s.name == (json['status'] ?? 'pending'),
        orElse: () => PublicStepStatus.pending,
      ),
      dataHash: json['data_hash'] as String?,
      txHash: json['tx_hash'] as String?,
      blockNumber: json['block_number']?.toString(),
      recordedAt: json['recorded_at'] as String?,
      completedAt: json['completed_at'] as String?,
      results: results,
      attachments: attachments,
    );
  }

  bool get isConfirmed => status == PublicStepStatus.confirmed;
}
