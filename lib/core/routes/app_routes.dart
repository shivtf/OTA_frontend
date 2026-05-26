// lib/core/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/registration_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/flights/screens/flight_search_screen.dart';
import '../../features/flights/screens/flight_results_screen.dart';
import '../../features/flights/screens/flight_details_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash       = '/';
  static const String login        = '/login';
  static const String signup       = '/signup';
  static const String registration = '/registration';
  static const String home         = '/home';
  static const String flightSearch  = '/flights/search';
  static const String flightResults = '/flights/results';
  static const String flightDetails = '/flights/details';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:        return _fade(const SplashScreen(), settings);
      case login:         return _fade(const LoginScreen(), settings);
      case signup:        return _fade(const SignupScreen(), settings);
      case registration:  return _fade(const RegistrationScreen(), settings);
      //case home:          return _fade(const HomeSearchBar(), settings);
      case flightSearch:  return _slide(const FlightSearchScreen(), settings);
      case flightResults: return _slide(const FlightResultsScreen(), settings);
      case flightDetails: return _slide(const FlightDetailsScreen(), settings);
      default:            return _fade(const SplashScreen(), settings);
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
}