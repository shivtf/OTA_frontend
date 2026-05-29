// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/flights/models/flight_model.dart';
import '../../../shared/widgets/wanderly_nav_bar.dart';
import '../widgets/deal_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/home_search_bar.dart';
import '../../home/widgets/quick_category_row.dart';
import '../../profiles/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(isDark: isDark, tc: tc),
          // Flights tab → tapping nav goes to flight search
          _PlaceholderTab(
              icon: Icons.flight_rounded, label: 'Flights', isDark: isDark),
          _PlaceholderTab(
              icon: Icons.hotel_rounded, label: 'Hotels', isDark: isDark),
          _PlaceholderTab(
              icon: Icons.directions_car_rounded,
              label: 'Cars',
              isDark: isDark),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: WanderlyNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pushNamed(AppRoutes.flightSearch);
            return;
          }
          if (i == 2) {
            Navigator.of(context).pushNamed(AppRoutes.hotelSearch);
            return;
          }
          if (i == 3) {
            Navigator.of(context).pushNamed(AppRoutes.carSearch);
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}

// ─── Main Home Tab ────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final bool isDark;
  final ThemeController tc;
  const _HomeTab({required this.isDark, required this.tc});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header with greeting + avatar
        SliverToBoxAdapter(child: _HomeHeader(isDark: isDark, tc: tc)),

        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: HomeSearchBar(isDark: isDark),
          ),
        ),

        // Quick categories
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: QuickCategoryRow(isDark: isDark),
          ),
        ),

        // Popular destinations
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Destinations',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              itemCount: FlightData.popularDestinations.length,
              itemBuilder: (ctx, i) => DestinationCard(
                destination: FlightData.popularDestinations[i],
                isDark: isDark,
              ),
            ),
          ),
        ),

        // Hot deals
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hot Deals ✈️',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.flightSearch),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final flights = FlightData.search(from: '', to: '');
              if (i >= flights.length) return null;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: DealCard(flight: flights[i], isDark: isDark),
              );
            },
            childCount: 3,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final bool isDark;
  final ThemeController tc;
  const _HomeHeader({required this.isDark, required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF9B5CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avatar + theme toggle
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            fontSize: AppSizes.fontSM,
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Where to next? 🌍',
                          style: TextStyle(
                            fontSize: AppSizes.fontXXL,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle
                  GestureDetector(
                    onTap: tc.toggleTheme,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _StatChip(
                      icon: Icons.flight_takeoff_rounded, label: '12 Trips'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.star_rounded, label: '4.9 Rating'),
                  const SizedBox(width: 10),
                  _StatChip(
                      icon: Icons.location_on_rounded, label: '8 Countries'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, Traveler 👋';
    if (h < 17) return 'Good afternoon, Traveler 👋';
    return 'Good evening, Traveler 👋';
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder tabs ─────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _PlaceholderTab(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            '$label\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature is under construction.',
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
