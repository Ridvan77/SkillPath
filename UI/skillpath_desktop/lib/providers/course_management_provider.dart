import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class CourseScheduleItem {
  final String? id;
  final String courseId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final DateTime startDate;
  final DateTime endDate;
  final int maxCapacity;
  final int currentEnrollment;
  final bool isActive;

  CourseScheduleItem({
    this.id,
    required this.courseId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.maxCapacity,
    this.currentEnrollment = 0,
    this.isActive = true,
  });

  factory CourseScheduleItem.fromJson(Map<String, dynamic> json) {
    return CourseScheduleItem(
      id: json['id']?.toString(),
      courseId: json['courseId']?.toString() ?? '',
      dayOfWeek: _parseDayOfWeek(json['dayOfWeek']),
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : DateTime.now().add(const Duration(days: 90)),
      maxCapacity: json['maxCapacity'] as int? ?? 20,
      currentEnrollment: json['currentEnrollment'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static int _parseDayOfWeek(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      const days = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ];
      final idx = days.indexWhere(
          (d) => d.toLowerCase() == value.toLowerCase());
      return idx >= 0 ? idx : 0;
    }
    return 0;
  }

  Map<String, dynamic> toCreateJson() => {
        'courseId': courseId,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'maxCapacity': maxCapacity,
      };
}

class CourseManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<CourseDto> _courses = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;
  String _searchQuery = '';
  int? _categoryFilter;

  // Detail / form data
  Map<String, dynamic>? _courseDetail;
  List<CourseScheduleItem> _schedules = [];

  // Dropdown data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _instructors = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CourseDto> get courses => _courses;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  String get searchQuery => _searchQuery;
  int? get categoryFilter => _categoryFilter;
  Map<String, dynamic>? get courseDetail => _courseDetail;
  List<CourseScheduleItem> get schedules => _schedules;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get instructors => _instructors;

  // ---------------------------------------------------------------------------
  // Fetch all courses (paged)
  // ---------------------------------------------------------------------------
  Future<void> fetchCourses({
    int? page,
    String? search,
    int? categoryId,
  }) async {
    if (page != null) _currentPage = page;
    if (search != null) _searchQuery = search;
    if (categoryId != null) _categoryFilter = categoryId;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var endpoint =
          '/api/Course?page=$_currentPage&pageSize=$_pageSize';
      if (_searchQuery.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(_searchQuery)}';
      }
      if (_categoryFilter != null && _categoryFilter! > 0) {
        endpoint += '&categoryId=$_categoryFilter';
      }

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _courses = (data['items'] as List<dynamic>?)
                ?.map((e) => CourseDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;
      } else {
        _error = 'Greska pri ucitavanju kurseva (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearCategoryFilter() {
    _categoryFilter = null;
    fetchCourses(page: 1);
  }

  // ---------------------------------------------------------------------------
  // Fetch single course detail
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchCourseDetail(String courseId) async {
    try {
      final response = await ApiClient.get('/api/Course/$courseId');
      if (response.statusCode == 200) {
        _courseDetail = jsonDecode(response.body) as Map<String, dynamic>;
        notifyListeners();
        return _courseDetail;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Fetch schedules for a course
  // ---------------------------------------------------------------------------
  Future<void> fetchSchedules(String courseId) async {
    try {
      final response =
          await ApiClient.get('/api/course-schedules/course/$courseId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _schedules = data
            .map((e) =>
                CourseScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch dropdown data (categories + instructors)
  // ---------------------------------------------------------------------------
  Future<void> fetchDropdownData() async {
    try {
      final catResponse = await ApiClient.get('/api/Category');
      if (catResponse.statusCode == 200) {
        final catData = jsonDecode(catResponse.body);
        if (catData is List) {
          _categories = catData
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
      }

      final userResponse =
          await ApiClient.get('/api/User?role=Instructor&pageSize=100');
      if (userResponse.statusCode == 200) {
        final userData =
            jsonDecode(userResponse.body) as Map<String, dynamic>;
        _instructors = (userData['items'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Create course
  // ---------------------------------------------------------------------------
  Future<String?> createCourse(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/api/Course', data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['id']?.toString();
      } else {
        _error = 'Greska pri kreiranju kursa (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------------------
  // Update course
  // ---------------------------------------------------------------------------
  Future<bool> updateCourse(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.put('/api/Course/$id', data);
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Greska pri azuriranju kursa (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Delete course
  // ---------------------------------------------------------------------------
  Future<bool> deleteCourse(String id) async {
    try {
      final response = await ApiClient.delete('/api/Course/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _courses.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Schedule CRUD
  // ---------------------------------------------------------------------------
  Future<bool> createSchedule(Map<String, dynamic> data) async {
    try {
      final response =
          await ApiClient.post('/api/course-schedules', data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  Future<bool> deleteSchedule(String scheduleId) async {
    try {
      final response =
          await ApiClient.delete('/api/course-schedules/$scheduleId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _schedules.removeWhere((s) => s.id == scheduleId);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }
}
