// lib/core/routes/app_routes.dart
//
// Updated to include:
//   • /auth/forgot-password  — forgot password screen
//   • /auth/reset-password   — reset password (opened via deep link)
//   • /auth/email-verified   — email verification deep-link target
//   • /flights/seat-map      — seat selection screen
//   • Deep link handler via onGenerateRoute parsing

import 'package:flutter/material.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/email_verified_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart'; // ← NEW
import '../../features/auth/screens/reset_password_screen.dart'; // ← NEW
import '../../features/home/screens/home_screen.dart';
import '../../features/flights/screens/flight_search_screen.dart';
import '../../features/flights/screens/flight_results_screen.dart';
import '../../features/flights/screens/flight_details_screen.dart';
import '../../features/flights/screens/passenger_form_screen.dart';
import '../../features/flights/screens/seat_map_screen.dart';
import '../../features/hotels/screens/hotel_search_screen.dart';
import '../../features/hotels/screens/hotel_results_screen.dart';
import '../../features/hotels/screens/hotel_details_screen.dart';
import '../../features/cars/screens/car_search_screen.dart';
import '../../features/cars/screens/car_results_screen.dart';
import '../../features/cars/screens/car_details_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/payment/screens/payment_success_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String registration = '/registration';
  static const String emailVerified = '/auth/email-verified';
  static const String forgotPassword = '/auth/forgot-password'; // ← NEW
  static const String resetPassword = '/auth/reset-password'; // ← NEW
  static const String home = '/home';
  static const String flightSearch = '/flights/search';
  static const String flightResults = '/flights/results';
  static const String flightDetails = '/flights/details';
  static const String passengerForm = '/flights/passenger-form';
  static const String seatMap = '/flights/seat-map';
  static const String hotelSearch = '/hotels/search';
  static const String hotelResults = '/hotels/results';
  static const String hotelDetails = '/hotels/details';
  static const String carSearch = '/cars/search';
  static const String carResults = '/cars/results';
  static const String carDetails = '/cars/details';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment/success';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // ── Deep link: otaapp://auth/verified?status=success ──────────────────────
    if (settings.name != null &&
        settings.name!.startsWith('/auth/reset-password')) {
      // Token may come from arguments (navigator push) OR query params (raw deep link)
      String token = '';

      final args = settings.arguments;
      if (args is Map && args['token'] != null) {
        token = args['token'] as String; // ← from _handleLink via arguments
      } else {
        final uri = Uri.tryParse(settings.name!);
        token = uri?.queryParameters['token'] ??
            ''; // ← fallback for raw route name
      }

      return _slide(
        const ResetPasswordScreen(),
        RouteSettings(
          name: resetPassword,
          arguments: {'token': token},
        ),
      );
    }

    // ── Deep link: otaapp://auth/reset-password?token=<TOKEN> ────────────────
    // The backend email uses this scheme. Flutter receives it as a route name.
    if (settings.name != null &&
        settings.name!.startsWith('/auth/reset-password')) {
      final uri = Uri.tryParse(settings.name!);
      final token = uri?.queryParameters['token'] ?? '';
      return _slide(
        const ResetPasswordScreen(),
        RouteSettings(
          name: resetPassword,
          arguments: {'token': token},
        ),
      );
    }

    switch (settings.name) {
      case splash:
        return _fade(const SplashScreen(), settings);
      case login:
        return _fade(const LoginScreen(), settings);
      case signup:
        return _fade(const SignupScreen(), settings);
      case registration:
        return _fade(const RegistrationScreen(), settings);
      case emailVerified:
        return _fade(const EmailVerifiedScreen(), settings);
      case forgotPassword: // ← NEW
        return _slide(const ForgotPasswordScreen(), settings);
      case resetPassword: // ← NEW
        return _slide(const ResetPasswordScreen(), settings);
      case home:
        return _fade(const HomeScreen(), settings);
      case flightSearch:
        return _slide(const FlightSearchScreen(), settings);
      case flightResults:
        return _slide(const FlightResultsScreen(), settings);
      case flightDetails:
        return _slide(const FlightDetailsScreen(), settings);
      case passengerForm:
        return _slide(const PassengerFormScreen(), settings);
      case seatMap:
        return _slideUp(const SeatMapScreen(), settings);
      case hotelSearch:
        return _slide(const HotelSearchScreen(), settings);
      case hotelResults:
        return _slide(const HotelResultsScreen(), settings);
      case hotelDetails:
        return _slide(const HotelDetailsScreen(), settings);
      case carSearch:
        return _slide(const CarSearchScreen(), settings);
      case carResults:
        return _slide(const CarResultsScreen(), settings);
      case carDetails:
        return _slide(const CarDetailsScreen(), settings);
      case payment:
        return _slideUp(const PaymentScreen(), settings);
      case paymentSuccess:
        return _fade(const PaymentSuccessScreen(), settings);
      default:
        return _fade(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _fade(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder _slide(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  static PageRouteBuilder _slideUp(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        return SlideTransition(position: slide, child: child);
      },
      transitionDuration: const Duration(milliseconds: 380),
    );
  }
}
