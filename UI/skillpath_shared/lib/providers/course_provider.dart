import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/course/course_detail_dto.dart';
import '../models/course/course_dto.dart';
import '../models/paged_result.dart';
import '../services/api_client.dart';

/// Manages course listing state with pagination, search, and filtering.
class CourseProvider extends ChangeNotifier {
  List<CourseDto> _courses = [];
  List<CourseDto> _featuredCourses = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _error;
  CourseDetailDto? _selectedCourse;

  // Current filter state (retained across pagination calls).
  String? _searchQuery;
  int? _categoryId;
  String? _difficultyLevel;
  int? _selectedDifficulty;
  bool? _isFeatured;
  String? _sortBy;
  bool _sortDescending = false;
  double? _minPrice;
  double? _maxPrice;
  String? _instructorId;

  // Multi-select filters (applied client-side after fetch)
  Set<int> _categoryIds = {};
  Set<int> _difficultyLevels = {};
  Set<String> _instructorIds = {};

  List<CourseDto> get courses => List.unmodifiable(_courses);
  List<CourseDto> get featuredCourses => List.unmodifiable(_featuredCourses);

  /// Returns courses filtered by multi-select filters (client-side).
  List<CourseDto> get filteredCourses {
    if (_categoryIds.isEmpty && _difficultyLevels.isEmpty && _instructorIds.isEmpty &&
        _minPrice == null && _maxPrice == null) {
      return courses;
    }
    return _courses.where((c) {
      if (_categoryIds.isNotEmpty && !_categoryIds.contains(c.categoryId)) return false;
      if (_difficultyLevels.isNotEmpty) {
        final level = _difficultyToInt(c.difficultyLevel);
        if (level != null && !_difficultyLevels.contains(level)) return false;
      }
      if (_instructorIds.isNotEmpty && !_instructorIds.contains(c.instructorId)) return false;
      if (_minPrice != null && c.price < _minPrice!) return false;
      if (_maxPrice != null && c.price > _maxPrice!) return false;
      return true;
    }).toList();
  }

