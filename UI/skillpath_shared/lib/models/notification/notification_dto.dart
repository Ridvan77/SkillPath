class NotificationDto {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedEntityId;
  final String? relatedEntityType;

  NotificationDto({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedEntityId,
    this.relatedEntityType,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      relatedEntityId: json['relatedEntityId'] as String?,
      relatedEntityType: json['relatedEntityType'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'relatedEntityId': relatedEntityId,
        'relatedEntityType': relatedEntityType,
      };
}
