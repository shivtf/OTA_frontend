// lib/core/services/flight_change_service.dart
//
// HTTP client for the 3-step flight change request flow.
// Mirrors the patterns in FlightService / ApiClient.

import '../network/api_client.dart';
import '../../features/flights/change_request/models/flight_change_model.dart';

export '../../features/flights/change_request/models/flight_change_model.dart';

class FlightChangeService {
  final _client = ApiClient.instance;

  // ── Step 0: GET /flights/bookings/:bookingId ─────────────────────────────
  // Returns the raw booking map; caller reads data.slices[0].id
  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    final res =
    await _client.get('/flights/bookings/$bookingId', auth: true);
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  // ── Step 1: POST /flights/bookings/:bookingId/change-request ─────────────
  Future<ChangeRequest> createChangeRequest({
    required String bookingId,
    required List<ChangeRequestSliceInput> slices,
  }) async {
    final res = await _client.post(
      '/flights/bookings/$bookingId/change-request',
      {'slices': slices.map((s) => s.toJson()).toList()},
      auth: true,
    );
    return ChangeRequest.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── Step 2: GET /flights/bookings/:bookingId/change-offers ───────────────
  Future<List<ChangeOffer>> listChangeOffers({
    required String bookingId,
    required String orderChangeRequestId,
  }) async {
    final res = await _client.get(
      '/flights/bookings/$bookingId/change-offers',
      query: {'orderChangeRequestId': orderChangeRequestId},
      auth: true,
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ChangeOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Step 3: POST /flights/bookings/:bookingId/change/confirm ─────────────
  Future<ConfirmedChange> confirmChange({
    required String bookingId,
    required String orderChangeOfferId,
  }) async {
    final res = await _client.post(
      '/flights/bookings/$bookingId/change/confirm',
      {'orderChangeOfferId': orderChangeOfferId},
      auth: true,
    );
    return ConfirmedChange.fromJson(res['data'] as Map<String, dynamic>);
  }
}


