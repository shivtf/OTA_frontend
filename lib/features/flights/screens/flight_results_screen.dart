import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../providers/flight_booking_provider.dart';
import '../../../core/services/flight_service.dart';
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
  String _sortBy = 'total_amount';
  Set<String> _activeFilters = {};
  late AnimationController _listController;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadOffers();
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    final provider = context.read<FlightBookingProvider>();
    final ok = await provider.loadOffers(sortBy: _sortBy);
    if (ok && mounted) _listController.forward();
  }

  List<FlightOffer> get _filtered {
    final provider = context.read<FlightBookingProvider>();
    var list = List<FlightOffer>.from(provider.offers);
    if (_activeFilters.contains('Direct')) {
      list = list.where((f) => f.stops == 0).toList();
    }
    if (_activeFilters.contains('Refundable')) {
      list = list.where((f) => f.conditions?.refundable == true).toList();
    }
    return list;
  }

  void _onSortChanged(String sort) {
    setState(() {
      _sortBy = sort;
      _loaded = false;
      _listController.reset();
    });
    _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();
    final provider = context.watch<FlightBookingProvider>();

    // Route args
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final from = args?['from'] as String? ?? '';
    final to = args?['to'] as String? ?? '';
    final fromCity = args?['fromCity'] as String? ?? from;
    final toCity = args?['toCity'] as String? ?? to;

    final filtered = _filtered;
    final isLoading = provider.step == BookingStep.loadingOffers;
    final hasFailed = provider.step == BookingStep.failed;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: _buildHeader(
                  context, isDark, tc, from, to, fromCity, toCity)),
          SliverToBoxAdapter(
            child: FilterChipRow(
              filters: const ['Direct', 'Refundable', 'Under ₹5000'],
              activeFilters: _activeFilters,
              isDark: isDark,
              onToggle: (f) => setState(() {
                _activeFilters.contains(f)
                    ? _activeFilters.remove(f)
                    : _activeFilters.add(f);
              }),
              onSort: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => SortBottomSheet(
                  currentSort: _sortBy,
                  onSortSelected: _onSortChanged,
                ),
              ),
            ),
          ),
          if (isLoading)
            const SliverFillRemaining(child: _LoadingState())
          else if (hasFailed)
            SliverFillRemaining(
              child: _ErrorState(
                message: provider.error ?? 'Failed to load flights',
                onRetry: _loadOffers,
              ),
            )
          else if (filtered.isEmpty)
            const SliverFillRemaining(child: _EmptyState())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final offer = filtered[i];
                  return AnimatedBuilder(
                    animation: _listController,
                    builder: (_, child) {
                      final delay = (i * 0.08).clamp(0.0, 0.7);
                      final t = CurvedAnimation(
                        parent: _listController,
                        curve: Interval(delay, delay + 0.3,
                            curve: Curves.easeOutCubic),
                      ).value;
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 24),
                          child: child,
                        ),
                      );
                    },
                    child: FlightCard(
                      offer: offer,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.flightDetails,
                        arguments: offer,
                      ),
                    ),
                  );
                },
                childCount: filtered.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeController tc,
      String from, String to, String fromCity, String toCity) {
    final provider = context.read<FlightBookingProvider>();
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLG),
          child: Column(
            children: [
              Row(
                children: [
                  const CustomBackButton(color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$from → $to',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '$fromCity to $toCity  ·  ${provider.totalOffers} flights',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: AppSizes.fontSM,
                          ),
                        ),
                      ],
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
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding the best flights...',
            style: TextStyle(
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.airplanemode_inactive,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          const SizedBox(height: 16),
          Text('No flights match your filters',
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}
