// lib/app.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/network/api_client.dart';
import 'core/utils/reset_password_token_cache.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/flights/providers/flight_booking_provider.dart';

class WanderlyApp extends StatefulWidget {
  final AuthProvider authProvider;
  final Uri? initialDeepLink;

  const WanderlyApp({
    super.key,
    required this.authProvider,
    this.initialDeepLink,
  });

  @override
  State<WanderlyApp> createState() => _WanderlyAppState();
}

class _WanderlyAppState extends State<WanderlyApp> {
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    if (widget.initialDeepLink != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLink(widget.initialDeepLink!);
      });
    }

    _linkSubscription = AppLinks().uriLinkStream.listen(
          _handleLink,
          onError: (_) {},
        );
  }

  Future<void> _handleLink(Uri uri) async {
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
    } else if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'] ?? '';
      if (token.isNotEmpty) {
        // ✅ Save token to cache — ResetPasswordScreen reads it from there.
        // This avoids the token being dropped if the navigator rebuilds,
        // and survives the splash → reset-password navigation sequence.
        await ResetPasswordTokenCache.save(token);
      }
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.resetPassword,
        (route) => false,
        // Still pass via arguments as a fallback — cache is the primary source.
        arguments: {'token': token},
      );
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
