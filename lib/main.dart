// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'package:wanderly/app.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/payment/models/stripe_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  StripeService.init();

  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  // Resolve the initial deep link before runApp so it is available
  // synchronously when the first frame builds — no race condition.
  Uri? initialDeepLink = await AppLinks().getInitialLink().catchError((_) => null);

  runApp(WanderlyApp(
    authProvider: authProvider,
    initialDeepLink: initialDeepLink,
  ));
}