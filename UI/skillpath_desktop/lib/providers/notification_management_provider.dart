import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class NotificationItem {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String type;
  final String targetGroup;
  final int recipientCount;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.type,
    required this.targetGroup,
    required this.recipientCount,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      type: json['type'] as String? ?? '',
      targetGroup: json['targetGroup'] as String? ?? 'all',
      recipientCount: json['recipientCount'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse('${json['scheduledAt']}Z')
          : null,
      sentAt: json['sentAt'] != null
          ? DateTime.parse('${json['sentAt']}Z')
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse('${json['createdAt']}Z')
          : DateTime.now(),
    );
  }
}

class NotificationManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<NotificationItem> _notifications = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 20;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<NotificationItem> get notifications => _notifications;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get totalPages => (_totalCount / _pageSize).ceil();

  // ---------------------------------------------------------------------------
  // Fetch notifications
  // ---------------------------------------------------------------------------
  Future<void> fetchNotifications({int? page}) async {
    if (page != null) _currentPage = page;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint =
          '/api/Notification/admin?page=$_currentPage&pageSize=$_pageSize';
      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _notifications = (data['items'] as List<dynamic>?)
                ?.map((e) =>
                    NotificationItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;
      } else {
        _error =
            'Greska pri ucitavanju obavjestenja (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Create notification
  // ---------------------------------------------------------------------------
  Future<bool> createNotification({
    required String title,
    required String content,
    required int type,
    String? userId,
    String? targetGroup,
    String? imageUrl,
    DateTime? scheduledAt,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'title': title,
        'content': content,
        'type': type,
      };
      if (userId != null && userId.isNotEmpty) body['userId'] = userId;
      if (targetGroup != null && targetGroup.isNotEmpty) {
        body['targetGroup'] = targetGroup;
      }
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['imageUrl'] = imageUrl;
      }
      if (scheduledAt != null) {
        // Compute target UTC time using delay from now (avoids all timezone issues)
        final delay = scheduledAt.difference(DateTime.now());
        final utcTarget = DateTime.now().toUtc().add(delay);
        final isoString = utcTarget.toIso8601String();
        body['scheduledAt'] = isoString;
        debugPrint('[NOTIF] Local scheduled: $scheduledAt');
        debugPrint('[NOTIF] Delay from now: $delay');
        debugPrint('[NOTIF] UTC target: $isoString');
      }

      final response = await ApiClient.post('/api/Notification', body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        await fetchNotifications();
        return true;
      } else {
        _error =
            'Greska pri kreiranju obavjestenja (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ---------------------------------------------------------------------------
  // Reschedule notification
  // ---------------------------------------------------------------------------
  Future<bool> rescheduleNotification(String id, DateTime scheduledAt) async {
    try {
      final delay = scheduledAt.difference(DateTime.now());
      final utcTarget = DateTime.now().toUtc().add(delay);
      final isoString = utcTarget.toIso8601String();
      debugPrint('[NOTIF] Reschedule UTC target: $isoString');
      final response = await ApiClient.put(
        '/api/Notification/admin/$id/schedule',
        {'scheduledAt': isoString},
      );
      if (response.statusCode == 200) {
        await fetchNotifications();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Delete notification
  // ---------------------------------------------------------------------------
  Future<bool> deleteNotification(String id) async {
    try {
      final response = await ApiClient.delete('/api/Notification/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _notifications.removeWhere((n) => n.id == id);
        _totalCount--;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }
}
