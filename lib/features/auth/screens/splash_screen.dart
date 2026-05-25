// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../widgets/gradient_button.dart';

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

  int _currentPage = 0;

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
      'subtitle': 'Plan your perfect trip with Wanderly\'s smart tools.',
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          _buildBackground(isDark),

          // Floating decorative circles
          _buildDecorativeElements(isDark),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Top bar: theme toggle + language
                  _buildTopBar(context, themeController, isDark),

                  const Spacer(),

                  // Center: logo + airplane visual
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildCenterContent(context, isDark),
                  ),

                  const Spacer(),

                  // Bottom section
                  _buildBottomSection(context, isDark),
                ],
              ),
            ),
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
              color: Colors.white.withOpacity(0.04),
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
              color: Colors.white.withOpacity(0.03),
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
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
              border:
              Border.all(color: Colors.white.withOpacity(0.25), width: 1),
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
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1),
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
        // Big airplane icon with glow
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.flight,
            color: Colors.white,
            size: 52,
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
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
          ),
        ),

        const SizedBox(height: AppSizes.paddingXXL),

        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _pages.length,
                (i) => GestureDetector(
              onTap: () => setState(() => _currentPage = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? Colors.white
                      : Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.paddingLG),

        // Dynamic title/subtitle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_currentPage),
            children: [
              Text(
                _pages[_currentPage]['title']!,
                style: const TextStyle(
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingXXL),
                child: Text(
                  _pages[_currentPage]['subtitle']!,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.login),
            child: Container(
              height: AppSizes.buttonHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(AppSizes.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
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
                  color: Colors.white.withOpacity(0.6), size: 14),
              const SizedBox(width: 6),
              Text(
                AppStrings.trustedBy,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
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