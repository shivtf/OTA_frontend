// // lib/features/auth/screens/splash_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_sizes.dart';
// import '../../../core/constants/app_strings.dart';
// import '../../../core/routes/app_routes.dart';
// import '../../../core/theme/theme_controller.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   // Airplane launch animation
//   late AnimationController _launchController;
//   bool _isLaunching = false;
//
//   // We capture the plane's center position so the full-screen
//   // overlay can place the trail + plane exactly on top of it.
//   final GlobalKey _planeKey = GlobalKey();
//   Offset _planeCenter = Offset.zero;
//
//   int _currentPage = 0;
//
//   final List<Map<String, String>> _pages = [
//     {
//       'title': AppStrings.appFeatures,
//       'subtitle': AppStrings.appSubtitle,
//     },
//     {
//       'title': 'Discover the World',
//       'subtitle': 'Find the best deals on flights, hotels and car rentals.',
//     },
//     {
//       'title': 'Travel Smarter',
//       'subtitle': "Plan your perfect trip with Wanderly's smart tools.",
//     },
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 900),
//       vsync: this,
//     );
//     _fadeAnimation =
//         CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOutCubic,
//     ));
//
//     _fadeController.forward();
//     _slideController.forward();
//
//     // 1200 ms gives the trail time to look great
//     _launchController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _slideController.dispose();
//     _launchController.dispose();
//     super.dispose();
//   }
//
//   /// Measure where the plane icon sits on screen, then run the animation.
//   Future<void> _onGetStarted() async {
//     if (_isLaunching) return;
//
//     // Find the plane icon's position in global coordinates
//     final renderBox =
//     _planeKey.currentContext?.findRenderObject() as RenderBox?;
//     if (renderBox != null) {
//       final pos = renderBox.localToGlobal(Offset.zero);
//       final size = renderBox.size;
//       _planeCenter = Offset(pos.dx + size.width / 2, pos.dy + size.height / 2);
//     }
//
//     setState(() => _isLaunching = true);
//     await _launchController.forward();
//
//     if (mounted) {
//       Navigator.of(context).pushNamed(AppRoutes.login);
//       _launchController.reset();
//       setState(() => _isLaunching = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final themeController = context.watch<ThemeController>();
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final screenH = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Background ──────────────────────────────────────────────
//           _buildBackground(isDark),
//
//           // ── Decorative circles + stars ───────────────────────────────
//           _buildDecorativeElements(isDark),
//
//           // ── Main UI ──────────────────────────────────────────────────
//           SafeArea(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: Column(
//                 children: [
//                   _buildTopBar(context, themeController, isDark),
//                   const Spacer(),
//                   SlideTransition(
//                     position: _slideAnimation,
//                     child: _buildCenterContent(context, isDark),
//                   ),
//                   const Spacer(),
//                   _buildBottomSection(context, isDark),
//                 ],
//               ),
//             ),
//           ),
//
//           // ── Full-screen launch overlay (plane + trail) ───────────────
//           if (_isLaunching)
//             AnimatedBuilder(
//               animation: _launchController,
//               builder: (context, _) {
//                 final t = _launchController.value;
//
//                 // easeInQuart: slow start → rapid ascent (realistic takeoff)
//                 final curve = Curves.easeInQuart.transform(t);
//                 final planeY = _planeCenter.dy - curve * screenH * 1.15;
//                 final trailOpacity = (t < 0.85 ? 1.0 : (1.0 - t) / 0.15)
//                     .clamp(0.0, 1.0);
//                 // Trail length grows proportionally to how far the plane has moved
//                 final trailLength =
//                 (_planeCenter.dy - planeY).clamp(0.0, screenH);
//
//                 return Stack(
//                   children: [
//                     // ── Contrail ────────────────────────────────────────
//                     // Drawn from current plane position downward (behind it)
//                     Positioned(
//                       left: _planeCenter.dx - 18,
//                       top: planeY,
//                       child: Opacity(
//                         opacity: trailOpacity,
//                         child: CustomPaint(
//                           size: Size(36, trailLength),
//                           painter: _ContrailPainter(
//                             progress: t,
//                             trailLength: trailLength,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     // ── Plane icon (moves upward) ────────────────────────
//                     Positioned(
//                       left: _planeCenter.dx - 26,
//                       top: planeY - 26,
//                       child: const Icon(
//                         Icons.flight,
//                         color: Colors.white,
//                         size: 52,
//                       ),
//                     ),
//                   ],
//                 );
//               },
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBackground(bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: isDark
//             ? const LinearGradient(
//           colors: [
//             Color(0xFF060411),
//             Color(0xFF110B2E),
//             Color(0xFF2A1466),
//             Color(0xFF6C3CE1),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           stops: [0.0, 0.3, 0.65, 1.0],
//         )
//             : const LinearGradient(
//           colors: [
//             Color(0xFF1A0A4E),
//             Color(0xFF3D1FA0),
//             Color(0xFF6C3CE1),
//             Color(0xFF9B5CFF),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           stops: [0.0, 0.3, 0.7, 1.0],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDecorativeElements(bool isDark) {
//     return Stack(
//       children: [
//         // Top-right large circle
//         Positioned(
//           top: -80,
//           right: -60,
//           child: Container(
//             width: 260,
//             height: 260,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withValues(alpha:0.04),
//             ),
//           ),
//         ),
//         // Mid-left circle
//         Positioned(
//           top: 180,
//           left: -100,
//           child: Container(
//             width: 220,
//             height: 220,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withValues(alpha:0.03),
//             ),
//           ),
//         ),
//         // Stars pattern
//         ..._buildStars(),
//       ],
//     );
//   }
//
//   List<Widget> _buildStars() {
//     final positions = [
//       [60.0, 120.0],
//       [180.0, 80.0],
//       [280.0, 150.0],
//       [50.0, 300.0],
//       [320.0, 260.0],
//       [140.0, 220.0],
//     ];
//     return positions.map((pos) {
//       return Positioned(
//         left: pos[0],
//         top: pos[1],
//         child: Container(
//           width: 3,
//           height: 3,
//           decoration: const BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white54,
//           ),
//         ),
//       );
//     }).toList();
//   }
//
//   Widget _buildTopBar(
//       BuildContext context, ThemeController tc, bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//         horizontal: AppSizes.paddingLG,
//         vertical: AppSizes.paddingMD,
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Language selector
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha:0.15),
//               borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
//               border:
//               Border.all(color: Colors.white.withValues(alpha:0.25), width: 1),
//             ),
//             child: const Text(
//               AppStrings.languageSelector,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: AppSizes.fontSM,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//
//           // Theme toggle
//           GestureDetector(
//             onTap: tc.toggleTheme,
//             child: Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 color: Colors.white.withValues(alpha:0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                     color: Colors.white.withValues(alpha:0.25), width: 1),
//               ),
//               child: Icon(
//                 isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
//                 color: Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCenterContent(BuildContext context, bool isDark) {
//     return Column(
//       children: [
//         // Ring stays completely static. Plane icon gets a GlobalKey so we
//         // can measure its screen position before the overlay takes over.
//         SizedBox(
//           width: 110,
//           height: 110,
//           child: Stack(
//             alignment: Alignment.center,
//             clipBehavior: Clip.none,
//             children: [
//               // Static glowing ring
//               Container(
//                 width: 110,
//                 height: 110,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white.withValues(alpha:0.12),
//                   border: Border.all(
//                       color: Colors.white.withValues(alpha:0.2), width: 1),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.white.withValues(alpha:0.15),
//                       blurRadius: 40,
//                       spreadRadius: 10,
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Clouds — appear when launching
//               if (_isLaunching)
//                 AnimatedBuilder(
//                   animation: _launchController,
//                   builder: (context, _) {
//                     final t = _launchController.value;
//                     return Stack(
//                       clipBehavior: Clip.none,
//                       children: [
//                         Positioned(
//                           left: -60 + (t * 18),
//                           top: 28 + (t * -12),
//                           child: Opacity(
//                             opacity: (t * 1.8).clamp(0.0, 0.7),
//                             child: _CloudShape(
//                                 width: 52, height: 22, opacity: 0.55),
//                           ),
//                         ),
//                         Positioned(
//                           right: -56 + (t * 14),
//                           top: 38 + (t * -8),
//                           child: Opacity(
//                             opacity: (t * 1.6).clamp(0.0, 0.6),
//                             child: _CloudShape(
//                                 width: 44, height: 18, opacity: 0.45),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//
//               // Plane icon — hidden during launch (overlay takes over)
//               Opacity(
//                 opacity: _isLaunching ? 0.0 : 1.0,
//                 child: Icon(
//                   Icons.flight,
//                   key: _planeKey,
//                   color: Colors.white,
//                   size: 52,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: AppSizes.paddingXL),
//
//         // App name
//         const Text(
//           AppStrings.appName,
//           style: TextStyle(
//             fontSize: 44,
//             fontWeight: FontWeight.w900,
//             color: Colors.white,
//             letterSpacing: 3,
//           ),
//         ),
//
//         const SizedBox(height: AppSizes.paddingSM),
//
//         // Tagline
//         Text(
//           AppStrings.appTagline,
//           style: TextStyle(
//             fontSize: AppSizes.fontMD,
//             color: Colors.white.withValues(alpha:0.8),
//             fontWeight: FontWeight.w400,
//             letterSpacing: 1.5,
//           ),
//         ),
//
//         const SizedBox(height: AppSizes.paddingXXL),
//
//         // Page indicator dots
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(
//             _pages.length,
//                 (i) => GestureDetector(
//               onTap: () => setState(() => _currentPage = i),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 250),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 width: _currentPage == i ? 24 : 8,
//                 height: 8,
//                 decoration: BoxDecoration(
//                   color: _currentPage == i
//                       ? Colors.white
//                       : Colors.white.withValues(alpha:0.35),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//             ),
//           ),
//         ),
//
//         const SizedBox(height: AppSizes.paddingLG),
//
//         // Dynamic title/subtitle
//         AnimatedSwitcher(
//           duration: const Duration(milliseconds: 300),
//           child: Column(
//             key: ValueKey(_currentPage),
//             children: [
//               Text(
//                 _pages[_currentPage]['title']!,
//                 style: const TextStyle(
//                   fontSize: AppSizes.fontLG,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                     horizontal: AppSizes.paddingXXL),
//                 child: Text(
//                   _pages[_currentPage]['subtitle']!,
//                   style: TextStyle(
//                     fontSize: AppSizes.fontMD,
//                     color: Colors.white.withValues(alpha:0.7),
//                     height: 1.5,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBottomSection(BuildContext context, bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(
//         AppSizes.paddingLG,
//         0,
//         AppSizes.paddingLG,
//         AppSizes.paddingXL,
//       ),
//       child: Column(
//         children: [
//           // Get Started button with white style
//           GestureDetector(
//             onTap: _onGetStarted,
//             child: Container(
//               height: AppSizes.buttonHeight,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius:
//                 BorderRadius.circular(AppSizes.radiusMedium),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha:0.25),
//                     blurRadius: 20,
//                     offset: const Offset(0, 8),
//                   ),
//                 ],
//               ),
//               child: const Center(
//                 child: Text(
//                   AppStrings.getStarted,
//                   style: TextStyle(
//                     fontSize: AppSizes.fontMD,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.primaryStart,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: AppSizes.paddingLG),
//
//           // Trusted by travelers
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.verified_rounded,
//                   color: Colors.white.withValues(alpha:0.6), size: 14),
//               const SizedBox(width: 6),
//               Text(
//                 AppStrings.trustedBy,
//                 style: TextStyle(
//                   color: Colors.white.withValues(alpha:0.6),
//                   fontSize: AppSizes.fontSM,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Cloud shape widget drawn with CustomPaint
// class _CloudShape extends StatelessWidget {
//   final double width;
//   final double height;
//   final double opacity;
//
//   const _CloudShape({
//     required this.width,
//     required this.height,
//     required this.opacity,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: Size(width, height),
//       painter: _CloudPainter(opacity: opacity),
//     );
//   }
// }
//
// class _CloudPainter extends CustomPainter {
//   final double opacity;
//   const _CloudPainter({required this.opacity});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withValues(alpha:opacity)
//       ..style = PaintingStyle.fill;
//
//     final w = size.width;
//     final h = size.height;
//     final path = Path();
//
//     // Base bar
//     path.addRRect(RRect.fromRectAndRadius(
//       Rect.fromLTWH(0, h * 0.4, w, h * 0.6),
//       Radius.circular(h * 0.3),
//     ));
//     // Left bump
//     path.addOval(Rect.fromCircle(
//       center: Offset(w * 0.25, h * 0.42),
//       radius: h * 0.32,
//     ));
//     // Center bump (tallest)
//     path.addOval(Rect.fromCircle(
//       center: Offset(w * 0.52, h * 0.28),
//       radius: h * 0.38,
//     ));
//     // Right bump
//     path.addOval(Rect.fromCircle(
//       center: Offset(w * 0.76, h * 0.45),
//       radius: h * 0.28,
//     ));
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant _CloudPainter old) => old.opacity != opacity;
// }
//
// /// Contrail painter — drawn in a box whose top is the current plane position
// /// and whose bottom is the original starting position.  The gradient goes
// /// from opaque at the TOP (where the plane is right now) to transparent at
// /// the BOTTOM (the old position), so it always trails BEHIND the aircraft.
// class _ContrailPainter extends CustomPainter {
//   final double progress;
//   final double trailLength;
//
//   const _ContrailPainter({
//     required this.progress,
//     required this.trailLength,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (trailLength < 2) return;
//
//     final w = size.width;
//     final h = size.height;
//     final cx = w / 2;
//
//     // ── Core streak ─────────────────────────────────────────────────────
//     // Solid at top (fresh exhaust near the engine), dissolves downward.
//     final coreGradient = LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Colors.white.withValues(alpha:0.90),
//         Colors.white.withValues(alpha:0.55),
//         Colors.white.withValues(alpha:0.15),
//         Colors.white.withValues(alpha:0.0),
//       ],
//       stops: const [0.0, 0.25, 0.65, 1.0],
//     );
//
//     final coreRect = Rect.fromLTWH(0, 0, w, h);
//     final corePaint = Paint()
//       ..shader = coreGradient.createShader(coreRect)
//       ..strokeCap = StrokeCap.round;
//
//     // Taper: 5 px wide at the top (near plane) → 1 px at bottom
//     // We draw a filled tapered polygon.
//     final topHalfW = 5.0;
//     final bottomHalfW = (1.5 * (1 - progress * 0.5)).clamp(0.5, 1.5);
//
//     final corePath = Path()
//       ..moveTo(cx - topHalfW, 0)
//       ..lineTo(cx + topHalfW, 0)
//       ..lineTo(cx + bottomHalfW, h)
//       ..lineTo(cx - bottomHalfW, h)
//       ..close();
//
//     canvas.drawPath(corePath, corePaint);
//
//     // ── Left wing-tip vortex ─────────────────────────────────────────────
//     // Starts from top-left of the core and curves outward as it descends
//     // (real contrails spread sideways over time).
//     final leftGradient = LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: [
//         Colors.white.withValues(alpha:0.45),
//         Colors.white.withValues(alpha:0.12),
//         Colors.white.withValues(alpha:0.0),
//       ],
//       stops: const [0.0, 0.5, 1.0],
//     );
//     final leftPaint = Paint()
//       ..shader = leftGradient.createShader(coreRect);
//
//     final leftPath = Path()
//       ..moveTo(cx - topHalfW, 0)
//       ..quadraticBezierTo(cx - 14, h * 0.4, cx - 18, h * 0.8)
//       ..quadraticBezierTo(cx - 12, h * 0.45, cx - topHalfW + 1, h * 0.05)
//       ..close();
//     canvas.drawPath(leftPath, leftPaint);
//
//     // ── Right wing-tip vortex ────────────────────────────────────────────
//     final rightPaint = Paint()
//       ..shader = leftGradient.createShader(coreRect); // same gradient
//
//     final rightPath = Path()
//       ..moveTo(cx + topHalfW, 0)
//       ..quadraticBezierTo(cx + 14, h * 0.4, cx + 18, h * 0.8)
//       ..quadraticBezierTo(cx + 12, h * 0.45, cx + topHalfW - 1, h * 0.05)
//       ..close();
//     canvas.drawPath(rightPath, rightPaint);
//
//     // ── Soft glow halo around core ───────────────────────────────────────
//     final glowPaint = Paint()
//       ..shader = LinearGradient(
//         begin: Alignment.topCenter,
//         end: Alignment.bottomCenter,
//         colors: [
//           Colors.white.withValues(alpha:0.18),
//           Colors.white.withValues(alpha:0.0),
//         ],
//         stops: const [0.0, 0.4],
//       ).createShader(coreRect)
//       ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
//
//     final glowPath = Path()
//       ..moveTo(cx - 12, 0)
//       ..lineTo(cx + 12, 0)
//       ..lineTo(cx + 4, h * 0.4)
//       ..lineTo(cx - 4, h * 0.4)
//       ..close();
//     canvas.drawPath(glowPath, glowPaint);
//   }
//
//   @override
//   bool shouldRepaint(covariant _ContrailPainter old) =>
//       old.progress != progress || old.trailLength != trailLength;
// }
//
//

