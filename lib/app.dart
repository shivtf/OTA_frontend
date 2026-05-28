// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/flights/providers/flight_booking_provider.dart';

class WanderlyApp extends StatefulWidget {
  const WanderlyApp({super.key});

  @override
  State<WanderlyApp> createState() => _WanderlyAppState();
}

class _WanderlyAppState extends State<WanderlyApp> {
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks(); // ← replaces uni_links

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Cold start — app opened via deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleLink(initialUri);
    }

    // Warm start — link received while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (_) {},
    );
  }

  void _handleLink(Uri uri) {
    // otaapp://auth/verified?status=success
    // otaapp://auth/verified?status=error&message=...
    if (uri.host == 'auth' && uri.path == '/verified') {
      final status = uri.queryParameters['status'] ?? 'error';
      final message = uri.queryParameters['message'] ?? 'Verification failed.';
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.emailVerified,
        (route) => false,
        arguments: {'status': status, 'message': message},
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
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..tryAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => FlightBookingProvider(),
        ),
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
