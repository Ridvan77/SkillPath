class CourseScheduleDto {
  final String id;
  final String courseId;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final DateTime startDate;
  final DateTime endDate;
  final int maxCapacity;
  final int currentEnrollment;
  final bool isActive;

  CourseScheduleDto({
    required this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.maxCapacity,
    required this.currentEnrollment,
    required this.isActive,
  });

  int get availableSpots => maxCapacity - currentEnrollment;

  bool get isFull => currentEnrollment >= maxCapacity;

  factory CourseScheduleDto.fromJson(Map<String, dynamic> json) {
    return CourseScheduleDto(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      dayOfWeek: json['dayOfWeek'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now(),
      maxCapacity: json['maxCapacity'] as int? ?? 0,
      currentEnrollment: json['currentEnrollment'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'courseId': courseId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'maxCapacity': maxCapacity,
        'currentEnrollment': currentEnrollment,
        'isActive': isActive,
      };
}
