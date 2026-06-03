// lib/features/home/providers/booking_stats_provider.dart
//
// Fetches the user's confirmed bookings from the API and exposes:
//   • tripCount    — number of bookings with status 'confirmed' / 'paid'
//   • countryCount — number of UNIQUE destination countries across those bookings
//
// Call refresh() after a successful payment so the header chips update instantly.

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class BookingStatsProvider extends ChangeNotifier {
  int _tripCount = 0;
  int _countryCount = 0;
  bool _loading = false;

  int get tripCount => _tripCount;
  int get countryCount => _countryCount;
  bool get loading => _loading;

  // ── Fetch from API ────────────────────────────────────────────────────────
  // Calls GET /bookings?status=confirmed  (adjust path to match your backend)
  // Expected response shape:
  //   { data: [ { status, destination: { countryCode } }, ... ] }
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get(
        '/bookings',
        query: {'status': 'confirmed'},
        auth: true,
      );

      final raw = res['data'];
      final List<dynamic> bookings =
      raw is List ? raw : (raw is Map ? (raw['bookings'] ?? []) : []);

      // Count only confirmed/paid trips
      final confirmed = bookings.where((b) {
        final status = (b['status'] as String? ?? '').toLowerCase();
        return status == 'confirmed' || status == 'paid';
      }).toList();

      // Unique destination countries
      final countries = <String>{};
      for (final b in confirmed) {
        // Try common response shapes: destination.countryCode / destination / country
        final dest = b['destination'];
        String? country;
        if (dest is Map) {
          country = (dest['countryCode'] as String?) ??
              (dest['country'] as String?) ??
              (dest['iataCode'] as String?);
        } else if (dest is String && dest.isNotEmpty) {
          country = dest;
        }
        // Fallback: top-level country field
        country ??= b['country'] as String?;
        country ??= b['destinationCountry'] as String?;

        if (country != null && country.isNotEmpty) {
          countries.add(country.toUpperCase());
        }
      }

      _tripCount = confirmed.length;
      _countryCount = countries.length;
    } catch (_) {
      // Network error or unexpected shape — keep existing values
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
