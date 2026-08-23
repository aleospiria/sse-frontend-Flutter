class Attachment {
  final String id;
  final String? processId;
  final String? stepId;
  final String storageKey;
  final String? url;
  final String originalName;
  final String mimetype;
  final int sizeBytes;
  final String createdAt;
  final String? uploadedByUsername;

  const Attachment({
    required this.id,
    this.processId,
    this.stepId,
    required this.storageKey,
    this.url,
    required this.originalName,
    required this.mimetype,
    required this.sizeBytes,
    required this.createdAt,
    this.uploadedByUsername,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      processId: json['process_id'] as String?,
      stepId: json['step_id'] as String?,
      storageKey: json['storage_key'] as String,
      url: json['url'] as String?,
      originalName: json['original_name'] as String,
      mimetype: json['mimetype'] as String,
      sizeBytes: json['size_bytes'] as int,
      createdAt: json['created_at'] as String,
      uploadedByUsername: json['uploaded_by_username'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'process_id': processId,
        'step_id': stepId,
        'storage_key': storageKey,
        'url': url,
        'original_name': originalName,
        'mimetype': mimetype,
        'size_bytes': sizeBytes,
        'created_at': createdAt,
        'uploaded_by_username': uploadedByUsername,
      };

  bool get isImage =>
      mimetype == 'image/jpeg' ||
      mimetype == 'image/png' ||
      mimetype == 'image/webp';

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
