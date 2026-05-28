// lib/features/flights/services/flight_service.dart
import '../network/api_client.dart';

class FlightService {
  final _client = ApiClient.instance;

  // ────────────────────────────────────────────────────────────────
  // SEARCH
  // ────────────────────────────────────────────────────────────────

  /// POST /flights/search
  /// Returns { offerRequestId, totalOffers, offers: [...] }
  Future<FlightSearchResult> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults        = 1,
    int children      = 0,
    int infants       = 0,
    String cabinClass = 'economy',
    int? maxConnections,
  }) async {
    final body = <String, dynamic>{
      'origin':         origin.toUpperCase(),
      'destination':    destination.toUpperCase(),
      'departureDate':  departureDate, // YYYY-MM-DD
      'adults':         adults,
      'children':       children,
      'infants':        infants,
      'cabinClass':     cabinClass,    // economy | business | first
    };
    if (returnDate     != null) body['returnDate']      = returnDate;
    if (maxConnections != null) body['maxConnections']  = maxConnections;

    final res = await _client.post('/flights/search', body);
    return FlightSearchResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // OFFERS
  // ────────────────────────────────────────────────────────────────

  /// GET /flights/offers?offerRequestId=...&sortBy=...&maxPrice=...
  Future<List<FlightOffer>> listOffers({
    required String offerRequestId,
    String? sortBy,       // total_amount | duration | stops
    double? maxPrice,
    int? maxStops,
    String? airlines,     // comma-separated IATA codes
  }) async {
    final query = <String, String>{
      'offerRequestId': offerRequestId,
      if (sortBy    != null) 'sortBy':   sortBy,
      if (maxPrice  != null) 'maxPrice': maxPrice.toString(),
      if (maxStops  != null) 'maxStops': maxStops.toString(),
      if (airlines  != null) 'airlines': airlines,
    };
    final res = await _client.get('/flights/offers', query: query);
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => FlightOffer.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /flights/offers/:offerId
  Future<FlightOffer> getOffer(String offerId) async {
    final res = await _client.get('/flights/offers/$offerId');
    return FlightOffer.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /flights/offers/:offerId/seat-map
  Future<SeatMapResult> getSeatMap(String offerId) async {
    final res = await _client.get('/flights/offers/$offerId/seat-map');
    return SeatMapResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // BOOKING
  // ────────────────────────────────────────────────────────────────

  /// POST /flights/book  (requires auth)
  /// passengers: List of PassengerInput
  Future<FlightBooking> initBooking({
    required String offerId,
    required List<PassengerInput> passengers,
    String tripType = 'one_way', // one_way | return
  }) async {
    final res = await _client.post('/flights/book', {
      'offerId':    offerId,
      'passengers': passengers.map((p) => p.toJson()).toList(),
      'tripType':   tripType,
    }, auth: true);
    return FlightBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /flights/bookings/:bookingId/confirm  (requires auth)
  Future<FlightBooking> confirmBooking(
    String bookingId, {
    String? paymentProvider,
    List<Map<String, String>> selectedServices = const [],
  }) async {
    final res = await _client.post('/flights/bookings/$bookingId/confirm', {
      if (paymentProvider != null) 'paymentProvider': paymentProvider,
      'selectedServices': selectedServices,
    }, auth: true);
    return FlightBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /flights/bookings  (requires auth)
  Future<List<FlightBooking>> listBookings({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final query = <String, String>{
      'page':  page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final res = await _client.get('/flights/bookings', query: query, auth: true);
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => FlightBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /flights/bookings/:bookingId  (requires auth)
  Future<FlightBooking> getBooking(String bookingId) async {
    final res = await _client.get('/flights/bookings/$bookingId', auth: true);
    return FlightBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /flights/bookings/:bookingId/cancel  (requires auth)
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final res = await _client.post(
      '/flights/bookings/$bookingId/cancel', {}, auth: true);
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  // ────────────────────────────────────────────────────────────────
  // CHANGE
  // ────────────────────────────────────────────────────────────────

  /// POST /flights/bookings/:bookingId/change-request  (requires auth)
  /// slices: list of new slice specs
  Future<Map<String, dynamic>> createChangeRequest(
    String bookingId,
    List<Map<String, dynamic>> slices,
  ) async {
    final res = await _client.post(
      '/flights/bookings/$bookingId/change-request',
      {'slices': slices},
      auth: true,
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  /// GET /flights/bookings/:bookingId/change-offers  (requires auth)
  Future<List<dynamic>> listChangeOffers(
    String bookingId, {
    required String orderChangeRequestId,
  }) async {
    final res = await _client.get(
      '/flights/bookings/$bookingId/change-offers',
      query: {'orderChangeRequestId': orderChangeRequestId},
      auth: true,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// POST /flights/bookings/:bookingId/change/confirm  (requires auth)
  Future<Map<String, dynamic>> confirmChange(
    String bookingId,
    String orderChangeOfferId,
  ) async {
    final res = await _client.post(
      '/flights/bookings/$bookingId/change/confirm',
      {'orderChangeOfferId': orderChangeOfferId},
      auth: true,
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}

// ── Data models ──────────────────────────────────────────────────────

class FlightSearchResult {
  final String offerRequestId;
  final int    totalOffers;
  final List<FlightOffer> offers;

  FlightSearchResult({
    required this.offerRequestId,
    required this.totalOffers,
    required this.offers,
  });

  factory FlightSearchResult.fromJson(Map<String, dynamic> j) {
    final offerList = j['offers'] as List<dynamic>? ?? [];
    return FlightSearchResult(
      offerRequestId: j['offerRequestId'] as String? ?? '',
      totalOffers:    j['totalOffers']    as int?    ?? offerList.length,
      offers: offerList
          .map((e) => FlightOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FlightOffer {
  final String id;
  final double totalAmount;
  final String totalCurrency;
  final List<FlightSlice> slices;
  final List<dynamic>     passengers;
  final String? cabinClass;

  FlightOffer({
    required this.id,
    required this.totalAmount,
    required this.totalCurrency,
    required this.slices,
    required this.passengers,
    this.cabinClass,
  });

  // Convenience getters
  FlightSlice get outbound => slices.first;
  String get airline => outbound.segments.isNotEmpty
      ? (outbound.segments.first['operating_carrier_name'] as String? ?? '')
      : '';
  String get origin      => outbound.origin;
  String get destination => outbound.destination;
  int    get stops       => outbound.segments.length - 1;

  factory FlightOffer.fromJson(Map<String, dynamic> j) {
    final sliceList = j['slices'] as List<dynamic>? ?? [];
    return FlightOffer(
      id:            j['id']             as String? ?? '',
      totalAmount:   double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0,
      totalCurrency: j['total_currency'] as String? ?? 'USD',
      slices:   sliceList.map((s) => FlightSlice.fromJson(s as Map<String, dynamic>)).toList(),
      passengers: j['passengers'] as List<dynamic>? ?? [],
      cabinClass: j['cabin_class'] as String?,
    );
  }
}

class FlightSlice {
  final String origin;
  final String destination;
  final String departureAt;
  final String arrivalAt;
  final String duration;
  final List<Map<String, dynamic>> segments;

  FlightSlice({
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.arrivalAt,
    required this.duration,
    required this.segments,
  });

  factory FlightSlice.fromJson(Map<String, dynamic> j) => FlightSlice(
    origin:      j['origin']      as String? ?? '',
    destination: j['destination'] as String? ?? '',
    departureAt: j['departure_at'] as String? ?? '',
    arrivalAt:   j['arrival_at']   as String? ?? '',
    duration:    j['duration']     as String? ?? '',
    segments:   (j['segments'] as List<dynamic>? ?? [])
        .map((s) => s as Map<String, dynamic>)
        .toList(),
  );
}

class FlightBooking {
  final String id;
  final String status;
  final String? offerId;
  final double? totalAmount;
  final String? currency;
  final List<dynamic> passengers;
  final DateTime createdAt;

  FlightBooking({
    required this.id,
    required this.status,
    this.offerId,
    this.totalAmount,
    this.currency,
    required this.passengers,
    required this.createdAt,
  });

  factory FlightBooking.fromJson(Map<String, dynamic> j) => FlightBooking(
    id:          j['id']     as String? ?? '',
    status:      j['status'] as String? ?? '',
    offerId:     j['offerId'] as String?,
    totalAmount: double.tryParse(j['totalAmount']?.toString() ?? ''),
    currency:    j['currency'] as String?,
    passengers:  j['passengers'] as List<dynamic>? ?? [],
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

class PassengerInput {
  final String type;         // adult | child | infant_without_seat
  final String title;        // mr | ms | mrs | dr
  final String firstName;
  final String lastName;
  final String dateOfBirth;  // YYYY-MM-DD
  final String gender;       // m | f
  final String email;
  final String phone;
  final String? passportNumber;
  final String? issuingCountry;
  final String? passportExpiryDate;

  PassengerInput({
    this.type        = 'adult',
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.gender,
    required this.email,
    required this.phone,
    this.passportNumber,
    this.issuingCountry,
    this.passportExpiryDate,
  });

  Map<String, dynamic> toJson() => {
    'type':        type,
    'title':       title,
    'given_name':  firstName,
    'family_name': lastName,
    'born_on':     dateOfBirth,
    'gender':      gender,
    'email':       email,
    'phone_number': phone,
    if (passportNumber   != null) 'passport_number':   passportNumber,
    if (issuingCountry   != null) 'issuing_country':   issuingCountry,
    if (passportExpiryDate != null) 'passport_expiry_date': passportExpiryDate,
  };
}

class SeatMapResult {
  final bool available;
  final List<dynamic> seatMaps;
  final String? reason;

  SeatMapResult({
    required this.available,
    required this.seatMaps,
    this.reason,
  });

  factory SeatMapResult.fromJson(Map<String, dynamic> j) => SeatMapResult(
    available: j['available'] as bool? ?? false,
    seatMaps:  j['seatMaps']  as List<dynamic>? ?? [],
    reason:    j['reason']    as String?,
  );
}
