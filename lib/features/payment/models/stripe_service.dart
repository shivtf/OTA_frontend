// lib/features/payment/models/stripe_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();

  // ── Stripe publishable key (test mode) ─────────────────────────────────────
  // Replace with your own key from https://dashboard.stripe.com/test/apikeys
  static const String _publishableKey =
      'pk_test_51OxYourTestPublishableKeyHere';

  // ── Your backend URL that creates PaymentIntents ───────────────────────────
  // In production this should be YOUR server endpoint.
  // For testing we simulate the response locally.
  static const String _backendUrl =
      'https://your-backend.com/create-payment-intent';

  /// Call once at app startup (in main.dart)
  static void init() {
    Stripe.publishableKey = _publishableKey;
    Stripe.merchantIdentifier = 'wanderly.app';
  }

  /// Full payment flow:
  /// 1. Create PaymentIntent on backend
  /// 2. Initialize the payment sheet
  /// 3. Present the sheet to the user
  /// Returns true on success, false on failure/cancellation
  Future<bool> processPayment({
    required double amount, // in USD
    required String currency,
    required String customerEmail,
    required String description,
  }) async {
    try {
      // Step 1 — Get client secret from backend
      final clientSecret = await _createPaymentIntent(
        amount: (amount * 100).toInt(), // Stripe uses cents
        currency: currency,
        customerEmail: customerEmail,
        description: description,
      );

      if (clientSecret == null) return false;

      // Step 2 — Init payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Wanderly',
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'US',
            currencyCode: 'usd',
            testEnv: true,
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

      // Step 3 — Present the sheet
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) {
        return false; // user cancelled — not an error
      }
      return false;
    } catch (e) {
      debugPrint('Payment error: $e');
      return false;
    }
  }

  Future<String?> _createPaymentIntent({
    required int amount,
    required String currency,
    required String customerEmail,
    required String description,
  }) async {
    try {
      // ── In a real app, hit YOUR backend ────────────────────────────────────
      // Your server creates a PaymentIntent and returns the client_secret.
      // Example Node.js / Python backend shown in README below.
      //
      // final response = await http.post(
      //   Uri.parse(_backendUrl),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'amount': amount,
      //     'currency': currency,
      //     'receipt_email': customerEmail,
      //     'description': description,
      //   }),
      // );
      // final data = jsonDecode(response.body);
      // return data['client_secret'] as String?;

      // ── For local UI testing without a backend ─────────────────────────────
      // Returns a simulated client secret so the UI flow works end-to-end.
      // The Stripe payment sheet will fail at confirmation (expected) but
      // the entire UI before that works perfectly.
      await Future.delayed(const Duration(milliseconds: 600));
      return 'pi_test_simulated_${DateTime.now().millisecondsSinceEpoch}_secret_demo';
    } catch (e) {
      debugPrint('PaymentIntent creation error: $e');
      return null;
    }
  }
}

/* ─────────────────────────────────────────────────────────────────────────────
   BACKEND SETUP (Node.js example)
   ─────────────────────────────────────────────────────────────────────────────

   1. npm install stripe express cors
   2. Create server.js:

   const stripe = require('stripe')('sk_test_YOUR_SECRET_KEY');
   const express = require('express');
   const app = express();
   app.use(express.json());

   app.post('/create-payment-intent', async (req, res) => {
     const { amount, currency, receipt_email, description } = req.body;
     const paymentIntent = await stripe.paymentIntents.create({
       amount,
       currency,
       receipt_email,
       description,
       automatic_payment_methods: { enabled: true },
     });
     res.json({ client_secret: paymentIntent.client_secret });
   });

   app.listen(4242, () => console.log('Server running on port 4242'));

   ─────────────────────────────────────────────────────────────────────────────
   ANDROID SETUP (android/app/build.gradle)
   ─────────────────────────────────────────────────────────────────────────────

   android {
     defaultConfig {
       minSdkVersion 21   // required by flutter_stripe
     }
   }

   ────────────────────────────────────────────────────────────────────────── */
