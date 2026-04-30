class CourseDto {
  final String id;
  final String title;
  final String shortDescription;
  final double price;
  final int durationWeeks;
  final String difficultyLevel;
  final String? imageUrl;
  final bool isActive;
  final bool isFeatured;
  final int categoryId;
  final String categoryName;
  final String instructorId;
  final String instructorName;
  final double averageRating;
  final int reviewCount;
  final DateTime createdAt;

  CourseDto({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.price,
    required this.durationWeeks,
    required this.difficultyLevel,
    this.imageUrl,
    required this.isActive,
    required this.isFeatured,
    required this.categoryId,
    required this.categoryName,
    required this.instructorId,
    required this.instructorName,
    required this.averageRating,
    required this.reviewCount,
    required this.createdAt,
  });

  factory CourseDto.fromJson(Map<String, dynamic> json) {
    return CourseDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationWeeks: json['durationWeeks'] as int? ?? 0,
      difficultyLevel: json['difficultyLevel'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      instructorId: json['instructorId'] as String? ?? '',
      instructorName: json['instructorName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'shortDescription': shortDescription,
        'price': price,
        'durationWeeks': durationWeeks,
        'difficultyLevel': difficultyLevel,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'instructorId': instructorId,
        'instructorName': instructorName,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'createdAt': createdAt.toIso8601String(),
      };
}
