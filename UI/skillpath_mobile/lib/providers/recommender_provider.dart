import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class RecommendationDto {
  final String courseId;
  final String title;
  final String shortDescription;
  final double price;
  final String difficultyLevel;
  final String? imageUrl;
  final String categoryName;
  final String instructorName;
  final double averageRating;
  final int reviewCount;
  final double recommendationScore;
  final String explanation;

  RecommendationDto({
    required this.courseId,
    required this.title,
    required this.shortDescription,
    required this.price,
    required this.difficultyLevel,
    this.imageUrl,
    required this.categoryName,
    required this.instructorName,
    required this.averageRating,
    required this.reviewCount,
    required this.recommendationScore,
    required this.explanation,
  });

  factory RecommendationDto.fromJson(Map<String, dynamic> json) {
    return RecommendationDto(
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortDescription: json['shortDescription'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      difficultyLevel: json['difficultyLevel'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      categoryName: json['categoryName'] as String? ?? '',
      instructorName: json['instructorName'] as String? ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      recommendationScore:
          (json['recommendationScore'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class RecommenderProvider extends ChangeNotifier {
  List<RecommendationDto> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecommendationDto> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecommendations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/recommender');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            jsonDecode(response.body) as List<dynamic>;
        _recommendations = jsonList
            .map((e) =>
                RecommendationDto.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = 'Greska prilikom ucitavanja preporuka.';
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom ucitavanja preporuka.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> trackCourseView(String courseId) async {
    try {
      await ApiClient.post('/api/recommender/track-view', {
        'courseId': courseId,
      });
    } catch (_) {
      // Silent fail - tracking should not interrupt UX
    }
  }
}
