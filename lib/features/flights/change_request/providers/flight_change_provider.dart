// lib/features/flights/change_request/providers/flight_change_provider.dart
//
// ChangeNotifier that drives the 3-step change-request flow.
// Screens rebuild by calling context.watch<FlightChangeProvider>().

import 'package:flutter/foundation.dart';
import '../../../../../core/services/flight_change_service.dart';
import '../../../../core/network/api_client.dart';

enum ChangeStep { form, offers, confirming, success, error }

class FlightChangeProvider extends ChangeNotifier {
  final _service = FlightChangeService();

  // ── Current booking context ──────────────────────────────────────
  String? bookingId;
  String? sliceId; // fetched from GET /bookings/:id

  // ── Step state ───────────────────────────────────────────────────
  ChangeStep step = ChangeStep.form;
  bool isLoading = false;
  String? errorMessage;

  // ── Step 1 result ────────────────────────────────────────────────
  ChangeRequest? changeRequest;

  // ── Step 2 result ────────────────────────────────────────────────
  List<ChangeOffer> offers = [];
  ChangeOffer? selectedOffer;

  // ── Step 3 result ────────────────────────────────────────────────
  ConfirmedChange? confirmedChange;

  // ── Form inputs ──────────────────────────────────────────────────
  String origin = '';
  String destination = '';
  DateTime? departureDate;
  String cabinClass = 'economy';

  // ─────────────────────────────────────────────────────────────────
  // Initialise with a booking — fetches sliceId from the API
  // ─────────────────────────────────────────────────────────────────
  Future<void> init(String bId) async {
    bookingId = bId;
    _setLoading(true);
    try {
      final booking = await _service.getBooking(bId);
      final slices = booking['slices'] as List<dynamic>? ?? [];
      if (slices.isNotEmpty) {
        final first = slices.first as Map<String, dynamic>;
        sliceId = first['id'] as String?;
        // Pre-fill origin / destination from booking for convenience
        origin = (first['origin']?['iata_code'] as String?) ?? '';
        destination = (first['destination']?['iata_code'] as String?) ?? '';
      }
      step = ChangeStep.form;
      errorMessage = null;
    } catch (e) {
      errorMessage = _friendlyError(e);
      step = ChangeStep.error;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 1 — Create change request
  // ─────────────────────────────────────────────────────────────────
  Future<void> submitChangeRequest() async {
    if (bookingId == null || sliceId == null) return;
    if (origin.isEmpty || destination.isEmpty || departureDate == null) {
      errorMessage = 'Please fill in all required fields.';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      changeRequest = await _service.createChangeRequest(
        bookingId: bookingId!,
        slices: [
          ChangeRequestSliceInput(
            sliceId: sliceId!,
            origin: origin,
            destination: destination,
            departureDate:
            '${departureDate!.year.toString().padLeft(4, '0')}-'
                '${departureDate!.month.toString().padLeft(2, '0')}-'
                '${departureDate!.day.toString().padLeft(2, '0')}',
            cabinClass: cabinClass,
          ),
        ],
      );
      await _loadOffers();
    } catch (e) {
      errorMessage = _friendlyError(e);
      step = ChangeStep.error;
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 2 — List offers (called internally after step 1)
  // ─────────────────────────────────────────────────────────────────
  Future<void> _loadOffers() async {
    try {
      offers = await _service.listChangeOffers(
        bookingId: bookingId!,
        orderChangeRequestId: changeRequest!.id,
      );
      step = ChangeStep.offers;
      errorMessage = null;
    } catch (e) {
      errorMessage = _friendlyError(e);
      step = ChangeStep.error;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Step 3 — Confirm chosen offer
  // ─────────────────────────────────────────────────────────────────
  Future<void> confirmOffer(ChangeOffer offer) async {
    if (bookingId == null) return;
    selectedOffer = offer;
    step = ChangeStep.confirming;
    _setLoading(true);
    notifyListeners();

    try {
      confirmedChange = await _service.confirmChange(
        bookingId: bookingId!,
        orderChangeOfferId: offer.id,
      );
      step = ChangeStep.success;
      errorMessage = null;
    } catch (e) {
      final msg = _friendlyError(e);
      // 422 = offer expired → force restart
      if (e is ApiException && e.statusCode == 422) {
        errorMessage =
        'This offer has expired. Please search for new options.';
        _resetToForm();
      } else {
        errorMessage = msg;
        step = ChangeStep.error;
      }
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────
  void goBackToForm() {
    _resetToForm();
    notifyListeners();
  }

  void _resetToForm() {
    changeRequest = null;
    offers = [];
    selectedOffer = null;
    step = ChangeStep.form;
  }

  void _setLoading(bool v) {
    isLoading = v;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }
}
