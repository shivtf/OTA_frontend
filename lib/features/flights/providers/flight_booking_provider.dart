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
  bookingPending, // has bookingId, awaiting payment
  initiatingPayment,
  awaitingStripe, // sessionUrl opened, waiting for user to return
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

  // Payment state
  PaymentSession? _paymentSession;
  PaymentConfirmResult? _confirmResult;

  // Getters
  BookingStep get step => _step;
  String? get error => _error;
  String? get offerRequestId => _offerRequestId;
  int get totalOffers => _totalOffers;
  List<FlightOffer> get offers => _offers;
  FlightOffer? get selectedOffer => _selectedOffer;
  FlightBooking? get currentBooking => _currentBooking;
  PaymentSession? get paymentSession => _paymentSession;
  PaymentConfirmResult? get confirmResult => _confirmResult;
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

  // ── Select offer ─────────────────────────────────────────────────
  void selectOffer(FlightOffer offer) {
    _selectedOffer = offer;
    _step = BookingStep.passengerDetails;
    notifyListeners();
  }

  // ── Step 3: Init Booking ─────────────────────────────────────────
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

  // ── Step 4: Initiate Payment → get Stripe URL ────────────────────
  Future<bool> initiatePayment() async {
    if (_currentBooking == null) return false;

    _step = BookingStep.initiatingPayment;
    _error = null;
    notifyListeners();

    try {
      _paymentSession = await _paymentService.initiatePayment(
        _currentBooking!.bookingId,
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

  // ── Step 5: Confirm Payment (called after Stripe redirect) ───────
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
    _paymentSession = null;
    _confirmResult = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}