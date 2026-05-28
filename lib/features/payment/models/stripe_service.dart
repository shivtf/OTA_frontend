// lib/features/payment/models/stripe_service.dart
//
// Connected to the real backend at https://ota-jnuy.onrender.com/api/v1/payments
// Flow:
//   1. POST /payments/initiate  → get clientSecret
//   2. Init Stripe payment sheet
//   3. Present sheet → user pays
//   4. POST /payments/confirm   → backend confirms & triggers booking

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../../core/network/api_client.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  // ── YOUR Stripe publishable key ────────────────────────────────────────────
  // Get from https://dashboard.stripe.com/test/apikeys
  // Replace this before going to production!
  static const String _publishableKey =
      'pk_test_51OxYourTestPublishableKeyHere';

  static void init() {
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'wanderly.app';
  }

  /// Full payment flow for a booking.
  /// [bookingId] — the pending booking from /flights/book or /stays/book
  /// Returns true on success.
  Future<bool> processBookingPayment({
    required String bookingId,
    required String customerEmail,
  }) async {
    try {
      // Step 1 — Get PaymentIntent client secret from our backend
      final intentResult = await ApiClient.instance.post(
        '/payments/initiate',
        {'bookingId': bookingId},
        auth: true,
      );

      final data = intentResult['data'] as Map<String, dynamic>;
      final clientSecret = data['clientSecret'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final currency = (data['currency'] as String? ?? 'usd').toLowerCase();

      if (clientSecret == null || clientSecret.isEmpty) {
        debugPrint('[Stripe] No clientSecret from backend');
        return false;
      }

      // Step 2 — Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Wanderly',
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: currency,
            testEnv: _publishableKey.startsWith('pk_test_'),
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'US',
          ),
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6C3CE1),
              background: Color(0xFFF8F7FF),
              componentBackground: Color(0xFFFFFFFF),
              componentBorder: Color(0xFFE8E4F0),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 16,
              borderWidth: 1.5,
            ),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                light: PaymentSheetPrimaryButtonThemeColors(
                  background: Color(0xFF6C3CE1),
                  text: Color(0xFFFFFFFF),
                  border: Color(0xFF6C3CE1),
                ),
              ),
              shapes: PaymentSheetPrimaryButtonShape(blurRadius: 8),
            ),
          ),
        ),
      );

      // Step 3 — Show payment sheet to user
      await Stripe.instance.presentPaymentSheet();

      // Step 4 — Confirm with backend (triggers booking finalization)
      await ApiClient.instance.post(
        '/payments/confirm',
        {'bookingId': bookingId},
        auth: true,
      );

      return true;
    } on StripeException catch (e) {
      debugPrint('[Stripe] StripeException: ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) return false;
      return false;
    } on ApiException catch (e) {
      debugPrint('[Stripe] ApiException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Stripe] Unknown error: $e');
      return false;
    }
  }

  /// Standalone payment (non-booking) — amount in full currency units (e.g. 42.50 USD)
  Future<bool> processPayment({
    required double amount,
    required String currency,
    required String customerEmail,
    required String description,
  }) async {
    // For non-booking payments, create intent on backend too
    try {
      final intentResult = await ApiClient.instance.post(
        '/payments/create-intent',
        {
          'amount': (amount * 100).toInt(),
          'currency': currency.toLowerCase(),
          'description': description,
        },
        auth: true,
      );
      final clientSecret =
          intentResult['data']['clientSecret'] as String? ?? '';
      if (clientSecret.isEmpty) return false;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Wanderly',
          style: ThemeMode.system,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) return false;
      return false;
    } catch (_) {
      return false;
    }
  }
}
