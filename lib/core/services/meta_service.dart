// lib/core/services/meta_service.dart
//
// Supporting / reference data endpoints under /api/v1/meta
// Used for autocomplete, airline logos, airport info, etc.

import '../network/api_client.dart';

class MetaService {
  final _client = ApiClient.instance;

  // ── Places autocomplete ─────────────────────────────────────────
  /// GET /meta/places/search?q=London
  /// Returns airports AND cities matching the query string.
  /// Minimum 2 characters.
  Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().length < 2) return [];
    final res = await _client.get(
      '/meta/places/search',
      query: {'q': query.trim()},
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Airports ────────────────────────────────────────────────────
  /// GET /meta/airports?country=IN&iata=DEL
  Future<List<Airport>> listAirports({String? country, String? iata}) async {
    final query = <String, String>{
      if (country != null) 'country': country.toUpperCase(),
      if (iata != null) 'iata': iata.toUpperCase(),
    };
    final res = await _client.get('/meta/airports', query: query);
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => Airport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /meta/airports/:id
  Future<Airport> getAirport(String id) async {
    final res = await _client.get('/meta/airports/$id');
    return Airport.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── Airlines ────────────────────────────────────────────────────
  /// GET /meta/airlines?iata=BA
  Future<List<Airline>> listAirlines({String? iata}) async {
    final query = <String, String>{
      if (iata != null) 'iata': iata.toUpperCase(),
    };
    final res = await _client.get('/meta/airlines', query: query);
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => Airline.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /meta/airlines/:id
  Future<Airline> getAirline(String id) async {
    final res = await _client.get('/meta/airlines/$id');
    return Airline.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── Aircraft ────────────────────────────────────────────────────
  /// GET /meta/aircraft
  Future<List<Map<String, dynamic>>> listAircraft() async {
    final res = await _client.get('/meta/aircraft');
    return (res['data'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  // ── Cities ──────────────────────────────────────────────────────
  /// GET /meta/cities?country=IN
  Future<List<City>> listCities({String? country}) async {
    final query = <String, String>{
      if (country != null) 'country': country.toUpperCase(),
    };
    final res = await _client.get('/meta/cities', query: query);
    final list = res['data'] as List<dynamic>? ?? [];
    return list.map((e) => City.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Loyalty Programmes ──────────────────────────────────────────
  /// GET /meta/loyalty-programmes
  Future<List<LoyaltyProgramme>> listLoyaltyProgrammes() async {
    final res = await _client.get('/meta/loyalty-programmes');
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => LoyaltyProgramme.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Models ───────────────────────────────────────────────────────────

/// Combined airport + city result from /meta/places/search
class PlaceResult {
  final String id;
  final String name;
  final String iataCode;
  final String type; // airport | city
  final String? cityName;
  final String? countryName;
  final String? icaoCode;
  final double? latitude;
  final double? longitude;

  PlaceResult({
    required this.id,
    required this.name,
    required this.iataCode,
    required this.type,
    this.cityName,
    this.countryName,
    this.icaoCode,
    this.latitude,
    this.longitude,
  });

  String get displayLabel {
    final city = cityName ?? '';
    final country = countryName ?? '';
    if (city.isNotEmpty && country.isNotEmpty)
      return '$name ($iataCode) · $city, $country';
    return '$name ($iataCode)';
  }

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    iataCode: j['iata_code'] as String? ?? '',
    type: j['type'] as String? ?? 'airport',
    cityName: j['city_name'] as String?,
    countryName: j['country_name'] as String?,
    icaoCode: j['icao_code'] as String?,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );
}

class Airport {
  final String id;
  final String name;
  final String iataCode;
  final String? icaoCode;
  final String? cityName;
  final String? countryCode;
  final double? latitude;
  final double? longitude;

  Airport({
    required this.id,
    required this.name,
    required this.iataCode,
    this.icaoCode,
    this.cityName,
    this.countryCode,
    this.latitude,
    this.longitude,
  });

  factory Airport.fromJson(Map<String, dynamic> j) => Airport(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    iataCode: j['iata_code'] as String? ?? '',
    icaoCode: j['icao_code'] as String?,
    cityName: j['city_name'] as String?,
    countryCode: j['iata_country_code'] as String?,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );
}

class Airline {
  final String id;
  final String name;
  final String iataCode;
  final String? logoUrl;

  Airline({
    required this.id,
    required this.name,
    required this.iataCode,
    this.logoUrl,
  });

  factory Airline.fromJson(Map<String, dynamic> j) => Airline(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    iataCode: j['iata_code'] as String? ?? '',
    logoUrl: j['logo_url'] as String?,
  );
}

class City {
  final String id;
  final String name;
  final String iataCode;
  final String? countryCode;
  final List<String> airportIds;

  City({
    required this.id,
    required this.name,
    required this.iataCode,
    this.countryCode,
    required this.airportIds,
  });

  factory City.fromJson(Map<String, dynamic> j) => City(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    iataCode: j['iata_code'] as String? ?? '',
    countryCode: j['iata_country_code'] as String?,
    airportIds: (j['airports'] as List<dynamic>? ?? [])
        .map((a) => (a is Map ? a['id'] as String? : a as String?) ?? '')
        .where((s) => s.isNotEmpty)
        .toList(),
  );
}

class LoyaltyProgramme {
  final String id;
  final String name;
  final String? airlineId;

  LoyaltyProgramme({required this.id, required this.name, this.airlineId});

  factory LoyaltyProgramme.fromJson(Map<String, dynamic> j) => LoyaltyProgramme(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    airlineId: j['airline_id'] as String?,
  );
}
