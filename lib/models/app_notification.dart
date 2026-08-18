class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? link;
  final bool read;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.link,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      link: json['link'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'link': link,
        'read': read,
        'created_at': createdAt,
      };
}
