// lib/features/flights/providers/flight_booking_provider.dart
//
// Manages the full flight booking flow:
//   1. Select offer → init booking
//   2. Select seats (optional)
//   3. Confirm booking → Stripe payment
//   4. Show success

import 'package:flutter/foundation.dart';
import '../../../core/services/flight_service.dart';
import '../../../core/network/api_client.dart';

enum BookingStep {
  idle,
  initiating,
  seatSelection,
  confirming,
  success,
  failed
}

class FlightBookingProvider extends ChangeNotifier {
  final FlightService _service = FlightService();

  BookingStep _step = BookingStep.idle;
  String? _error;
  FlightBooking? _currentBooking;
  String? _offerId;
  int _passengerCount = 1;

  BookingStep get step => _step;
  String? get error => _error;
  FlightBooking? get currentBooking => _currentBooking;
  String? get offerId => _offerId;
  int get passengerCount => _passengerCount;
  bool get isLoading =>
      _step == BookingStep.initiating || _step == BookingStep.confirming;

  /// Step 1: Init booking (creates pending booking in backend)
  Future<bool> initBooking({
    required String offerId,
    required List<PassengerInput> passengers,
    String tripType = 'one_way',
  }) async {
    _step = BookingStep.initiating;
    _error = null;
    _offerId = offerId;
    _passengerCount = passengers.length;
    notifyListeners();

    try {
      _currentBooking = await _service.initBooking(
        offerId: offerId,
        passengers: passengers,
        tripType: tripType,
      );
      _step = BookingStep.seatSelection;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Confirm booking with optional selected seat service IDs
  Future<bool> confirmBooking({
    List<String> selectedServiceIds = const [],
  }) async {
    if (_currentBooking == null) return false;

    _step = BookingStep.confirming;
    _error = null;
    notifyListeners();

    try {
      _currentBooking = await _service.confirmBooking(
        _currentBooking!.id,
        selectedServices: selectedServiceIds.map((id) => {'id': id}).toList(),
      );
      _step = BookingStep.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Confirmation failed. Please try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _step = BookingStep.idle;
    _error = null;
    _currentBooking = null;
    _offerId = null;
    _passengerCount = 1;
    notifyListeners();
  }
}
