import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class ReservationProvider extends ChangeNotifier {
  List<ReservationDto> _activeReservations = [];
  List<ReservationDto> _completedReservations = [];
  List<ReservationDto> _cancelledReservations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReservationDto> get activeReservations => _activeReservations;
  List<ReservationDto> get completedReservations => _completedReservations;
  List<ReservationDto> get cancelledReservations => _cancelledReservations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserReservations({String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var url = '/api/Reservation/my';
      if (status != null) url += '?status=$status';
      final response = await ApiClient.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final paged = PagedResult<ReservationDto>.fromJson(
            data, ReservationDto.fromJson);
        final all = paged.items;

        _activeReservations = all
            .where((r) =>
                r.status == 'Confirmed' ||
                r.status == 'Pending' ||
                r.status == 'Active')
            .toList();
        _completedReservations =
            all.where((r) => r.status == 'Completed').toList();
        _cancelledReservations =
            all.where((r) => r.status == 'Cancelled').toList();
      } else {
        _errorMessage = 'Greska prilikom ucitavanja rezervacija.';
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom ucitavanja rezervacija.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ReservationDto?> createReservation(
      Map<String, dynamic> request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.post('/api/Reservation', request);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final reservation = ReservationDto.fromJson(json);

        _isLoading = false;
        notifyListeners();
        return reservation;
      } else {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          _errorMessage = body['error']?['message'] as String? ??
              body['message'] as String? ??
              'Greska prilikom kreiranja rezervacije.';
        } catch (_) {
          _errorMessage = 'Greska prilikom kreiranja rezervacije.';
        }
      }
    } catch (e) {
      _errorMessage = 'Greska pri povezivanju: $e';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<bool> confirmReservation(
      String reservationId, String paymentIntentId) async {
    try {
      final response = await ApiClient.post(
        '/api/Reservation/$reservationId/confirm',
        {'stripePaymentIntentId': paymentIntentId},
      );

      if (response.statusCode == 200) {
        await fetchUserReservations();
        return true;
      } else {
        _errorMessage = 'Greska prilikom potvrde rezervacije.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom potvrde rezervacije.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation(String reservationId, String reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiClient.post(
        '/api/Reservation/$reservationId/cancel',
        {'reason': reason},
      );

      if (response.statusCode == 200) {
        await fetchUserReservations();
        return true;
      } else {
        _errorMessage = 'Greska prilikom otkazivanja rezervacije.';
      }
    } catch (e) {
      _errorMessage = 'Greska prilikom otkazivanja rezervacije.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
