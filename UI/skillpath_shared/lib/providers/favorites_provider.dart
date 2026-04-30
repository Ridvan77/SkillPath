import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/course/course_dto.dart';
import '../models/paged_result.dart';
import '../services/api_client.dart';

/// Manages the current user's favorite courses.
class FavoritesProvider extends ChangeNotifier {
  List<CourseDto> _favorites = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _error;

  List<CourseDto> get favorites => List.unmodifiable(_favorites);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the current user's favorite courses.
  ///
  /// Replaces the existing list entirely.
  Future<void> fetchFavorites({int page = 1, int pageSize = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.get('/api/Favorite?page=$page&pageSize=$pageSize');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paged = PagedResult<CourseDto>.fromJson(data, CourseDto.fromJson);

        _favorites = paged.items;
        _favoriteIds
          ..clear()
          ..addAll(paged.items.map((c) => c.id));
      } else {
        _error = 'Failed to load favorites.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('FavoritesProvider.fetchFavorites error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles the favorite status of the course with [courseId].
  ///
  /// Returns the new favorite status (`true` = now a favorite).
  Future<bool> toggleFavorite(String courseId) async {
    try {
      final response = await ApiClient.post('/api/Favorite/$courseId', null);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final isFav = data['isFavorite'] as bool? ?? false;

        if (isFav) {
          _favoriteIds.add(courseId);
        } else {
          _favoriteIds.remove(courseId);
          _favorites.removeWhere((c) => c.id == courseId);
        }

        notifyListeners();
        return isFav;
      }
      return isFavorite(courseId);
    } catch (e) {
      debugPrint('FavoritesProvider.toggleFavorite error: $e');
      return isFavorite(courseId);
    }
  }

  /// Returns `true` if the course with [courseId] is in the user's favorites.
  bool isFavorite(String courseId) {
    return _favoriteIds.contains(courseId);
  }

  /// Clears all local favorite state (e.g., on logout).
  void clear() {
    _favorites = [];
    _favoriteIds.clear();
    _error = null;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
