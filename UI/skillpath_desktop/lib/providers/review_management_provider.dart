import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class ReviewItem {
  final String id;
  final String userId;
  final String userFullName;
  final String courseId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isVisible;
  final int helpfulCount;

  ReviewItem({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.courseId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVisible,
    required this.helpfulCount,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] as String? ?? '',
      userFullName: json['userFullName'] as String? ?? '',
      courseId: json['courseId']?.toString() ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVisible: json['isVisible'] as bool? ?? true,
      helpfulCount: json['helpfulCount'] as int? ?? 0,
    );
  }
}

class ReviewManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<ReviewItem> _reviews = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;
  String? _courseIdFilter;

  // Stable stats (fetched once across all courses)
  bool _statsLoaded = false;
  int _totalVisible = 0;
  int _totalHidden = 0;
  int _totalAllReviews = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ReviewItem> get reviews => _reviews;
  int get totalCount => _totalAllReviews;
  int get currentPage => _currentPage;
  int get totalPages => (_totalCount / _pageSize).ceil();
  int get visibleCount => _totalVisible;
  int get hiddenCount => _totalHidden;

  // ---------------------------------------------------------------------------
  // Fetch reviews for a specific course (admin view fetches all courses)
  // ---------------------------------------------------------------------------
  Future<void> fetchReviews({int? page, String? courseId}) async {
    if (page != null) _currentPage = page;
    if (courseId != null) _courseIdFilter = courseId;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // The API exposes reviews per course. For admin overview, we fetch
      // courses first and then aggregate. For simplicity, we rely on
      // the course-level review endpoint if a course is selected.
      // Otherwise, we get all courses and fetch reviews for each.
      if (_courseIdFilter != null && _courseIdFilter!.isNotEmpty) {
        await _fetchCourseReviews(_courseIdFilter!);
      } else {
        await _fetchAllReviews();
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchCourseReviews(String courseId) async {
    final response = await ApiClient.get(
      '/api/Review/course/$courseId?page=$_currentPage&pageSize=$_pageSize&includeHidden=true',
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reviewsData = data['reviews'] as Map<String, dynamic>?;
      if (reviewsData != null) {
        _reviews = (reviewsData['items'] as List<dynamic>?)
                ?.map(
                    (e) => ReviewItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = reviewsData['totalCount'] as int? ?? 0;
      }
      await _computeStats();
    }
  }

  Future<void> _fetchAllReviews() async {
    // Fetch courses to iterate their reviews
    final coursesResponse =
        await ApiClient.get('/api/Course?page=1&pageSize=100');
    if (coursesResponse.statusCode == 200) {
      final coursesData =
          jsonDecode(coursesResponse.body) as Map<String, dynamic>;
      final courseItems = coursesData['items'] as List<dynamic>? ?? [];

      List<ReviewItem> allReviews = [];
      for (final course in courseItems) {
        final cid = course['id']?.toString() ?? '';
        if (cid.isEmpty) continue;

        final reviewResponse = await ApiClient.get(
          '/api/Review/course/$cid?page=1&pageSize=100&includeHidden=true',
        );
        if (reviewResponse.statusCode == 200) {
          final rData =
              jsonDecode(reviewResponse.body) as Map<String, dynamic>;
          final reviewsData = rData['reviews'] as Map<String, dynamic>?;
          if (reviewsData != null) {
            final items = (reviewsData['items'] as List<dynamic>?)
                    ?.map((e) =>
                        ReviewItem.fromJson(e as Map<String, dynamic>))
                    .toList() ??
                [];
            allReviews.addAll(items);
          }
        }
      }

      allReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _totalCount = allReviews.length;

      final start = (_currentPage - 1) * _pageSize;
      final end =
          start + _pageSize > allReviews.length ? allReviews.length : start + _pageSize;
      _reviews = allReviews.sublist(
        start.clamp(0, allReviews.length),
        end.clamp(0, allReviews.length),
      );
      await _computeStats();
    }
  }

  Future<void> _computeStats() async {
    if (_statsLoaded) return;

    try {
      final coursesResponse =
          await ApiClient.get('/api/Course?page=1&pageSize=100');
      if (coursesResponse.statusCode == 200) {
        final coursesData =
            jsonDecode(coursesResponse.body) as Map<String, dynamic>;
        final courseItems = coursesData['items'] as List<dynamic>? ?? [];

        int visible = 0;
        int hidden = 0;
        int total = 0;

        for (final course in courseItems) {
          final cid = course['id']?.toString() ?? '';
          if (cid.isEmpty) continue;

          final reviewResponse = await ApiClient.get(
            '/api/Review/course/$cid?page=1&pageSize=100&includeHidden=true',
          );
          if (reviewResponse.statusCode == 200) {
            final rData =
                jsonDecode(reviewResponse.body) as Map<String, dynamic>;
            final reviewsData = rData['reviews'] as Map<String, dynamic>?;
            if (reviewsData != null) {
              final items = (reviewsData['items'] as List<dynamic>?) ?? [];
              for (final item in items) {
                total++;
                final isVisible = (item as Map<String, dynamic>)['isVisible'] as bool? ?? true;
                if (isVisible) {
                  visible++;
                } else {
                  hidden++;
                }
              }
            }
          }
        }

        _totalVisible = visible;
        _totalHidden = hidden;
        _totalAllReviews = total;
        _statsLoaded = true;
      }
    } catch (_) {}
  }

  void refreshStats() {
    _statsLoaded = false;
  }

  // ---------------------------------------------------------------------------
  // Toggle visibility
  // ---------------------------------------------------------------------------
  Future<bool> toggleVisibility(String reviewId) async {
    try {
      final response =
          await ApiClient.put('/api/Review/$reviewId/visibility', null);
      if (response.statusCode == 200) {
        refreshStats();
        await fetchReviews();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Delete review
  // ---------------------------------------------------------------------------
  Future<bool> deleteReview(String reviewId) async {
    try {
      final response = await ApiClient.delete('/api/Review/$reviewId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _reviews.removeWhere((r) => r.id == reviewId);
        _totalCount--;
        refreshStats();
        await _computeStats();
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  void clearCourseFilter() {
    _courseIdFilter = null;
    fetchReviews(page: 1);
  }
}
