import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationDto> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  List<NotificationDto> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<NotificationDto> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Item 18: Start auto-refresh polling
  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      fetchNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchNotifications({bool? isRead}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = '/api/Notification';
      if (isRead != null) url += '?isRead=$isRead';
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paged =
            PagedResult<NotificationDto>.fromJson(data, NotificationDto.fromJson);
        _notifications = paged.items;
        _unreadCount = _notifications.where((n) => !n.isRead).length;

        // Start polling after first successful fetch
        if (_pollingTimer == null) {
          startPolling();
        }
      } else {
        _errorMessage = 'Greska prilikom ucitavanja obavijesti.';
      }
    } catch (e) {
      debugPrint('NotificationProvider.fetchNotifications error: $e');
      _errorMessage = 'Greska prilikom ucitavanja obavijesti.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await ApiClient.put(
        '/api/Notification/$notificationId/read',
        null,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await ApiClient.put('/api/Notification/read-all', null);

      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchNotifications();
      }
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await ApiClient.get('/api/Notification/unread-count');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is int) {
          _unreadCount = data;
        } else if (data is Map<String, dynamic>) {
          _unreadCount = data['count'] as int? ?? data['unreadCount'] as int? ?? 0;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
