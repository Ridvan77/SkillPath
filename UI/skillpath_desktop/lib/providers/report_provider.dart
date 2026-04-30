import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class InstructorReportItem {
  final String instructorId;
  final String instructorName;
  final int coursesCount;
  final int totalStudents;
  final double totalRevenue;
  final double averageRating;

  InstructorReportItem({
    required this.instructorId,
    required this.instructorName,
    required this.coursesCount,
    required this.totalStudents,
    required this.totalRevenue,
    required this.averageRating,
  });

  factory InstructorReportItem.fromJson(Map<String, dynamic> json) {
    return InstructorReportItem(
      instructorId: json['instructorId'] as String? ?? '',
      instructorName: json['instructorName'] as String? ?? '',
      coursesCount: json['coursesCount'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class InstructorReportData {
  final List<InstructorReportItem> instructors;
  final int totalInstructors;
  final int totalStudents;
  final double totalRevenue;
  final DateTime? fromDate;
  final DateTime? toDate;

  InstructorReportData({
    required this.instructors,
    required this.totalInstructors,
    required this.totalStudents,
    required this.totalRevenue,
    this.fromDate,
    this.toDate,
  });

  factory InstructorReportData.fromJson(Map<String, dynamic> json) {
    return InstructorReportData(
      instructors: (json['instructors'] as List<dynamic>?)
              ?.map((e) =>
                  InstructorReportItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalInstructors: json['totalInstructors'] as int? ?? 0,
      totalStudents: json['totalStudents'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      fromDate: json['fromDate'] != null
          ? DateTime.parse(json['fromDate'] as String)
          : null,
      toDate: json['toDate'] != null
          ? DateTime.parse(json['toDate'] as String)
          : null,
    );
  }
}

class CategoryPopularityItem {
  final int categoryId;
  final String categoryName;
  final int coursesCount;
  final int enrollmentCount;
  final double revenue;
  final double averageRating;

  CategoryPopularityItem({
    required this.categoryId,
    required this.categoryName,
    required this.coursesCount,
    required this.enrollmentCount,
    required this.revenue,
    required this.averageRating,
  });

  factory CategoryPopularityItem.fromJson(Map<String, dynamic> json) {
    return CategoryPopularityItem(
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      coursesCount: json['coursesCount'] as int? ?? 0,
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ReportProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  InstructorReportData? _instructorReport;
  List<CategoryPopularityItem> _categoryReport = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  InstructorReportData? get instructorReport => _instructorReport;
  List<CategoryPopularityItem> get categoryReport => _categoryReport;

  // ---------------------------------------------------------------------------
  // Instructor report
  // ---------------------------------------------------------------------------
  Future<void> fetchInstructorReport({
    List<String>? instructorIds,
    DateTime? from,
    DateTime? to,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var endpoint = '/api/Report/instructor?';
      final params = <String>[];
      if (instructorIds != null && instructorIds.isNotEmpty) {
        params.add('instructorIds=${instructorIds.join(',')}');
      }
      if (from != null) {
        params.add('from=${from.toIso8601String()}');
      }
      if (to != null) {
        params.add('to=${to.toIso8601String()}');
      }
      endpoint += params.join('&');

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _instructorReport = InstructorReportData.fromJson(data);
      } else {
        _error = 'Greska pri ucitavanju izvjestaja (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Category popularity report
  // ---------------------------------------------------------------------------
  Future<void> fetchCategoryReport({
    DateTime? from,
    DateTime? to,
    List<int>? categoryIds,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var endpoint = '/api/Report/category-popularity?';
      final params = <String>[];
      if (from != null) {
        params.add('from=${from.toIso8601String()}');
      }
      if (to != null) {
        params.add('to=${to.toIso8601String()}');
      }
      if (categoryIds != null && categoryIds.isNotEmpty) {
        params.add('categoryIds=${categoryIds.join(',')}');
      }
      endpoint += params.join('&');

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        _categoryReport = data
            .map((e) =>
                CategoryPopularityItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = 'Greska pri ucitavanju izvjestaja (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
