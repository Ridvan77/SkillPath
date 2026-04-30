import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Callback type for handling authentication state changes (e.g., forced logout on 401).
typedef AuthStateCallback = void Function();

/// Static API client for communicating with the SkillPath backend.
///
/// Handles JWT token management, platform-aware base URL resolution,
/// and automatic 401 handling with token clearing.
class ApiClient {
  static const String _tokenKey = 'skillpath_access_token';
  static const String _refreshTokenKey = 'skillpath_refresh_token';

  /// Optional callback invoked when a 401 response is received and
  /// the stored token is cleared. Use this to trigger a logout flow
  /// in the UI layer.
  static AuthStateCallback? onAuthenticationExpired;

  /// Returns the base URL for the API, resolved based on the current platform.
  ///
  /// Priority:
  /// 1. Compile-time override via `--dart-define=API_BASE_URL=...`
  /// 2. Platform-specific defaults (Android emulator, iOS simulator, desktop)
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      return 'http://localhost:8080';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    if (Platform.isIOS) {
      return 'http://127.0.0.1:8080';
    }

    // macOS, Windows, Linux
    return 'http://localhost:8080';
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Retrieves the stored access token, or `null` if none exists.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Persists the access token.
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieves the stored refresh token, or `null` if none exists.
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// Persists the refresh token.
  static Future<void> setRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  /// Removes all stored tokens.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  /// Builds standard headers including JSON content type and, when available,
  /// the Bearer authorization header.
  static Future<Map<String, String>> _buildHeaders({String? token}) async {
    final resolvedToken = token ?? await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $resolvedToken';
    }
    return headers;
  }

  /// Inspects the response for a 401 status and, if found, clears the stored
  /// tokens and notifies listeners.
  static Future<void> _handleUnauthorized(http.Response response) async {
    if (response.statusCode == 401) {
      await clearTokens();
      onAuthenticationExpired?.call();
    }
  }

  /// Constructs the full URI for the given [endpoint].
  ///
  /// If [endpoint] already starts with `http`, it is used as-is; otherwise
  /// it is appended to [baseUrl].
  static Uri _buildUri(String endpoint) {
    if (endpoint.startsWith('http')) {
      return Uri.parse(endpoint);
    }
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$path');
  }

  // ---------------------------------------------------------------------------
  // Public HTTP methods
  // ---------------------------------------------------------------------------

  /// Sends a GET request to [endpoint].
  static Future<http.Response> get(String endpoint, {String? token}) async {
    final headers = await _buildHeaders(token: token);
    final response = await http.get(_buildUri(endpoint), headers: headers);
    await _handleUnauthorized(response);
    return response;
  }

  /// Sends a POST request to [endpoint] with an optional JSON [body].
  static Future<http.Response> post(
    String endpoint,
    dynamic body, {
    String? token,
  }) async {
    final headers = await _buildHeaders(token: token);
    final response = await http.post(
      _buildUri(endpoint),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    await _handleUnauthorized(response);
    return response;
  }

  /// Sends a PUT request to [endpoint] with an optional JSON [body].
  static Future<http.Response> put(
    String endpoint,
    dynamic body, {
    String? token,
  }) async {
    final headers = await _buildHeaders(token: token);
    final response = await http.put(
      _buildUri(endpoint),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    await _handleUnauthorized(response);
    return response;
  }

  /// Sends a multipart POST request to upload a file.
  static Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    String? token,
  }) async {
    final resolvedToken = token ?? await getToken();
    final request = http.MultipartRequest('POST', _buildUri(endpoint));
    if (resolvedToken != null && resolvedToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $resolvedToken';
    }
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    return await request.send();
  }

  /// Sends a DELETE request to [endpoint].
  static Future<http.Response> delete(String endpoint, {String? token}) async {
    final headers = await _buildHeaders(token: token);
    final response = await http.delete(_buildUri(endpoint), headers: headers);
    await _handleUnauthorized(response);
    return response;
  }
}
