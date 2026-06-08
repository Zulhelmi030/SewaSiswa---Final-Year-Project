class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // e.g., 'payment', 'housemate_request', 'system'
  final bool isRead;
  final String? relatedId; // Optional ID linking to a specific rental, payment, etc.
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.relatedId,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      isRead: json['is_read'] as bool? ?? false,
      relatedId: json['related_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      if (relatedId != null) 'related_id': relatedId,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
