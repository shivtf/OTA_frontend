import 'package:flutter/foundation.dart';
import '../../../core/services/flight_service.dart';
import '../../../core/services/payment_service.dart';
import '../../../core/network/api_client.dart';

enum BookingStep {
  idle,
  searching,
  searchDone,
  loadingOffers,
  offersDone,
  passengerDetails,
  initiatingBooking,
  bookingPending,
  initiatingPayment,
  awaitingStripe,
  confirmingPayment,
  confirmed,
  failed,
}

class FlightBookingProvider extends ChangeNotifier {
  final FlightService _flightService = FlightService();
  final PaymentService _paymentService = PaymentService();

  BookingStep _step = BookingStep.idle;
  String? _error;

  // Search state
  String? _offerRequestId;
  int _totalOffers = 0;

  // Offers state
  List<FlightOffer> _offers = [];
  FlightOffer? _selectedOffer;

  // Booking state
  FlightBooking? _currentBooking;
  List<PassengerInput> _passengers = [];

  // Seat selection — full rich data from seat map screen.
  // Each entry: { passengerIndex, serviceId, designator, amount, currency }
  // Stored here so it survives navigation and is sent to the backend
  // at payment initiation time (NOT at booking init time).
  List<Map<String, dynamic>> _seatSelections = [];

  // Payment state
  PaymentSession? _paymentSession;
  PaymentConfirmResult? _confirmResult;

  // ── Getters ──────────────────────────────────────────────────────
  BookingStep get step => _step;
  String? get error => _error;
  String? get offerRequestId => _offerRequestId;
  int get totalOffers => _totalOffers;
  List<FlightOffer> get offers => _offers;
  FlightOffer? get selectedOffer => _selectedOffer;
  FlightBooking? get currentBooking => _currentBooking;
  PaymentSession? get paymentSession => _paymentSession;
  PaymentConfirmResult? get confirmResult => _confirmResult;

  /// Full rich seat selection data — each entry has passengerIndex,
  /// serviceId, designator, amount, currency.
  List<Map<String, dynamic>> get seatSelections =>
      List.unmodifiable(_seatSelections);

  /// Total extra cost across all selected seats (0.0 if none selected).
  double get seatUpgradeTotal => _seatSelections.fold(
        0.0,
        (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
      );

  bool get isLoading =>
      _step == BookingStep.searching ||
      _step == BookingStep.loadingOffers ||
      _step == BookingStep.initiatingBooking ||
      _step == BookingStep.initiatingPayment ||
      _step == BookingStep.confirmingPayment;

  // ── Step 1: Search ───────────────────────────────────────────────
  Future<bool> searchFlights({
    required String origin,
    required String destination,
    required String departureDate,
    String? returnDate,
    int adults = 1,
    int children = 0,
    String cabinClass = 'economy',
  }) async {
    _step = BookingStep.searching;
    _error = null;
    _offers = [];
    _selectedOffer = null;
    _currentBooking = null;
    notifyListeners();

    try {
      final result = await _flightService.searchFlights(
        origin: origin,
        destination: destination,
        departureDate: departureDate,
        returnDate: returnDate,
        adults: adults,
        children: children,
        cabinClass: cabinClass,
      );
      _offerRequestId = result.offerRequestId;
      _totalOffers = result.totalOffers;
      _step = BookingStep.searchDone;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Search failed. Please check your connection and try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  // ── Step 2: Load Offers ──────────────────────────────────────────
  Future<bool> loadOffers({String sortBy = 'total_amount'}) async {
    if (_offerRequestId == null) return false;

    _step = BookingStep.loadingOffers;
    _error = null;
    notifyListeners();

    try {
      final result = await _flightService.listOffers(
        offerRequestId: _offerRequestId!,
        sortBy: sortBy,
      );
      _offers = result.offers;
      _totalOffers = result.totalOffers;
      _step = BookingStep.offersDone;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to load offers. Please try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  // ── Seat selection ───────────────────────────────────────────────

  /// Called by the seat map screen after the user confirms seat choices.
  /// [selections] is the rich result from Navigator.pop() — each entry has:
  /// { passengerIndex, serviceId, designator, amount, currency }
  void setSeatSelections(List<Map<String, dynamic>> selections) {
    _seatSelections = List.from(selections);
    notifyListeners();
  }

  /// Clears all seat selections (e.g. user taps "Skip" on seat map).
  void clearSeatSelections() {
    _seatSelections = [];
    notifyListeners();
  }

  // ── Select offer ─────────────────────────────────────────────────
  void selectOffer(FlightOffer offer) {
    _selectedOffer = offer;
    _step = BookingStep.passengerDetails;
    notifyListeners();
  }

  void setOfferSilently(FlightOffer offer) {
    _selectedOffer = offer;
    _step = BookingStep.passengerDetails;
    // intentionally no notifyListeners()
  }

  // ── Step 3: Init Booking ─────────────────────────────────────────
  // Note: seat selections are NOT sent here anymore.
  // They are sent at payment initiation time so the correct total
  // is charged. Sending them here served no backend purpose.
  Future<bool> initBooking({
    required List<PassengerInput> passengers,
    String tripType = 'ONE_WAY',
  }) async {
    if (_selectedOffer == null) return false;

    _step = BookingStep.initiatingBooking;
    _passengers = passengers;
    _error = null;
    notifyListeners();

    try {
      _currentBooking = await _flightService.initBooking(
        offerId: _selectedOffer!.offerId,
        passengers: passengers,
        tripType: tripType,
        // No seat services here — sent at initiatePayment instead
      );
      _step = BookingStep.bookingPending;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Booking failed. Please try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  // ── Step 4: Initiate Payment ─────────────────────────────────────
  // Sends seat selections so the backend can:
  //   1. Persist them to flight_booking.selected_services
  //   2. Add seat cost to total_amount before charging
  //   3. Return a pricing breakdown for the UI
  Future<bool> initiatePayment() async {
    if (_currentBooking == null) return false;

    _step = BookingStep.initiatingPayment;
    _error = null;
    notifyListeners();

    try {
      _paymentSession = await _paymentService.initiatePayment(
        _currentBooking!.bookingId,
        selectedServices: _seatSelections, // ← seat selections sent here
      );
      _step = BookingStep.awaitingStripe;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Payment initiation failed. Please try again.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  // ── Step 5: Confirm Payment ──────────────────────────────────────
  // selectedServices are read by the backend from DB (saved at initiate time).
  // No need to re-send them here.
  Future<bool> confirmPayment({required String sessionId}) async {
    if (_currentBooking == null) return false;

    _step = BookingStep.confirmingPayment;
    _error = null;
    notifyListeners();

    try {
      _confirmResult = await _paymentService.confirmPayment(
        bookingId: _currentBooking!.bookingId,
        sessionId: sessionId,
      );
      _step = BookingStep.confirmed;
      notifyListeners();
      return _confirmResult!.isConfirmed;
    } on ApiException catch (e) {
      _error = e.message;
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Payment confirmation failed.';
      _step = BookingStep.failed;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _step = BookingStep.idle;
    _error = null;
    _offerRequestId = null;
    _totalOffers = 0;
    _offers = [];
    _selectedOffer = null;
    _currentBooking = null;
    _passengers = [];
    _seatSelections = []; // ← was _selectedSeatServiceIds
    _paymentSession = null;
    _confirmResult = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
