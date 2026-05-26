// lib/features/flights/screens/flight_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/flight_model.dart';
import '../widgets/flight_card.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/sort_bottom_sheet.dart';

class FlightResultsScreen extends StatefulWidget {
  const FlightResultsScreen({super.key});

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen>
    with SingleTickerProviderStateMixin {
  late List<FlightModel> _flights;
  String _sortBy = 'Cheapest';
  Set<String> _activeFilters = {};
  bool _isLoading = true;

  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadFlights();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _flights = FlightData.search(from: 'DEL', to: 'DXB');
        _isLoading = false;
      });
      _listController.forward();
    }
  }

  List<FlightModel> get _filtered {
    var list = List<FlightModel>.from(_flights);
    if (_activeFilters.contains('Direct')) {
      list = list.where((f) => f.stops == 0).toList();
    }
    if (_activeFilters.contains('Refundable')) {
      list = list.where((f) => f.isRefundable).toList();
    }
    if (_activeFilters.contains('Wi-Fi')) {
      list = list.where((f) => f.hasWifi).toList();
    }
    if (_activeFilters.contains('Meal')) {
      list = list.where((f) => f.hasMeal).toList();
    }
    switch (_sortBy) {
      case 'Cheapest':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fastest':
        list.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case 'Best':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(context, isDark, tc),
          if (!_isLoading) ...[
            FilterChipRow(
              activeFilters: _activeFilters,
              onToggle: (f) => setState(() {
                _activeFilters.contains(f)
                    ? _activeFilters.remove(f)
                    : _activeFilters.add(f);
              }),
              isDark: isDark,
            ),
            _buildResultsBar(isDark),
          ],
          Expanded(
            child: _isLoading
                ? _buildSkeleton(isDark)
                : _buildList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeController tc) {
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  CustomBackButton(useLightStyle: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DEL  →  DXB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.fontXL,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Jun 15  ·  1 Traveller  ·  Economy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.75),
                            fontSize: AppSizes.fontSM,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: tc.toggleTheme,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(10),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Text(
            '${_filtered.length} flights found',
            style: TextStyle(
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => SortBottomSheet.show(
              context,
              current: _sortBy,
              isDark: isDark,
              onSelected: (s) => setState(() => _sortBy = s),
            ),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded,
                      size: 15, color: AppColors.primaryStart),
                  const SizedBox(width: 5),
                  Text(
                    _sortBy,
                    style: const TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(bool isDark) {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight,
                size: 64,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(height: 16),
            Text(
              'No flights match\nyour filters',
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
            GestureDetector(
              onTap: () => setState(() => _activeFilters.clear()),
              child: const Text(
                'Clear filters',
                style: TextStyle(
                  color: AppColors.primaryStart,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final delay = i * 0.12;
        final start = delay.clamp(0.0, 0.8);
        final end = (delay + 0.4).clamp(0.0, 1.0);

        return AnimatedBuilder(
          animation: _listController,
          builder: (_, child) {
            final t = (((_listController.value - start) / (end - start))
                .clamp(0.0, 1.0));
            final curve = Curves.easeOutCubic.transform(t);
            return Opacity(
              opacity: curve,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - curve)),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: FlightCard(
              flight: results[i],
              isDark: isDark,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.flightDetails,
                arguments: results[i],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      itemCount: 4,
      itemBuilder: (_, i) => _SkeletonCard(isDark: isDark),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base =
    widget.isDark ? AppColors.darkCard : const Color(0xFFEEEBF8);
    final highlight =
    widget.isDark ? AppColors.darkBorder : const Color(0xFFDDD8F0);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: [
                (_shimmer.value - 0.3).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}