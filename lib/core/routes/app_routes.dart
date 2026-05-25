import 'package:flutter/material.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/registration_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String registration = '/registration';

  static Map<String, WidgetBuilder> get routes =>{
    splash:(_) => const SplashScreen(),
    login:(_) => const LoginScreen(),
    signup:(_) => const SignupScreen(),
    registration:(_) => const RegistrationScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case login:
        return _buildRoute(const LoginScreen(), settings);
      case signup:
        return _buildRoute(const SignupScreen(), settings);
      case registration:
        return _buildRoute(const RegistrationScreen(), settings);
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings){
    return PageRouteBuilder(
      settings: settings,
      pageBuilder:(_,__,___) => page,
      transitionsBuilder:(_,animation,__,child){
        return FadeTransition
          (opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child:child,
        );
      },
        transitionDuration: const Duration(milliseconds: 300),
    );
  }
}