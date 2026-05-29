// lib/core/services/meta_service.dart
import '../network/api_client.dart';

// ── Place model (from GET /meta/places/search) ────────────────────────────────

class PlaceResult {
  final String id;
  final String type; // 'city' | 'airport'
  final String iataCode;
  final String name;
  final String city;
  final String countryCode;

  PlaceResult({
    required this.id,
    required this.type,
    required this.iataCode,
    required this.name,
    required this.city,
    required this.countryCode,
  });

  /// Display label shown in the dropdown
  String get displayName {
    if (type == 'city') return '$name ($iataCode) · All airports';
    return '$name ($iataCode) · $city';
  }

  /// Short label shown in the field after selection
  String get shortLabel => '$iataCode · $name';

  factory PlaceResult.fromJson(Map<String, dynamic> j) => PlaceResult(
        id: j['id'] as String? ?? '',
        type: j['type'] as String? ?? 'airport',
        iataCode: j['iataCode'] as String? ?? '',
        name: j['name'] as String? ?? '',
        city: j['city'] as String? ?? '',
        countryCode: j['countryCode'] as String? ?? '',
      );
}

// ── MetaService ───────────────────────────────────────────────────────────────

class MetaService {
  final _client = ApiClient.instance;

  /// GET /meta/places/search?q=query
  /// Returns cities and airports matching the query string.
  Future<List<PlaceResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return [];
    final res = await _client.get(
      '/meta/places/search',
      query: {'q': query.trim()},
    );
    final list = res['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => PlaceResult.fromJson(e as Map<String, dynamic>))
        .where((p) => p.iataCode.isNotEmpty) // filter out entries without code
        .toList();
  }
}