// lib/features/auth/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Airplane launch animation
  late AnimationController _launchController;
  bool _isLaunching = false;

  // We capture the plane's center position so the full-screen
  // overlay can place the trail + plane exactly on top of it.
  final GlobalKey _planeKey = GlobalKey();
  Offset _planeCenter = Offset.zero;

  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _pages = [
    {
      'title': AppStrings.appFeatures,
      'subtitle': AppStrings.appSubtitle,
    },
    {
      'title': 'Discover the World',
      'subtitle': 'Find the best deals on flights, hotels and car rentals.',
    },
    {
      'title': 'Travel Smarter',
      'subtitle': "Plan your perfect trip with Wanderly's smart tools.",
    },
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    // Auto-advance page dots every 3 seconds
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % _pages.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    // 1200 ms gives the trail time to look great
    _launchController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _launchController.dispose();
    super.dispose();
  }

  /// Measure where the plane icon sits on screen, then run the animation.
  Future<void> _onGetStarted() async {
    if (_isLaunching) return;

    // Find the plane icon's position in global coordinates
    final renderBox =
    _planeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final pos = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      _planeCenter = Offset(pos.dx + size.width / 2, pos.dy + size.height / 2);
    }

    setState(() => _isLaunching = true);
    await _launchController.forward();

    if (mounted) {
      Navigator.of(context).pushNamed(AppRoutes.login);
      _launchController.reset();
      setState(() => _isLaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ──────────────────────────────────────────────
          _buildBackground(isDark),

          // ── Decorative circles + stars ───────────────────────────────
          _buildDecorativeElements(isDark),

          // ── Main UI ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildTopBar(context, themeController, isDark),
                  const Spacer(),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildCenterContent(context, isDark),
                  ),
                  const Spacer(),
                  _buildBottomSection(context, isDark),
                ],
              ),
            ),
          ),

          // ── Full-screen launch overlay (plane + trail) ───────────────
          if (_isLaunching)
            AnimatedBuilder(
              animation: _launchController,
              builder: (context, _) {
                final t = _launchController.value;

                // easeInQuart: slow start → rapid ascent (realistic takeoff)
                final curve = Curves.easeInQuart.transform(t);
                final planeY = _planeCenter.dy - curve * screenH * 1.15;
                final trailOpacity = (t < 0.85 ? 1.0 : (1.0 - t) / 0.15)
                    .clamp(0.0, 1.0);
                // Trail length grows proportionally to how far the plane has moved
                final trailLength =
                (_planeCenter.dy - planeY).clamp(0.0, screenH);

                return Stack(
                  children: [
                    // ── Contrail ────────────────────────────────────────
                    // Drawn from current plane position downward (behind it)
                    Positioned(
                      left: _planeCenter.dx - 18,
                      top: planeY,
                      child: Opacity(
                        opacity: trailOpacity,
                        child: CustomPaint(
                          size: Size(36, trailLength),
                          painter: _ContrailPainter(
                            progress: t,
                            trailLength: trailLength,
                          ),
                        ),
                      ),
                    ),

                    // ── Plane icon (moves upward) ────────────────────────
                    Positioned(
                      left: _planeCenter.dx - 26,
                      top: planeY - 26,
                      child: const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          colors: [
            Color(0xFF060411),
            Color(0xFF110B2E),
            Color(0xFF2A1466),
            Color(0xFF6C3CE1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.65, 1.0],
        )
            : const LinearGradient(
          colors: [
            Color(0xFF1A0A4E),
            Color(0xFF3D1FA0),
            Color(0xFF6C3CE1),
            Color(0xFF9B5CFF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(bool isDark) {
    return Stack(
      children: [
        // Top-right large circle
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha:0.04),
            ),
          ),
        ),
        // Mid-left circle
        Positioned(
          top: 180,
          left: -100,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha:0.03),
            ),
          ),
        ),
        // Stars pattern
        ..._buildStars(),
      ],
    );
  }

  List<Widget> _buildStars() {
    final positions = [
      [60.0, 120.0],
      [180.0, 80.0],
      [280.0, 150.0],
      [50.0, 300.0],
      [320.0, 260.0],
      [140.0, 220.0],
    ];
    return positions.map((pos) {
      return Positioned(
        left: pos[0],
        top: pos[1],
        child: Container(
          width: 3,
          height: 3,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white54,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTopBar(
      BuildContext context, ThemeController tc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingLG,
        vertical: AppSizes.paddingMD,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
              border:
              Border.all(color: Colors.white.withValues(alpha:0.25), width: 1),
            ),
            child: const Text(
              AppStrings.languageSelector,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Theme toggle
          GestureDetector(
            onTap: tc.toggleTheme,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withValues(alpha:0.25), width: 1),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Ring stays completely static. Plane icon gets a GlobalKey so we
        // can measure its screen position before the overlay takes over.
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Static glowing ring
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha:0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha:0.15),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // Clouds — appear when launching
              if (_isLaunching)
                AnimatedBuilder(
                  animation: _launchController,
                  builder: (context, _) {
                    final t = _launchController.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: -60 + (t * 18),
                          top: 28 + (t * -12),
                          child: Opacity(
                            opacity: (t * 1.8).clamp(0.0, 0.7),
                            child: _CloudShape(
                                width: 52, height: 22, opacity: 0.55),
                          ),
                        ),
                        Positioned(
                          right: -56 + (t * 14),
                          top: 38 + (t * -8),
                          child: Opacity(
                            opacity: (t * 1.6).clamp(0.0, 0.6),
                            child: _CloudShape(
                                width: 44, height: 18, opacity: 0.45),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              // Plane icon — hidden during launch (overlay takes over)
              Opacity(
                opacity: _isLaunching ? 0.0 : 1.0,
                child: Icon(
                  Icons.flight,
                  key: _planeKey,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSizes.paddingXL),

        // App name
        const Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: AppSizes.paddingSM),

        // Tagline
        Text(
          AppStrings.appTagline,
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            color: Colors.white.withValues(alpha:0.8),
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: AppSizes.paddingXXL),

        // Static page indicator dots (stay fixed, only text below slides)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
                (dotIndex) => GestureDetector(
              onTap: () {
                _autoAdvanceTimer?.cancel();
                _pageController.animateToPage(
                  dotIndex,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
                _autoAdvanceTimer = Timer.periodic(
                  const Duration(seconds: 3),
                      (_) {
                    if (!mounted) return;
                    final next = (_currentPage + 1) % _pages.length;
                    _pageController.animateToPage(
                      next,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == dotIndex ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == dotIndex
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.paddingLG),

        // Sliding text — only this part moves
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXXL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    _pages[i]['title']!,
                    style: const TextStyle(
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pages[i]['subtitle']!,
                    style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLG,
        0,
        AppSizes.paddingLG,
        AppSizes.paddingXL,
      ),
      child: Column(
        children: [
          // Get Started button with white style
          GestureDetector(
            onTap: _onGetStarted,
            child: Container(
              height: AppSizes.buttonHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(AppSizes.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  AppStrings.getStarted,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryStart,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.paddingLG),

          // Trusted by travelers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded,
                  color: Colors.white.withValues(alpha:0.6), size: 14),
              const SizedBox(width: 6),
              Text(
                AppStrings.trustedBy,
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.6),
                  fontSize: AppSizes.fontSM,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Cloud shape widget drawn with CustomPaint
class _CloudShape extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;

  const _CloudShape({
    required this.width,
    required this.height,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _CloudPainter(opacity: opacity),
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double opacity;
  const _CloudPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:opacity)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path();

    // Base bar
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.4, w, h * 0.6),
      Radius.circular(h * 0.3),
    ));
    // Left bump
    path.addOval(Rect.fromCircle(
      center: Offset(w * 0.25, h * 0.42),
      radius: h * 0.32,
    ));
    // Center bump (tallest)
    path.addOval(Rect.fromCircle(
      center: Offset(w * 0.52, h * 0.28),
      radius: h * 0.38,
    ));
    // Right bump
    path.addOval(Rect.fromCircle(
      center: Offset(w * 0.76, h * 0.45),
      radius: h * 0.28,
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter old) => old.opacity != opacity;
}

/// Contrail painter — drawn in a box whose top is the current plane position
/// and whose bottom is the original starting position.  The gradient goes
/// from opaque at the TOP (where the plane is right now) to transparent at
/// the BOTTOM (the old position), so it always trails BEHIND the aircraft.
class _ContrailPainter extends CustomPainter {
  final double progress;
  final double trailLength;

  const _ContrailPainter({
    required this.progress,
    required this.trailLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trailLength < 2) return;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // ── Core streak ─────────────────────────────────────────────────────
    // Solid at top (fresh exhaust near the engine), dissolves downward.
    final coreGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha:0.90),
        Colors.white.withValues(alpha:0.55),
        Colors.white.withValues(alpha:0.15),
        Colors.white.withValues(alpha:0.0),
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    );

    final coreRect = Rect.fromLTWH(0, 0, w, h);
    final corePaint = Paint()
      ..shader = coreGradient.createShader(coreRect)
      ..strokeCap = StrokeCap.round;

    // Taper: 5 px wide at the top (near plane) → 1 px at bottom
    // We draw a filled tapered polygon.
    final topHalfW = 5.0;
    final bottomHalfW = (1.5 * (1 - progress * 0.5)).clamp(0.5, 1.5);

    final corePath = Path()
      ..moveTo(cx - topHalfW, 0)
      ..lineTo(cx + topHalfW, 0)
      ..lineTo(cx + bottomHalfW, h)
      ..lineTo(cx - bottomHalfW, h)
      ..close();

    canvas.drawPath(corePath, corePaint);

    // ── Left wing-tip vortex ─────────────────────────────────────────────
    // Starts from top-left of the core and curves outward as it descends
    // (real contrails spread sideways over time).
    final leftGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha:0.45),
        Colors.white.withValues(alpha:0.12),
        Colors.white.withValues(alpha:0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final leftPaint = Paint()
      ..shader = leftGradient.createShader(coreRect);

    final leftPath = Path()
      ..moveTo(cx - topHalfW, 0)
      ..quadraticBezierTo(cx - 14, h * 0.4, cx - 18, h * 0.8)
      ..quadraticBezierTo(cx - 12, h * 0.45, cx - topHalfW + 1, h * 0.05)
      ..close();
    canvas.drawPath(leftPath, leftPaint);

    // ── Right wing-tip vortex ────────────────────────────────────────────
    final rightPaint = Paint()
      ..shader = leftGradient.createShader(coreRect); // same gradient

    final rightPath = Path()
      ..moveTo(cx + topHalfW, 0)
      ..quadraticBezierTo(cx + 14, h * 0.4, cx + 18, h * 0.8)
      ..quadraticBezierTo(cx + 12, h * 0.45, cx + topHalfW - 1, h * 0.05)
      ..close();
    canvas.drawPath(rightPath, rightPaint);

    // ── Soft glow halo around core ───────────────────────────────────────
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha:0.18),
          Colors.white.withValues(alpha:0.0),
        ],
        stops: const [0.0, 0.4],
      ).createShader(coreRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final glowPath = Path()
      ..moveTo(cx - 12, 0)
      ..lineTo(cx + 12, 0)
      ..lineTo(cx + 4, h * 0.4)
      ..lineTo(cx - 4, h * 0.4)
      ..close();
    canvas.drawPath(glowPath, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ContrailPainter old) =>
      old.progress != progress || old.trailLength != trailLength;
}