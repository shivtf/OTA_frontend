// lib/features/payment/providers/stripe_payment_provider.dart
//
// Stripe implementation of PaymentProvider.
//
// Reuses the existing StripeService + ApiClient already in the project.
// Flow:
//   1. POST /payments/initiate  → clientSecret  (your backend)
//   2. Stripe.initPaymentSheet(clientSecret)
//   3. Stripe.presentPaymentSheet()             (native Stripe UI)
//   4. POST /payments/confirm                   (your backend finalises booking)
//   5. Return PaymentResult

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_result.dart';
import 'payment_provider.dart';

class StripePaymentProvider implements PaymentProvider {
  StripePaymentProvider({String? publishableKey})
      : _publishableKey = publishableKey ?? AppConfig.stripePublishableKey;

  final String _publishableKey;

  @override
  String get providerName => 'stripe';

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'wanderly.app';
    await Stripe.instance.applySettings();
    debugPrint('[StripeProvider] Initialized (key: ${_publishableKey.substring(0, 12)}...)');
  }

  // ── Core payment flow ─────────────────────────────────────────────────────

  @override
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String bookingId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Step 1 — Get PaymentIntent client secret from your backend
      final clientSecret = await _initiatePayment(bookingId: bookingId);
      if (clientSecret == null || clientSecret.isEmpty) {
        return PaymentResult.failure(
          errorMessage: 'Unable to start payment. Please try again.',
          errorCode: 'STRIPE_NO_CLIENT_SECRET',
          providerName: providerName,
        );
      }

      // Step 2 — Initialise the Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Wanderly',
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: currency.toLowerCase(),
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

      // Step 3 — Present sheet; user authenticates & pays
      await Stripe.instance.presentPaymentSheet();

      // Step 4 — Confirm with backend (triggers booking finalisation)
      await _confirmPayment(bookingId: bookingId);

      // Step 5 — Return success
      final paymentIntentId = clientSecret.split('_secret_').first;
      return PaymentResult.success(
        transactionId: paymentIntentId,
        bookingReference: bookingId,
        providerName: providerName,
        metadata: {'clientSecret': clientSecret, ...metadata},
      );
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return PaymentResult.cancelled(providerName: providerName);
      }
      return PaymentResult.failure(
        errorMessage: e.error.localizedMessage ?? 'Payment failed. Please try again.',
        errorCode: e.error.code.toString(),
        providerName: providerName,
      );
    } on ApiException catch (e) {
      return PaymentResult.failure(
        errorMessage: _friendlyApiError(e),
        errorCode: 'STRIPE_API_${e.statusCode}',
        providerName: providerName,
      );
    } catch (e) {
      return PaymentResult.failure(
        errorMessage: _friendlyError(e),
        errorCode: 'STRIPE_UNKNOWN',
        providerName: providerName,
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<String?> _initiatePayment({required String bookingId}) async {
    final res = await ApiClient.instance.post(
      '/payments/initiate',
      {'bookingId': bookingId},
      auth: true,
    );
    final data = res['data'] as Map<String, dynamic>?;
    return data?['clientSecret'] as String?;
  }

  Future<void> _confirmPayment({required String bookingId}) async {
    await ApiClient.instance.post(
      '/payments/confirm',
      {'bookingId': bookingId},
      auth: true,
    );
  }

  String _friendlyApiError(ApiException e) {
    if (e.isUnauthorized) return 'Session expired. Please log in again.';
    if (e.statusCode >= 500) return 'Our servers are having trouble. Please try again.';
    return e.message.isNotEmpty
        ? e.message
        : 'Payment request failed. Please try again.';
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('TimeoutException') ||
        msg.contains('NetworkException')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Future<void> dispose() async {
    debugPrint('[StripeProvider] Disposed');
  }
}
