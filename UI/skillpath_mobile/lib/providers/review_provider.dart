import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class ReviewProvider extends ChangeNotifier {
  List<ReviewDto> _courseReviews = [];
  double _averageRating = 0.0;
  int _totalReviewCount = 0;
  Map<int, int> _ratingDistribution = {};
  bool _isLoading = false;
  String? _errorMessage;
  bool _canUserReview = false;

  List<ReviewDto> get courseReviews => _courseReviews;
  double get averageRating => _averageRating;
  int get totalReviewCount => _totalReviewCount;
  Map<int, int> get ratingDistribution => _ratingDistribution;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canUserReview => _canUserReview;

  Future<void> fetchCourseReviews(String courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/Review/course/$courseId');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _averageRating = (json['averageRating'] as num?)?.toDouble() ?? 0.0;
        _totalReviewCount = json['totalCount'] as int? ?? 0;

        final distRaw = json['ratingDistribution'] as Map<String, dynamic>?;
        _ratingDistribution = {};
        if (distRaw != null) {
          for (final entry in distRaw.entries) {
            _ratingDistribution[int.parse(entry.key)] =
                entry.value as int? ?? 0;
          }
        }

        final reviewsJson = json['reviews'] as Map<String, dynamic>?;
        if (reviewsJson != null) {
          final pagedResult =
              PagedResult.fromJson(reviewsJson, ReviewDto.fromJson);
          _courseReviews = pagedResult.items;
        } else {
          _courseReviews = [];
        }
      } else {
        _errorMessage = 'Greska prilikom ucitavanja recenzija.';
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom ucitavanja recenzija: $e';
      debugPrint('ReviewProvider.fetchCourseReviews error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReview(
      String courseId, int rating, String comment) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/Review/course/$courseId',
        {'rating': rating, 'comment': comment},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCourseReviews(courseId);
        return true;
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        _errorMessage = body['message'] as String? ??
            'Greska prilikom kreiranja recenzije.';
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom kreiranja recenzije.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> toggleHelpful(String reviewId) async {
    try {
      final response =
          await ApiClient.post('/api/Review/$reviewId/helpful', null);

      if (response.statusCode == 200) {
        final index = _courseReviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          // Refresh reviews to get updated helpful counts
          final courseId = _courseReviews[index].courseId;
          await fetchCourseReviews(courseId);
        }
      }
    } catch (_) {
      // Silent fail
    }
  }

  Future<bool> canReview(String courseId) async {
    try {
      final response =
          await ApiClient.get('/api/Review/course/$courseId/can-review');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _canUserReview = json['canReview'] as bool? ?? false;
        notifyListeners();
        return _canUserReview;
      }
    } catch (_) {
      // Silent fail
    }
    _canUserReview = false;
    notifyListeners();
    return false;
  }

  void clearReviews() {
    _courseReviews = [];
    _averageRating = 0.0;
    _totalReviewCount = 0;
    _ratingDistribution = {};
    _canUserReview = false;
  }
}
