// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
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

  // ✅ Await auto-login BEFORE runApp so isLoggedIn is ready immediately
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(WanderlyApp(authProvider: authProvider)); // ✅ pass it in
}