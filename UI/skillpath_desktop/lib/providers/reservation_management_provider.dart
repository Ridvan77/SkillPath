import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class ReservationItem {
  final String id;
  final String reservationCode;
  final String userId;
  final String userFullName;
  final String courseScheduleId;
  final String courseName;
  final String? courseImageUrl;
  final String instructorName;
  final String scheduleDay;
  final String scheduleTime;
  final String status;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final double totalAmount;
  final String? stripePaymentIntentId;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  ReservationItem({
    required this.id,
    required this.reservationCode,
    required this.userId,
    required this.userFullName,
    required this.courseScheduleId,
    required this.courseName,
    this.courseImageUrl,
    required this.instructorName,
    required this.scheduleDay,
    required this.scheduleTime,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.totalAmount,
    this.stripePaymentIntentId,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  String get fullName => '$firstName $lastName';

  factory ReservationItem.fromJson(Map<String, dynamic> json) {
    return ReservationItem(
      id: json['id']?.toString() ?? '',
      reservationCode: json['reservationCode'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userFullName: json['userFullName'] as String? ?? '',
      courseScheduleId: json['courseScheduleId']?.toString() ?? '',
      courseName: json['courseName'] as String? ?? '',
      courseImageUrl: json['courseImageUrl'] as String?,
      instructorName: json['instructorName'] as String? ?? '',
      scheduleDay: json['scheduleDay'] as String? ?? '',
      scheduleTime: json['scheduleTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      stripePaymentIntentId: json['stripePaymentIntentId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}

class ReservationManagementProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  List<ReservationItem> _reservations = [];
  int _totalCount = 0;
  int _currentPage = 1;
  int _pageSize = 10;
  String _searchQuery = '';
  String? _statusFilter;

  // Stats
  int _totalReservations = 0;
  int _activeCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ReservationItem> get reservations => _reservations;
  int get totalCount => _totalCount;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;

  int get totalReservations => _totalReservations;
  int get activeCount => _activeCount;
  int get completedCount => _completedCount;
  int get cancelledCount => _cancelledCount;

  // ---------------------------------------------------------------------------
  // Fetch all reservations (paged)
  // ---------------------------------------------------------------------------
  bool _statsLoaded = false;

  Future<void> fetchReservations({
    int? page,
    String? search,
    String? status,
  }) async {
    if (page != null) _currentPage = page;
    if (search != null) _searchQuery = search;
    _statusFilter = status;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var endpoint =
          '/api/Reservation?page=$_currentPage&pageSize=$_pageSize';
      if (_searchQuery.isNotEmpty) {
        endpoint += '&search=${Uri.encodeComponent(_searchQuery)}';
      }
      if (_statusFilter != null && _statusFilter!.isNotEmpty) {
        endpoint += '&status=$_statusFilter';
      }

      final response = await ApiClient.get(endpoint);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _reservations = (data['items'] as List<dynamic>?)
                ?.map((e) =>
                    ReservationItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _totalCount = data['totalCount'] as int? ?? 0;

        if (!_statsLoaded) {
          await _fetchStats();
        }
      } else {
        _error =
            'Greska pri ucitavanju rezervacija (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchStats() async {
    try {
      // Fetch counts for each status separately using pageSize=1 to get totalCount
      final allRes = await ApiClient.get('/api/Reservation?page=1&pageSize=1');
      if (allRes.statusCode == 200) {
        final data = jsonDecode(allRes.body) as Map<String, dynamic>;
        _totalReservations = data['totalCount'] as int? ?? 0;
      }

      final activeRes = await ApiClient.get('/api/Reservation?page=1&pageSize=1&status=1');
      if (activeRes.statusCode == 200) {
        final data = jsonDecode(activeRes.body) as Map<String, dynamic>;
        _activeCount = data['totalCount'] as int? ?? 0;
      }
      // Also count pending as active
      final pendingRes = await ApiClient.get('/api/Reservation?page=1&pageSize=1&status=0');
      if (pendingRes.statusCode == 200) {
        final data = jsonDecode(pendingRes.body) as Map<String, dynamic>;
        _activeCount += data['totalCount'] as int? ?? 0;
      }

      final completedRes = await ApiClient.get('/api/Reservation?page=1&pageSize=1&status=2');
      if (completedRes.statusCode == 200) {
        final data = jsonDecode(completedRes.body) as Map<String, dynamic>;
        _completedCount = data['totalCount'] as int? ?? 0;
      }

      final cancelledRes = await ApiClient.get('/api/Reservation?page=1&pageSize=1&status=3');
      if (cancelledRes.statusCode == 200) {
        final data = jsonDecode(cancelledRes.body) as Map<String, dynamic>;
        _cancelledCount = data['totalCount'] as int? ?? 0;
      }

      _statsLoaded = true;
    } catch (_) {}
  }

  void refreshStats() {
    _statsLoaded = false;
  }

  void clearStatusFilter() {
    _statusFilter = null;
    fetchReservations(page: 1);
  }

  // ---------------------------------------------------------------------------
  // Confirm reservation
  // ---------------------------------------------------------------------------
  Future<bool> confirmReservation(
      String id, String stripePaymentIntentId) async {
    try {
      final response = await ApiClient.post(
        '/api/Reservation/$id/confirm',
        {'stripePaymentIntentId': stripePaymentIntentId},
      );
      if (response.statusCode == 200) {
        refreshStats();
        await fetchReservations();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Cancel reservation
  // ---------------------------------------------------------------------------
  Future<bool> cancelReservation(String id, String reason) async {
    try {
      final response = await ApiClient.post(
        '/api/Reservation/$id/cancel',
        {'reason': reason},
      );
      if (response.statusCode == 200) {
        refreshStats();
        await fetchReservations();
        return true;
      }
    } catch (e) {
      _error = 'Greska: $e';
    }
    return false;
  }
}
