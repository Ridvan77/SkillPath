import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/category/category_dto.dart';
import '../services/api_client.dart';

/// Manages the list of course categories.
class CategoryProvider extends ChangeNotifier {
  List<CategoryDto> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryDto> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches all categories from the API.
  ///
  /// Results are cached in memory; subsequent calls will skip the network
  /// request unless [force] is `true`.
  Future<void> fetchCategories({bool force = false}) async {
    if (_categories.isNotEmpty && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/Category');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          _categories = data
              .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is Map<String, dynamic> && data.containsKey('items')) {
          // Handle paginated response format.
          _categories = (data['items'] as List<dynamic>)
              .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } else {
        _error = 'Failed to load categories.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('CategoryProvider.fetchCategories error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the category with the given [id], or `null` if not found.
  CategoryDto? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
