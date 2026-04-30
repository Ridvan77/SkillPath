class CategoryDto {
  final int id;
  final String name;
  final String? description;
  final int coursesCount;

  CategoryDto({
    required this.id,
    required this.name,
    this.description,
    required this.coursesCount,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      coursesCount: json['coursesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'coursesCount': coursesCount,
      };
}