  static int? _difficultyToInt(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return 0;
      case 'intermediate': return 1;
      case 'advanced': return 2;
      default: return null;
    }
  }

  Set<int> get selectedCategoryIds => Set.unmodifiable(_categoryIds);
  Set<int> get selectedDifficultyLevels => Set.unmodifiable(_difficultyLevels);
  Set<String> get selectedInstructorIds => Set.unmodifiable(_instructorIds);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get hasNextPage => _hasMore;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  String? get error => _error;
  String? get errorMessage => _error;
  CourseDetailDto? get selectedCourse => _selectedCourse;
  int? get selectedCategoryId => _categoryId;
  int? get selectedDifficulty => _selectedDifficulty;

  /// Fetches courses from the API with optional filtering parameters.
  ///
  /// When [reset] is `true` (default on first call or filter change), the list
  /// is cleared and fetching starts from page 1. Otherwise the next page is
  /// appended.
  Future<void> fetchCourses({
    String? search,
    int? categoryId,
    String? difficultyLevel,
    bool? isFeatured,
    String? sortBy,
    bool? sortDescending,
    bool reset = false,
    int pageSize = 10,
  }) async {
    // Update filter state when explicitly provided.
    if (search != null) _searchQuery = search.isEmpty ? null : search;
    if (categoryId != null) _categoryId = categoryId == 0 ? null : categoryId;
    if (difficultyLevel != null) {
      _difficultyLevel = difficultyLevel.isEmpty ? null : difficultyLevel;
    }
    if (isFeatured != null) _isFeatured = isFeatured;
    if (sortBy != null) _sortBy = sortBy.isEmpty ? null : sortBy;
    if (sortDescending != null) _sortDescending = sortDescending;

    if (reset) {
      _courses = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore && !reset) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'page': _currentPage.toString(),
        'pageSize': pageSize.toString(),
      };
      if (_searchQuery != null) queryParams['search'] = _searchQuery!;
      if (_categoryId != null) {
        queryParams['categoryId'] = _categoryId.toString();
      }
      if (_difficultyLevel != null) {
        queryParams['difficultyLevel'] = _difficultyLevel!;
      }
      if (_isFeatured != null) {
        queryParams['isFeatured'] = _isFeatured.toString();
      }
      if (_minPrice != null) queryParams['minPrice'] = _minPrice.toString();
      if (_maxPrice != null) queryParams['maxPrice'] = _maxPrice.toString();
      if (_instructorId != null) queryParams['instructorId'] = _instructorId!;
      if (_sortBy != null) queryParams['sortBy'] = _sortBy!;
      if (_sortDescending) queryParams['sortDescending'] = 'true';

      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await ApiClient.get('/api/Course?$queryString');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paged = PagedResult<CourseDto>.fromJson(data, CourseDto.fromJson);

        _courses.addAll(paged.items);
        _hasMore = paged.hasNextPage;
        _totalCount = paged.totalCount;
        _currentPage++;
      } else {
        _error = 'Failed to load courses.';
      }
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('CourseProvider.fetchCourses error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches full course details including schedules.
  Future<CourseDetailDto?> fetchCourseDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/Course/$id');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _selectedCourse = CourseDetailDto.fromJson(data);
        return _selectedCourse;
      }
      _error = 'Failed to load course details.';
      return null;
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('CourseProvider.fetchCourseDetail error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches featured courses from the API.
  Future<void> fetchFeaturedCourses() async {
    try {
      final response =
          await ApiClient.get('/api/Course?isFeatured=true&pageSize=10');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paged =
            PagedResult<CourseDto>.fromJson(data, CourseDto.fromJson);
        _featuredCourses = paged.items;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CourseProvider.fetchFeaturedCourses error: $e');
    }
  }

  /// Sets the search query filter.
  void setSearchQuery(String query) {
    _searchQuery = query.isEmpty ? null : query;
  }

  /// Sets the category filter.
  void setCategoryFilter(int? categoryId) {
    _categoryId = categoryId;
  }

  /// Sets the difficulty filter.
  void setDifficultyFilter(int? difficulty) {
    _selectedDifficulty = difficulty;
    if (difficulty == null) {
      _difficultyLevel = null;
    } else {
      switch (difficulty) {
        case 0:
          _difficultyLevel = 'Pocetni';
          break;
        case 1:
          _difficultyLevel = 'Srednji';
          break;
        case 2:
          _difficultyLevel = 'Napredni';
          break;
        default:
          _difficultyLevel = null;
      }
    }
  }

  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get instructorId => _instructorId;

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
  }

  void setInstructorFilter(String? instructorId) {
    _instructorId = instructorId;
  }

  void setCategoryFilters(Set<int> ids) {
    _categoryIds = Set.from(ids);
  }

  void setDifficultyFilters(Set<int> levels) {
    _difficultyLevels = Set.from(levels);
  }

  void setInstructorFilters(Set<String> ids) {
    _instructorIds = Set.from(ids);
  }

  /// Applies multi-select filters and notifies listeners (no re-fetch needed).
  void applyFilters({
    Set<int>? categoryIds,
    Set<int>? difficultyLevels,
    Set<String>? instructorIds,
    double? minPrice,
    double? maxPrice,
  }) {
    if (categoryIds != null) _categoryIds = Set.from(categoryIds);
    if (difficultyLevels != null) _difficultyLevels = Set.from(difficultyLevels);
    if (instructorIds != null) _instructorIds = Set.from(instructorIds);
    if (minPrice != null) _minPrice = minPrice == 0 ? null : minPrice;
    if (maxPrice != null) _maxPrice = maxPrice == 1000 ? null : maxPrice;
    notifyListeners();
  }

  /// Loads the next page of courses.
  Future<void> nextPage() async {
    if (!_hasMore || _isLoading) return;
    await fetchCourses();
  }

  /// Clears the current list and re-fetches from page 1 with the existing
  /// filter state.
  Future<void> refresh() async {
    await fetchCourses(reset: true);
  }

  /// Resets all filters and the course list.
  void clearFilters() {
    _searchQuery = null;
    _categoryId = null;
    _difficultyLevel = null;
    _selectedDifficulty = null;
    _isFeatured = null;
    _sortBy = null;
    _sortDescending = false;
    _minPrice = null;
    _maxPrice = null;
    _instructorId = null;
    _categoryIds = {};
    _difficultyLevels = {};
    _instructorIds = {};
    _courses = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
