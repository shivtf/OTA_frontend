// lib/features/payment/controllers/payment_controller.dart
//
// The single orchestration layer between the UI and payment providers.
//
// ┌─────────────────────────────────────────────────────────────┐
// │  PaymentScreen  →  PaymentController  →  PaymentProvider    │
// │                        ↑                 (Stripe | Duffel)  │
// │                  AppConfig.paymentGateway                   │
// └─────────────────────────────────────────────────────────────┘
//
// SWITCHING PROVIDERS:
//   Change AppConfig.paymentGateway (or --dart-define PAYMENT_GATEWAY=duffel).
//   Nothing in the UI or this controller changes.

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../models/payment_model.dart';
import '../models/payment_result.dart';
import '../providers/payment_provider.dart';
import '../providers/stripe_payment_provider.dart';
import '../providers/duffel_payment_provider.dart';

class PaymentController extends ChangeNotifier {
  PaymentController() {
    _provider = _buildProvider();
  }

  // ── State ─────────────────────────────────────────────────────────────────
  late PaymentProvider _provider;
  bool _initialized = false;
  bool _isProcessing = false;
  PaymentResult? _lastResult;
  String? _errorMessage;
  int _retryCount = 0;

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isProcessing  => _isProcessing;
  PaymentResult? get lastResult  => _lastResult;
  String? get errorMessage => _errorMessage;
  int get retryCount     => _retryCount;
  String get providerName => _provider.providerName;

  bool get canRetry =>
      AppConfig.enablePaymentRetry &&
      _retryCount < AppConfig.maxRetryAttempts &&
      (_lastResult?.isFailure == true);

  PaymentScreenState get screenState {
    if (_isProcessing) return PaymentScreenState.processing;
    if (_lastResult == null) return PaymentScreenState.idle;
    switch (_lastResult!.status) {
      case PaymentStatus.success:
        return PaymentScreenState.success;
      case PaymentStatus.failure:
        return PaymentScreenState.failure;
      case PaymentStatus.cancelled:
        return PaymentScreenState.cancelled;
      case PaymentStatus.pending:
        return PaymentScreenState.idle;
      default:
        return PaymentScreenState.idle;
    }
  }

  // ── Provider factory ──────────────────────────────────────────────────────
  // THIS is the only place where Stripe vs Duffel is selected.
  // Changing AppConfig.paymentGateway is the only required change.
  PaymentProvider _buildProvider() {
    switch (AppConfig.paymentGateway) {
      case PaymentGateway.duffel:
        debugPrint('[PaymentController] Using DuffelPaymentProvider');
        return DuffelPaymentProvider();
      case PaymentGateway.stripe:
      // fall-through — default
      default:
        debugPrint('[PaymentController] Using StripePaymentProvider');
        return StripePaymentProvider();
    }
  }

  // ── Initialisation ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    await _provider.initialize();
    _initialized = true;
    debugPrint('[PaymentController] Provider "${_provider.providerName}" ready');
  }

  // ── Core: processPayment ──────────────────────────────────────────────────
  Future<PaymentResult> processPayment({
    required BookingItem booking,
    Map<String, dynamic> extraMetadata = const {},
  }) async {
    if (_isProcessing) {
      return PaymentResult.failure(
        errorMessage: 'A payment is already in progress.',
        errorCode: 'ALREADY_PROCESSING',
        providerName: _provider.providerName,
      );
    }

    // Ensure bookingId is present
    final bookingId = booking.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return PaymentResult.failure(
        errorMessage: 'Invalid booking. Please go back and try again.',
        errorCode: 'MISSING_BOOKING_ID',
        providerName: _provider.providerName,
      );
    }

    _isProcessing = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    // Ensure provider is initialised before every call (idempotent)
    if (!_initialized) await initialize();

    // Build provider metadata from BookingItem
    final metadata = {
      if (booking.duffelOfferId != null)
        'duffel_offer_id': booking.duffelOfferId!,
      'passengers': booking.passengers
          .map((p) => {'name': p.name, 'type': p.type})
          .toList(),
      ...extraMetadata,
    };

    final result = await _provider.processPayment(
      amount: booking.total,
      currency: booking.currency,
      bookingId: bookingId,
      metadata: metadata,
    );

    _lastResult = result;
    _isProcessing = false;

    if (result.isFailure) {
      _errorMessage = result.errorMessage;
    } else if (result.isCancelled) {
      _errorMessage = null; // silent cancellation
    } else {
      _errorMessage = null;
      _retryCount = 0;
    }

    debugPrint('[PaymentController] Result: $result');
    notifyListeners();
    return result;
  }

  // ── Retry ────────────────────────────────────────────────────────────────
  Future<PaymentResult?> retry({
    required BookingItem booking,
    Map<String, dynamic> extraMetadata = const {},
  }) async {
    if (!canRetry) return null;
    _retryCount++;
    debugPrint('[PaymentController] Retry #$_retryCount');
    notifyListeners();
    return processPayment(booking: booking, extraMetadata: extraMetadata);
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void reset() {
    _isProcessing = false;
    _lastResult = null;
    _errorMessage = null;
    _retryCount = 0;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _provider.dispose();
    super.dispose();
  }
}
