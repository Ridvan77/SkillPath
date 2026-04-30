import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class InstructorProvider extends ChangeNotifier {
  List<CourseDetailDto> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<CourseDetailDto> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalStudents {
    int total = 0;
    for (final course in _courses) {
      for (final schedule in course.schedules) {
        total += schedule.currentEnrollment;
      }
    }
    return total;
  }

  double get averageRating {
    if (_courses.isEmpty) return 0.0;
    final rated = _courses.where((c) => c.reviewCount > 0).toList();
    if (rated.isEmpty) return 0.0;
    final sum = rated.fold<double>(0.0, (acc, c) => acc + c.averageRating);
    return sum / rated.length;
  }

  Future<void> fetchInstructorCourses(String instructorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Get course list for this instructor
      final response =
          await ApiClient.get('/api/Course/instructor/$instructorId');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<dynamic> courseItems;

        if (jsonData is List) {
          courseItems = jsonData;
        } else if (jsonData is Map<String, dynamic>) {
          courseItems = jsonData['items'] as List<dynamic>? ?? [];
        } else {
          courseItems = [];
        }

        // Step 2: For each course, fetch full detail (includes schedules with enrollment)
        final detailedCourses = <CourseDetailDto>[];
        for (final item in courseItems) {
          final courseId = item['id'] as String?;
          if (courseId == null) continue;

          try {
            final detailResponse = await ApiClient.get('/api/Course/$courseId');
            if (detailResponse.statusCode == 200) {
              final detailData =
                  jsonDecode(detailResponse.body) as Map<String, dynamic>;
              detailedCourses.add(CourseDetailDto.fromJson(detailData));
            }
          } catch (e) {
            debugPrint('Failed to fetch detail for course $courseId: $e');
            // Fall back to basic data without schedules
            detailedCourses
                .add(CourseDetailDto.fromJson(item as Map<String, dynamic>));
          }
        }

        _courses = detailedCourses;
      } else {
        _error =
            'Greska prilikom ucitavanja kurseva (${response.statusCode}).';
      }
    } catch (e) {
      _error = 'Greska prilikom ucitavanja kurseva: $e';
      debugPrint('InstructorProvider.fetchInstructorCourses error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
