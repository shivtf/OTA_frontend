// lib/core/services/flight_service.dart
//
// Contains ONLY the FlightService HTTP client.
// All models (FlightOffer, FlightSegment, PassengerInput, etc.)
// live in features/flights/models/flight_offer.dart to avoid
// duplicate class definitions across libraries.

import '../network/api_client.dart';
import '../../features/flights/models/flight_offer.dart';

export '../../features/flights/models/flight_offer.dart';

class FlightService {
  final _client = ApiClient.instance;

  // ── POST /flights/search ─────────────────────────────────────────────────
  Future<FlightSearchResult> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults = 1,
    int children = 0,
    int infants = 0,
    String cabinClass = 'economy',
    int? maxConnections,
    double? maxPrice,
    String? sortBy,
  }) async {
    final body = <String, dynamic>{
      'origin': origin.toUpperCase(),
      'destination': destination.toUpperCase(),
      'departureDate': departureDate,
      'adults': adults,
      'children': children,
      'infants': infants,
      'cabinClass': cabinClass,
    };
    if (returnDate != null) body['returnDate'] = returnDate;
    if (maxConnections != null) body['maxConnections'] = maxConnections;
    if (maxPrice != null) body['maxPrice'] = maxPrice;
    if (sortBy != null) body['sortBy'] = sortBy;

    final res = await _client.post('/flights/search', body);
    return FlightSearchResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /flights/offers ──────────────────────────────────────────────────
  Future<OffersResult> listOffers({
    required String offerRequestId,
    String? sortBy,
    double? maxPrice,
    int? maxStops,
    String? airlines,
  }) async {
    final query = <String, String>{
      'offerRequestId': offerRequestId,
      if (sortBy != null) 'sortBy': sortBy,
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (maxStops != null) 'maxStops': maxStops.toString(),
      if (airlines != null) 'airlines': airlines,
    };
    final res = await _client.get('/flights/offers', query: query);
    return OffersResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /flights/offers/:offerId ─────────────────────────────────────────
  Future<FlightOffer> getOffer(String offerId) async {
    final res = await _client.get('/flights/offers/$offerId');
    return FlightOffer.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /flights/offers/:offerId/seat-map ────────────────────────────────
  Future<SeatMapResult> getSeatMap(String offerId) async {
    final res = await _client.get('/flights/offers/$offerId/seat-map');
    return SeatMapResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /flights/book ───────────────────────────────────────────────────
  Future<FlightBooking> initBooking({
    required String offerId,
    required List<PassengerInput> passengers,
    String tripType = 'ONE_WAY',
  }) async {
    final res = await _client.post(
        '/flights/book',
        {
          'offerId': offerId,
          'tripType': tripType,
          'passengers': passengers.map((p) => p.toJson()).toList(),
        },
        auth: true);
    return FlightBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /flights/bookings ────────────────────────────────────────────────
  Future<List<FlightBookingListItem>> listBookings({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final res =
        await _client.get('/flights/bookings', query: query, auth: true);
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => FlightBookingListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /flights/bookings/:bookingId/cancel ─────────────────────────────
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final res = await _client.post('/flights/bookings/$bookingId/cancel', {},
        auth: true);
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}
