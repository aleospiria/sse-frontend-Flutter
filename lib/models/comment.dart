class Comment {
  final String id;
  final String processId;
  final String stepId;
  final String userId;
  final String authorName;
  final String content;
  final String createdAt;

  const Comment({
    required this.id,
    required this.processId,
    required this.stepId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      processId: json['process_id'] as String,
      stepId: json['step_id'] as String,
      userId: json['user_id'] as String,
      authorName: json['author_name'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'process_id': processId,
        'step_id': stepId,
        'user_id': userId,
        'author_name': authorName,
        'content': content,
        'created_at': createdAt,
      };
}
