import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_info.dart';
import '../services/api_client.dart';

/// Manages authentication state for the SkillPath application.
///
/// Handles login, registration, logout, token persistence, and automatic
/// user info extraction from JWT claims.
class AuthProvider extends ChangeNotifier {
  UserInfo? _currentUser;
  bool _isLoading = false;
  String? _accessToken;
  String? _error;

  UserInfo? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null && _accessToken != null;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;
  String? get error => _error;

  /// Initializes the provider by loading any persisted token from secure
  /// storage and, if valid, extracting user information from it.
  ///
  /// Call this once during app startup (e.g., in `main()` or a splash screen).
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await ApiClient.getToken();
      if (token != null && token.isNotEmpty) {
        if (!JwtDecoder.isExpired(token)) {
          _accessToken = token;
          _currentUser = _extractUserFromToken(token);
          await _fetchFullProfile();
        } else {
          // Token expired -- clear it.
          await ApiClient.clearTokens();
        }
      }

      // Register for forced-logout events from the API client.
      ApiClient.onAuthenticationExpired = _handleAuthExpired;
    } catch (e) {
      debugPrint('AuthProvider.initialize error: $e');
      await ApiClient.clearTokens();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Authenticates the user with [email] and [password].
  ///
  /// On success, stores the tokens and populates [currentUser].
  /// Returns `true` on success, `false` on failure (check [error]).
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(email: email, password: password);
      final response =
          await ApiClient.post('/api/Auth/login', request.toJson());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);

        await ApiClient.setToken(authResponse.accessToken);
        await ApiClient.setRefreshToken(authResponse.refreshToken);

        _accessToken = authResponse.accessToken;
        _currentUser = _extractUserFromToken(authResponse.accessToken);

        // Fetch full profile (includes phoneNumber, cityId, etc. not in JWT)
        await _fetchFullProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _extractErrorMessage(response.body);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Greska pri povezivanju sa serverom.';
      debugPrint('AuthProvider.login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registers a new user account.
  ///
  /// On success, automatically logs the user in and returns `true`.
  Future<bool> register(RegisterRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.post('/api/Auth/register', request.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Auto-login after successful registration.
        return await login(request.email, request.password);
      } else {
        _error = _extractErrorMessage(response.body);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('AuthProvider.register error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logs the user out by clearing all tokens and resetting state.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiClient.clearTokens();
    } catch (e) {
      debugPrint('AuthProvider.logout error: $e');
    }

    _currentUser = null;
    _accessToken = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Updates the current user's profile.
  ///
  /// Sends a PUT request with the provided fields and refreshes [currentUser]
  /// from the server response.
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    int? cityId,
  }) async {
    if (!isLoggedIn) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (cityId != null) body['cityId'] = cityId;

      final response = await ApiClient.put('/api/Auth/profile', body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        // Preserve roles from current user (PUT profile doesn't return roles)
        final currentRoles = _currentUser?.roles ?? [];
        _currentUser = UserInfo(
          id: data['id'] as String? ?? _currentUser?.id ?? '',
          firstName: data['firstName'] as String? ?? _currentUser?.firstName ?? '',
          lastName: data['lastName'] as String? ?? _currentUser?.lastName ?? '',
          email: data['email'] as String? ?? _currentUser?.email ?? '',
          phoneNumber: data['phoneNumber'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          roles: (data['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? currentRoles,
          isActive: true,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _extractErrorMessage(response.body);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Connection error. Please check your network.';
      debugPrint('AuthProvider.updateProfile error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Decodes the JWT [token] and returns a [UserInfo] populated from claims.
  /// Fetches the full user profile from the API to get fields not in the JWT
  /// (e.g., phoneNumber, cityId, profileImageUrl).
  Future<void> _fetchFullProfile() async {
    try {
      final response = await ApiClient.get('/api/Auth/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final currentRoles = _currentUser?.roles ?? [];
        _currentUser = UserInfo(
          id: data['id'] as String? ?? _currentUser?.id ?? '',
          firstName: data['firstName'] as String? ?? _currentUser?.firstName ?? '',
          lastName: data['lastName'] as String? ?? _currentUser?.lastName ?? '',
          email: data['email'] as String? ?? _currentUser?.email ?? '',
          phoneNumber: data['phoneNumber'] as String?,
          profileImageUrl: data['profileImageUrl'] as String?,
          roles: (data['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? currentRoles,
          isActive: true,
        );
      }
    } catch (e) {
      debugPrint('AuthProvider._fetchFullProfile error: $e');
    }
  }

  UserInfo _extractUserFromToken(String token) {
    final claims = JwtDecoder.decode(token);
    return UserInfo.fromClaims(claims);
  }

  /// Called by [ApiClient] when a 401 response is received.
  void _handleAuthExpired() {
    _currentUser = null;
    _accessToken = null;
    notifyListeners();
  }

  /// Attempts to extract a human-readable error message from the API response
  /// body. Falls back to a generic message on failure.
  String _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;

      // Standard error envelope: { error: { message: "..." } }
      if (data.containsKey('error')) {
        final errorObj = data['error'];
        if (errorObj is Map<String, dynamic>) {
          return errorObj['message'] as String? ?? 'An error occurred.';
        }
        if (errorObj is String) return errorObj;
      }

      // Some endpoints return { message: "..." } directly.
      if (data.containsKey('message')) {
        return data['message'] as String;
      }

      return 'An error occurred. Please try again.';
    } catch (_) {
      return 'An error occurred. Please try again.';
    }
  }
}
