import '../network/api_client.dart';

class FlightService {
  final _client = ApiClient.instance;

  // ── POST /flights/search ─────────────────────────────────────────────────
  /// Returns { offerRequestId, totalOffers, slices, cabinClass, filters }
  Future<FlightSearchResult> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults = 1,
    int children = 0,
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
    String? sortBy, // total_amount | duration | stops
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
  /// Returns { bookingId, bookingRef, pricing, amount, currency, conditions, ... }
  Future<FlightBooking> initBooking({
    required String offerId,
    required List<PassengerInput> passengers,
    String tripType = 'ONE_WAY', // ONE_WAY | ROUND_TRIP
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

// ── Data models ──────────────────────────────────────────────────────────────

class FlightSearchResult {
  final String offerRequestId;
  final int totalOffers;

  FlightSearchResult({
    required this.offerRequestId,
    required this.totalOffers,
  });

  factory FlightSearchResult.fromJson(Map<String, dynamic> j) =>
      FlightSearchResult(
        offerRequestId: j['offerRequestId'] as String? ?? '',
        totalOffers: j['totalOffers'] as int? ?? 0,
      );
}

class OffersResult {
  final int totalOffers;
  final List<FlightOffer> offers;

  OffersResult({required this.totalOffers, required this.offers});

  factory OffersResult.fromJson(Map<String, dynamic> j) {
    final list = j['offers'] as List<dynamic>? ?? [];
    return OffersResult(
      totalOffers: j['totalOffers'] as int? ?? list.length,
      offers: list
          .map((e) => FlightOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FlightOffer {
  // Backend uses "offerId" (not "id")
  final String offerId;
  final OfferPricing pricing;
  final OfferConditions? conditions;
  final AirlineInfo? owner;
  final List<FlightSlice> slices;
  final String? expiresAt;

  FlightOffer({
    required this.offerId,
    required this.pricing,
    this.conditions,
    this.owner,
    required this.slices,
    this.expiresAt,
  });

  // Convenience
  FlightSlice get outbound => slices.first;
  String get airline => owner?.name ?? '';
  String get airlineIata => owner?.iataCode ?? '';
  String get airlineLogoUrl => owner?.logoUrl ?? '';
  String get origin => outbound.origin.iataCode;
  String get destination => outbound.destination.iataCode;
  String get originCity => outbound.origin.cityName;
  String get destinationCity => outbound.destination.cityName;
  int get stops => outbound.segments.length - 1;
  double get totalAmount => pricing.totalAmount;
  String get currency => pricing.totalCurrency;

  factory FlightOffer.fromJson(Map<String, dynamic> j) {
    final sliceList = j['slices'] as List<dynamic>? ?? [];
    return FlightOffer(
      offerId: j['offerId'] as String? ?? j['id'] as String? ?? '',
      pricing:
      OfferPricing.fromJson(j['pricing'] as Map<String, dynamic>? ?? {}),
      conditions: j['conditions'] != null
          ? OfferConditions.fromJson(j['conditions'] as Map<String, dynamic>)
          : null,
      owner: j['owner'] != null
          ? AirlineInfo.fromJson(j['owner'] as Map<String, dynamic>)
          : null,
      slices: sliceList
          .map((s) => FlightSlice.fromJson(s as Map<String, dynamic>))
          .toList(),
      expiresAt: j['expiresAt'] as String?,
    );
  }
}

class OfferPricing {
  final double baseAmount;
  final double taxAmount;
  final double totalAmount;
  final String totalCurrency;

  OfferPricing({
    required this.baseAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.totalCurrency,
  });

  factory OfferPricing.fromJson(Map<String, dynamic> j) => OfferPricing(
    baseAmount: double.tryParse(j['baseAmount']?.toString() ?? '0') ?? 0,
    taxAmount: double.tryParse(j['taxAmount']?.toString() ?? '0') ?? 0,
    totalAmount: double.tryParse(j['totalAmount']?.toString() ?? '0') ?? 0,
    totalCurrency: j['totalCurrency'] as String? ?? 'USD',
  );
}

class OfferConditions {
  final bool refundable;
  final bool changeable;
  final String? refundPenaltyAmount;
  final String? changePenaltyAmount;

  OfferConditions({
    required this.refundable,
    required this.changeable,
    this.refundPenaltyAmount,
    this.changePenaltyAmount,
  });

  factory OfferConditions.fromJson(Map<String, dynamic> j) => OfferConditions(
    refundable: j['refundable'] as bool? ?? false,
    changeable: j['changeable'] as bool? ?? false,
    refundPenaltyAmount: j['refundPenaltyAmount'] as String?,
    changePenaltyAmount: j['changePenaltyAmount'] as String?,
  );
}

class AirlineInfo {
  final String id;
  final String iataCode;
  final String name;
  final String? logoUrl;
  final String? logoLockupUrl;

  AirlineInfo({
    required this.id,
    required this.iataCode,
    required this.name,
    this.logoUrl,
    this.logoLockupUrl,
  });

  factory AirlineInfo.fromJson(Map<String, dynamic> j) => AirlineInfo(
    id: j['id'] as String? ?? '',
    iataCode: j['iataCode'] as String? ?? '',
    name: j['name'] as String? ?? '',
    logoUrl: j['logoUrl'] as String?,
    logoLockupUrl: j['logoLockupUrl'] as String?,
  );
}

class FlightSlice {
  final String sliceId;
  final AirportInfo origin;
  final AirportInfo destination;
  final String departureAt;
  final String arrivalAt;
  final String duration;
  final List<FlightSegment> segments;

  FlightSlice({
    required this.sliceId,
    required this.origin,
    required this.destination,
    required this.departureAt,
    required this.arrivalAt,
    required this.duration,
    required this.segments,
  });

  factory FlightSlice.fromJson(Map<String, dynamic> j) {
    final segList = j['segments'] as List<dynamic>? ?? [];
    return FlightSlice(
      sliceId: j['sliceId'] as String? ?? '',
      origin: AirportInfo.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
      destination:
      AirportInfo.fromJson(j['destination'] as Map<String, dynamic>? ?? {}),
      departureAt: j['departureAt'] as String? ?? '',
      arrivalAt: j['arrivalAt'] as String? ?? '',
      duration: j['duration'] as String? ?? '',
      segments: segList
          .map((s) => FlightSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AirportInfo {
  final String iataCode;
  final String name;
  final String cityName;
  final String? cityIataCode;
  final String? countryCode;
  final String? timeZone;

  AirportInfo({
    required this.iataCode,
    required this.name,
    required this.cityName,
    this.cityIataCode,
    this.countryCode,
    this.timeZone,
  });

  factory AirportInfo.fromJson(Map<String, dynamic> j) => AirportInfo(
    iataCode: j['iataCode'] as String? ?? '',
    name: j['name'] as String? ?? '',
    cityName: j['cityName'] as String? ?? '',
    cityIataCode: j['cityIataCode'] as String?,
    countryCode: j['countryCode'] as String?,
    timeZone: j['timeZone'] as String?,
  );
}

class FlightSegment {
  final String id;
  final AirportInfo origin;
  final AirportInfo destination;
  final String departingAt;
  final String arrivingAt;
  final String duration;
  final MarketingCarrier? marketingCarrier;
  final String? flightNumber;
  final String? originTerminal;
  final String? destinationTerminal;

  FlightSegment({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departingAt,
    required this.arrivingAt,
    required this.duration,
    this.marketingCarrier,
    this.flightNumber,
    this.originTerminal,
    this.destinationTerminal,
  });

  factory FlightSegment.fromJson(Map<String, dynamic> j) => FlightSegment(
    id: j['id'] as String? ?? '',
    origin:
    AirportInfo.fromJson(j['origin'] as Map<String, dynamic>? ?? {}),
    destination: AirportInfo.fromJson(
        j['destination'] as Map<String, dynamic>? ?? {}),
    departingAt: j['departingAt'] as String? ?? '',
    arrivingAt: j['arrivingAt'] as String? ?? '',
    duration: j['duration'] as String? ?? '',
    marketingCarrier: j['marketingCarrier'] != null
        ? MarketingCarrier.fromJson(
        j['marketingCarrier'] as Map<String, dynamic>)
        : null,
    flightNumber: j['marketingCarrierFlightNumber'] as String?,
    originTerminal: j['originTerminal'] as String?,
    destinationTerminal: j['destinationTerminal'] as String?,
  );
}

class MarketingCarrier {
  final String iataCode;
  final String name;
  final String? logoUrl;

  MarketingCarrier({
    required this.iataCode,
    required this.name,
    this.logoUrl,
  });

  factory MarketingCarrier.fromJson(Map<String, dynamic> j) => MarketingCarrier(
    iataCode: j['iataCode'] as String? ?? '',
    name: j['name'] as String? ?? '',
    logoUrl: j['logoUrl'] as String?,
  );
}

/// Returned by POST /flights/book
class FlightBooking {
  final String bookingId;
  final String bookingRef;
  final OfferPricing pricing;
  final double amount;
  final String currency;
  final OfferConditions? conditions;
  final String? offerExpiresAt;
  // Status from bookings list
  final String status;

  FlightBooking({
    required this.bookingId,
    required this.bookingRef,
    required this.pricing,
    required this.amount,
    required this.currency,
    this.conditions,
    this.offerExpiresAt,
    this.status = 'PENDING_PAYMENT',
  });

  factory FlightBooking.fromJson(Map<String, dynamic> j) => FlightBooking(
    bookingId: j['bookingId'] as String? ?? j['id'] as String? ?? '',
    bookingRef: j['bookingRef'] as String? ?? '',
    pricing: j['pricing'] != null
        ? OfferPricing.fromJson(j['pricing'] as Map<String, dynamic>)
        : OfferPricing.fromJson({}),
    amount: double.tryParse(j['amount']?.toString() ?? '0') ?? 0,
    currency: j['currency'] as String? ?? 'USD',
    conditions: j['conditions'] != null
        ? OfferConditions.fromJson(j['conditions'] as Map<String, dynamic>)
        : null,
    offerExpiresAt: j['offerExpiresAt'] as String?,
    status: j['status'] as String? ?? 'PENDING_PAYMENT',
  );
}

/// From GET /flights/bookings list
class FlightBookingListItem {
  final String id;
  final String bookingRef;
  final String status;
  final double totalAmount;
  final String currency;
  final DateTime createdAt;

  FlightBookingListItem({
    required this.id,
    required this.bookingRef,
    required this.status,
    required this.totalAmount,
    required this.currency,
    required this.createdAt,
  });

  factory FlightBookingListItem.fromJson(Map<String, dynamic> j) =>
      FlightBookingListItem(
        id: j['id'] as String? ?? '',
        bookingRef:
        j['booking_ref'] as String? ?? j['bookingRef'] as String? ?? '',
        status: j['status'] as String? ?? '',
        totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
        currency: j['currency'] as String? ?? 'USD',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class PassengerInput {
  /// API-accepted values: 'adult' | 'child' | 'infant_without_seat'
  final String type;
  final String title; // mr | ms | mrs | dr
  final String firstName;
  final String lastName;
  final String dateOfBirth; // YYYY-MM-DD
  final String gender; // m | f
  final String email;
  final String phone;
  final String? passportNumber;
  final String? issuingCountry;
  final String? passportExpiryDate;

  PassengerInput({
    this.type = 'adult',
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
  }) : assert(
  type == 'adult' || type == 'child' || type == 'infant_without_seat',
  'PassengerInput.type must be one of: adult, child, infant_without_seat',
  );

  Map<String, dynamic> toJson() => {
    'type': type, // API field name is 'type', not 'passengerType'
    'firstName': firstName,
    'lastName': lastName,
    'dateOfBirth': dateOfBirth,
    'gender': gender,
    'title': title,
    'email': email,
    'phone': phone,
    if (passportNumber != null) 'passportNumber': passportNumber,
    if (issuingCountry != null) 'issuingCountry': issuingCountry,
    if (passportExpiryDate != null) 'passportExpiry': passportExpiryDate,
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
    seatMaps: j['seatMaps'] as List<dynamic>? ?? [],
    reason: j['reason'] as String?,
  );
}