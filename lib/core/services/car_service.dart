// lib/features/cars/services/car_service.dart
import '../network/api_client.dart';

class CarService {
  final _client = ApiClient.instance;

  // ────────────────────────────────────────────────────────────────
  // SEARCH
  // ────────────────────────────────────────────────────────────────

  /// POST /cars/search
  /// pickupLocationIata / dropoffLocationIata: airport IATA codes e.g. "DEL"
  /// pickupDateTime / dropoffDateTime: ISO-8601 e.g. "2025-06-15T10:00:00"
  Future<CarSearchResult> searchCars({
    required String pickupLocationIata,
    required String dropoffLocationIata,
    required String pickupDateTime,
    required String dropoffDateTime,
    int driverAge = 30,
  }) async {
    final res = await _client.post('/cars/search', {
      'pickupLocationIata':  pickupLocationIata.toUpperCase(),
      'dropoffLocationIata': dropoffLocationIata.toUpperCase(),
      'pickupDateTime':      pickupDateTime,
      'dropoffDateTime':     dropoffDateTime,
      'driverAge':           driverAge,
    });
    return CarSearchResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // QUOTES
  // ────────────────────────────────────────────────────────────────

  /// POST /cars/quotes  (requires auth)  — create a quote from a rate ID
  Future<CarQuote> createQuote(String rateId) async {
    final res = await _client.post('/cars/quotes', {'rateId': rateId}, auth: true);
    return CarQuote.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /cars/quotes/:quoteId  — retrieve an existing quote
  Future<CarQuote> getQuote(String quoteId) async {
    final res = await _client.get('/cars/quotes/$quoteId');
    return CarQuote.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // BOOKING
  // ────────────────────────────────────────────────────────────────

  /// POST /cars/book  (requires auth)
  Future<CarBooking> initBooking({
    required String rateId,
    required String pickupLocation,
    required String dropoffLocation,
    required String pickupDate,
    required String dropoffDate,
    required String carType,
  }) async {
    final res = await _client.post('/cars/book', {
      'rateId':          rateId,
      'pickupLocation':  pickupLocation,
      'droppffLocation': dropoffLocation, // backend field name
      'pickupDate':      pickupDate,
      'droppffDate':     dropoffDate,     // backend field name
      'carType':         carType,
    }, auth: true);
    return CarBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /cars/bookings/:bookingId/confirm  (requires auth)
  Future<CarBooking> confirmBooking(
    String bookingId, {
    required DriverInput driver,
    String? paymentProvider,
  }) async {
    final res = await _client.post('/cars/bookings/$bookingId/confirm', {
      'driver': driver.toJson(),
      if (paymentProvider != null) 'paymentProvider': paymentProvider,
    }, auth: true);
    return CarBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /cars/bookings  (requires auth)
  Future<List<CarBooking>> listBookings({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final query = <String, String>{
      'page':  page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final res = await _client.get('/cars/bookings', query: query, auth: true);
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => CarBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /cars/bookings/:bookingId  (requires auth)
  Future<CarBooking> getBooking(String bookingId) async {
    final res = await _client.get('/cars/bookings/$bookingId', auth: true);
    return CarBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /cars/bookings/:bookingId/cancel  (requires auth)
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final res = await _client.post(
      '/cars/bookings/$bookingId/cancel', {}, auth: true);
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}

// ── Data models ──────────────────────────────────────────────────────

class CarSearchResult {
  final int   totalResults;
  final List<CarOffer> offers;

  CarSearchResult({required this.totalResults, required this.offers});

  factory CarSearchResult.fromJson(Map<String, dynamic> j) {
    final list = j['offers'] as List<dynamic>? ?? [];
    return CarSearchResult(
      totalResults: j['totalResults'] as int? ?? list.length,
      offers: list.map((e) => CarOffer.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class CarOffer {
  final String id;
  final String? vehicleType;       // economy | compact | suv | luxury
  final String? vehicleMake;
  final String? vehicleModel;
  final double  totalAmount;
  final String  currency;
  final String? transmissionType;  // automatic | manual
  final String? fuelType;
  final int?    passengerCapacity;
  final int?    baggageCapacity;
  final List<dynamic> features;
  final Map<String, dynamic>? pickupLocation;
  final Map<String, dynamic>? dropoffLocation;

  CarOffer({
    required this.id,
    this.vehicleType,
    this.vehicleMake,
    this.vehicleModel,
    required this.totalAmount,
    required this.currency,
    this.transmissionType,
    this.fuelType,
    this.passengerCapacity,
    this.baggageCapacity,
    required this.features,
    this.pickupLocation,
    this.dropoffLocation,
  });

  String get displayName {
    if (vehicleMake != null && vehicleModel != null) return '$vehicleMake $vehicleModel';
    return vehicleType ?? 'Car';
  }

  factory CarOffer.fromJson(Map<String, dynamic> j) => CarOffer(
    id:                j['id']                    as String? ?? '',
    vehicleType:       j['vehicle_type']           as String?,
    vehicleMake:       j['vehicle_make']           as String?,
    vehicleModel:      j['vehicle_model']          as String?,
    totalAmount:       (j['total_amount']          as num?)?.toDouble() ?? 0.0,
    currency:          j['currency']               as String? ?? 'USD',
    transmissionType:  j['transmission_type']      as String?,
    fuelType:          j['fuel_type']              as String?,
    passengerCapacity: j['passenger_capacity']     as int?,
    baggageCapacity:   j['baggage_capacity']       as int?,
    features:          j['features']               as List<dynamic>? ?? [],
    pickupLocation:    j['pickup_location']        as Map<String, dynamic>?,
    dropoffLocation:   j['dropoff_location']       as Map<String, dynamic>?,
  );
}

class CarQuote {
  final String id;
  final double totalAmount;
  final String currency;
  final String? expiresAt;
  final Map<String, dynamic> raw;

  CarQuote({
    required this.id,
    required this.totalAmount,
    required this.currency,
    this.expiresAt,
    required this.raw,
  });

  factory CarQuote.fromJson(Map<String, dynamic> j) => CarQuote(
    id:          j['id']           as String? ?? '',
    totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0.0,
    currency:    j['currency']     as String? ?? 'USD',
    expiresAt:   j['expires_at']   as String?,
    raw: j,
  );
}

class CarBooking {
  final String id;
  final String status;
  final String? carType;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? pickupDate;
  final String? dropoffDate;
  final double? totalAmount;
  final String? currency;
  final DateTime createdAt;

  CarBooking({
    required this.id,
    required this.status,
    this.carType,
    this.pickupLocation,
    this.dropoffLocation,
    this.pickupDate,
    this.dropoffDate,
    this.totalAmount,
    this.currency,
    required this.createdAt,
  });

  factory CarBooking.fromJson(Map<String, dynamic> j) => CarBooking(
    id:             j['id']             as String? ?? '',
    status:         j['status']         as String? ?? '',
    carType:        j['carType']        as String?,
    pickupLocation: j['pickupLocation'] as String?,
    dropoffLocation:j['dropoffLocation'] as String?,
    pickupDate:     j['pickupDate']     as String?,
    dropoffDate:    j['dropoffDate']    as String?,
    totalAmount:    (j['totalAmount']   as num?)?.toDouble(),
    currency:       j['currency']       as String?,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

class DriverInput {
  final String title;       // mr | ms | mrs | dr
  final String firstName;
  final String lastName;
  final String dateOfBirth; // YYYY-MM-DD
  final String email;
  final String phone;

  DriverInput({
    required this.title,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'title':        title,
    'given_name':   firstName,
    'family_name':  lastName,
    'born_on':      dateOfBirth,
    'email':        email,
    'phone_number': phone,
  };
}
