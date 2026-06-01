// lib/app.dart
//
// Root widget. Registers all ChangeNotifier providers including
// PaymentController — which auto-selects the active payment provider
// from AppConfig.paymentGateway.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/network/api_client.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/flights/providers/flight_booking_provider.dart';
import 'features/payment/controllers/payment_controller.dart'; // ← NEW

class WanderlyApp extends StatefulWidget {
  final AuthProvider authProvider;
  const WanderlyApp({super.key, required this.authProvider});

  @override
  State<WanderlyApp> createState() => _WanderlyAppState();
}

class _WanderlyAppState extends State<WanderlyApp> {
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleLink(initialUri);

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (_) {},
    );
  }

  void _handleLink(Uri uri) {
    if (uri.host != 'auth') return;

    if (uri.path == '/verified') {
      final status = uri.queryParameters['status'] ?? 'error';
      final message = uri.queryParameters['message'] ?? 'Verification failed.';
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.emailVerified,
        (route) => false,
        arguments: {'status': status, 'message': message},
      );
    } else if (uri.path == '/verify') {
      final token = uri.queryParameters['token'] ?? '';
      _verifyTokenAndNavigate(token);
    }
  }

  Future<void> _verifyTokenAndNavigate(String token) async {
    try {
      await ApiClient.instance.post(
        '/auth/verify-email-token',
        {'token': token},
      );
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.emailVerified,
        (route) => false,
        arguments: {'status': 'success'},
      );
    } catch (_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.emailVerified,
        (route) => false,
        arguments: {
          'status': 'error',
          'message': 'Verification failed. The link may have expired.',
        },
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider.value(value: widget.authProvider),
        ChangeNotifierProvider(create: (_) => FlightBookingProvider()),
        // ── PaymentController: auto-selects provider from AppConfig ─────────
        // Changing AppConfig.paymentGateway is the ONLY required change
        // to switch payment providers in production.
        ChangeNotifierProvider(create: (_) => PaymentController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'Wanderly',
            debugShowCheckedModeBanner: false,
            navigatorKey: _navigatorKey,
            themeMode: themeController.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
