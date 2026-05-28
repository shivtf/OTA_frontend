// lib/main.dart
//
// Entry point for Wanderly travel app.
// Initializes Stripe and launches the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'features/payment/models/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Stripe
  // TODO: Replace with your actual Stripe publishable key from
  // https://dashboard.stripe.com/test/apikeys
  StripeService.init();

  runApp(const WanderlyApp());
}
