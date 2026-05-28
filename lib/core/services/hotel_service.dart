// lib/features/hotels/services/hotel_service.dart
import '../network/api_client.dart';

class HotelService {
  final _client = ApiClient.instance;

  // ────────────────────────────────────────────────────────────────
  // SEARCH
  // ────────────────────────────────────────────────────────────────

  /// POST /stays/search
  /// Search by lat/lon. Use a geocoding step (or the meta/places API)
  /// to convert a city name to coordinates.
  Future<HotelSearchResult> searchHotels({
    required double latitude,
    required double longitude,
    required String checkInDate,   // YYYY-MM-DD
    required String checkOutDate,  // YYYY-MM-DD
    int rooms   = 1,
    int guests  = 1,
    int radius  = 10,              // km
  }) async {
    final res = await _client.post('/stays/search', {
      'latitude':     latitude,
      'longitude':    longitude,
      'checkInDate':  checkInDate,
      'checkOutDate': checkOutDate,
      'rooms':        rooms,
      'guests':       guests,
      'radius':       radius,
    });
    return HotelSearchResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /stays/results/:resultId/rates
  Future<List<HotelRate>> getHotelRates(String resultId) async {
    final res = await _client.get('/stays/results/$resultId/rates');
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => HotelRate.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /stays/accommodations/:accommodationId
  Future<HotelDetail> getAccommodation(String accommodationId) async {
    final res = await _client.get('/stays/accommodations/$accommodationId');
    return HotelDetail.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // QUOTES
  // ────────────────────────────────────────────────────────────────

  /// POST /stays/quotes  (requires auth)
  /// Creates a price-locked quote from a rate ID.
  Future<HotelQuote> createQuote(String rateId) async {
    final res = await _client.post('/stays/quotes', {'rateId': rateId}, auth: true);
    return HotelQuote.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ────────────────────────────────────────────────────────────────
  // BOOKING
  // ────────────────────────────────────────────────────────────────

  /// POST /stays/book  (requires auth)
  Future<HotelBooking> initBooking({
    required String rateId,
    required String hotelId,
    required String hotelName,
    required String checkInDate,
    required String checkOutDate,
    required int    rooms,
    required int    guests,
  }) async {
    final res = await _client.post('/stays/book', {
      'rateId':       rateId,
      'hotelId':      hotelId,
      'hotelName':    hotelName,
      'checkInDate':  checkInDate,
      'checkOutDate': checkOutDate,
      'rooms':        rooms,
      'guests':       guests,
    }, auth: true);
    return HotelBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /stays/booking/:bookingId/confirm  (requires auth)
  /// guests: list of GuestInput
  Future<HotelBooking> confirmBooking(
    String bookingId, {
    required List<GuestInput> guests,
    String? paymentProvider,
  }) async {
    final res = await _client.post('/stays/booking/$bookingId/confirm', {
      'guests': guests.map((g) => g.toJson()).toList(),
      if (paymentProvider != null) 'paymentProvider': paymentProvider,
    }, auth: true);
    return HotelBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// GET /stays/bookings  (requires auth)
  Future<List<HotelBooking>> listBookings({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final query = <String, String>{
      'page':  page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };
    final res = await _client.get('/stays/bookings', query: query, auth: true);
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => HotelBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /stays/bookings/:bookingId  (requires auth)
  Future<HotelBooking> getBooking(String bookingId) async {
    final res = await _client.get('/stays/bookings/$bookingId', auth: true);
    return HotelBooking.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// POST /stays/bookings/:bookingId/cancel  (requires auth)
  Future<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    final res = await _client.post(
      '/stays/bookings/$bookingId/cancel',
      {if (reason != null) 'reason': reason},
      auth: true,
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}

// ── Data models ──────────────────────────────────────────────────────

class HotelSearchResult {
  final int totalResults;
  final List<HotelResult> results;

  HotelSearchResult({required this.totalResults, required this.results});

  factory HotelSearchResult.fromJson(Map<String, dynamic> j) {
    final list = j['results'] as List<dynamic>? ?? [];
    return HotelSearchResult(
      totalResults: j['totalResults'] as int? ?? list.length,
      results: list.map((e) => HotelResult.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class HotelResult {
  final String id;
  final String name;
  final String? chainCode;
  final double? latitude;
  final double? longitude;
  final String? starRating;
  final double? lowestRate;
  final String? currency;
  final List<dynamic> photos;

  HotelResult({
    required this.id,
    required this.name,
    this.chainCode,
    this.latitude,
    this.longitude,
    this.starRating,
    this.lowestRate,
    this.currency,
    required this.photos,
  });

  factory HotelResult.fromJson(Map<String, dynamic> j) => HotelResult(
    id:          j['id']          as String? ?? '',
    name:        j['name']        as String? ?? '',
    chainCode:   j['chain_code']  as String?,
    latitude:    (j['latitude']   as num?)?.toDouble(),
    longitude:   (j['longitude']  as num?)?.toDouble(),
    starRating:  j['star_rating'] as String?,
    lowestRate:  (j['lowest_rate'] as num?)?.toDouble(),
    currency:    j['currency']    as String?,
    photos:      j['photos']      as List<dynamic>? ?? [],
  );
}

class HotelRate {
  final String id;
  final String rateId;
  final String boardType;          // room_only | breakfast | half_board | full_board
  final double totalAmount;
  final String currency;
  final String checkInDate;
  final String checkOutDate;
  final int    rooms;
  final bool   cancellable;

  HotelRate({
    required this.id,
    required this.rateId,
    required this.boardType,
    required this.totalAmount,
    required this.currency,
    required this.checkInDate,
    required this.checkOutDate,
    required this.rooms,
    required this.cancellable,
  });

  factory HotelRate.fromJson(Map<String, dynamic> j) => HotelRate(
    id:           j['id']           as String? ?? '',
    rateId:       j['rate_id']      as String? ?? j['id'] as String? ?? '',
    boardType:    j['board_type']   as String? ?? 'room_only',
    totalAmount:  (j['total_amount'] as num?)?.toDouble() ?? 0.0,
    currency:     j['currency']     as String? ?? 'USD',
    checkInDate:  j['check_in_date']  as String? ?? '',
    checkOutDate: j['check_out_date'] as String? ?? '',
    rooms:        j['rooms']        as int?    ?? 1,
    cancellable:  j['cancellable']  as bool?   ?? false,
  );
}

class HotelDetail {
  final String id;
  final String name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? starRating;
  final List<dynamic> amenities;
  final List<dynamic> photos;

  HotelDetail({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
    this.starRating,
    required this.amenities,
    required this.photos,
  });

  factory HotelDetail.fromJson(Map<String, dynamic> j) => HotelDetail(
    id:          j['id']          as String? ?? '',
    name:        j['name']        as String? ?? '',
    description: j['description'] as String?,
    latitude:    (j['latitude']   as num?)?.toDouble(),
    longitude:   (j['longitude']  as num?)?.toDouble(),
    address:     j['address']     as String?,
    starRating:  j['star_rating'] as String?,
    amenities:   j['amenities']   as List<dynamic>? ?? [],
    photos:      j['photos']      as List<dynamic>? ?? [],
  );
}

class HotelQuote {
  final String id;
  final double totalAmount;
  final String currency;
  final String expiresAt;
  final Map<String, dynamic> raw;

  HotelQuote({
    required this.id,
    required this.totalAmount,
    required this.currency,
    required this.expiresAt,
    required this.raw,
  });

  factory HotelQuote.fromJson(Map<String, dynamic> j) => HotelQuote(
    id:          j['id']           as String? ?? '',
    totalAmount: (j['total_amount'] as num?)?.toDouble() ?? 0,
    currency:    j['currency']     as String? ?? 'USD',
    expiresAt:   j['expires_at']   as String? ?? '',
    raw: j,
  );
}

class HotelBooking {
  final String id;
  final String status;
  final String? hotelName;
  final String? checkInDate;
  final String? checkOutDate;
  final double? totalAmount;
  final String? currency;
  final DateTime createdAt;

  HotelBooking({
    required this.id,
    required this.status,
    this.hotelName,
    this.checkInDate,
    this.checkOutDate,
    this.totalAmount,
    this.currency,
    required this.createdAt,
  });

  factory HotelBooking.fromJson(Map<String, dynamic> j) => HotelBooking(
    id:           j['id']           as String? ?? '',
    status:       j['status']       as String? ?? '',
    hotelName:    j['hotelName']    as String?,
    checkInDate:  j['checkInDate']  as String?,
    checkOutDate: j['checkOutDate'] as String?,
    totalAmount:  (j['totalAmount']  as num?)?.toDouble(),
    currency:     j['currency']     as String?,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
  );
}

class GuestInput {
  final String title;      // mr | ms | mrs | dr
  final String firstName;
  final String lastName;

  GuestInput({
    required this.title,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() => {
    'title':       title,
    'given_name':  firstName,
    'family_name': lastName,
  };
}
