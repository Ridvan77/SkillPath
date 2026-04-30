import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class DashboardReservation {
  final String id;
  final String reservationCode;
  final String firstName;
  final String lastName;
  final String email;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  DashboardReservation({
    required this.id,
    required this.reservationCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory DashboardReservation.fromJson(Map<String, dynamic> json) {
    return DashboardReservation(
      id: json['id']?.toString() ?? '',
      reservationCode: json['reservationCode'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class AdminProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  int _totalCourses = 0;
  int _activeStudents = 0;
  double _totalRevenue = 0;
  double _averageRating = 0;
  List<DashboardReservation> _recentReservations = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCourses => _totalCourses;
  int get activeStudents => _activeStudents;
  double get totalRevenue => _totalRevenue;
  double get averageRating => _averageRating;
  List<DashboardReservation> get recentReservations => _recentReservations;

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/api/Dashboard/stats');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _totalCourses = data['totalCourses'] as int? ?? 0;
        _activeStudents = data['activeStudents'] as int? ?? 0;
        _totalRevenue = (data['totalRevenue'] as num?)?.toDouble() ?? 0;
        _averageRating = (data['averageRating'] as num?)?.toDouble() ?? 0;
        _recentReservations = (data['recentReservations'] as List<dynamic>?)
                ?.map((e) =>
                    DashboardReservation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        _error = 'Greska pri ucitavanju statistike (${response.statusCode})';
      }
    } catch (e) {
      _error = 'Greska: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
