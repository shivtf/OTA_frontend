// lib/features/payment/providers/payment_provider.dart
//
// The ONLY contract that PaymentController and PaymentScreen depend on.
// Neither Stripe nor Duffel internals ever leak above this interface.
//
// RULE: Every method must return a value or complete normally.
//       Implementations MUST NOT throw — wrap all errors in PaymentResult.failure().

import '../models/payment_result.dart';

abstract class PaymentProvider {
  /// Human-readable label used for analytics / debug logs.
  String get providerName;

  /// One-time SDK / key initialisation.
  /// Called once by PaymentController before processPayment().
  Future<void> initialize();

  /// Process a payment.
  ///
  /// [amount]    – full currency units (e.g. 622.04 for $622.04)
  /// [currency]  – ISO-4217 (e.g. 'USD', 'EUR')
  /// [bookingId] – the pending booking ID from POST /flights/book
  /// [metadata]  – provider-specific extras (offer ID, passengers, token, etc.)
  ///
  /// Every implementation MUST return a [PaymentResult] — never throw.
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String bookingId,
    Map<String, dynamic> metadata,
  });

  /// Optional: clean up any open sessions / SDK state.
  Future<void> dispose() async {}
}
