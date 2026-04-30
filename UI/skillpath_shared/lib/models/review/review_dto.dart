class ReviewDto {
  final String id;
  final String userId;
  final String userFullName;
  final String courseId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isVisible;
  final int helpfulCount;
  final bool isHelpfulByCurrentUser;

  ReviewDto({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.courseId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVisible,
    required this.helpfulCount,
    required this.isHelpfulByCurrentUser,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userFullName: json['userFullName'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVisible: json['isVisible'] as bool? ?? true,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
      isHelpfulByCurrentUser:
          json['isHelpfulByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userFullName': userFullName,
        'courseId': courseId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
        'isVisible': isVisible,
        'helpfulCount': helpfulCount,
        'isHelpfulByCurrentUser': isHelpfulByCurrentUser,
      };
}
