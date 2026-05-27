// lib/features/cars/screens/car_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/car_model.dart';
import '../widgets/car_card.dart';

class CarResultsScreen extends StatefulWidget {
  const CarResultsScreen({super.key});

  @override
  State<CarResultsScreen> createState() => _CarResultsScreenState();
}

class _CarResultsScreenState extends State<CarResultsScreen>
    with SingleTickerProviderStateMixin {
  late List<CarModel> _cars;
  bool _isLoading = true;
  String _sortBy = 'Cheapest';
  Set<String> _activeFilters = {};
  late AnimationController _listAnim;

  static const _carGreen = LinearGradient(
    colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  final List<String> _filters = ['Automatic', 'Electric', 'Unlimited KM', 'Free Cancel', 'With Driver'];
  final List<Map<String, dynamic>> _sortOptions = [
    {'label': 'Cheapest', 'icon': Icons.attach_money_rounded},
    {'label': 'Best Rated', 'icon': Icons.star_rounded},
    {'label': 'Most Reviewed', 'icon': Icons.reviews_rounded},
    {'label': 'Largest', 'icon': Icons.airline_seat_recline_extra_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _listAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _load();
  }

  @override
  void dispose() {
    _listAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() { _cars = CarData.search(); _isLoading = false; });
      _listAnim.forward();
    }
  }

  List<CarModel> get _filtered {
    var list = List<CarModel>.from(_cars);
    if (_activeFilters.contains('Automatic')) list = list.where((c) => c.transmission == 'Auto').toList();
    if (_activeFilters.contains('Electric')) list = list.where((c) => c.fuelType == 'Electric').toList();
    if (_activeFilters.contains('Unlimited KM')) list = list.where((c) => c.unlimitedMileage).toList();
    if (_activeFilters.contains('Free Cancel')) list = list.where((c) => c.freeCancellation).toList();
    switch (_sortBy) {
      case 'Cheapest': list.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay)); break;
      case 'Best Rated': list.sort((a, b) => b.rating.compareTo(a.rating)); break;
      case 'Most Reviewed': list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); break;
      case 'Largest': list.sort((a, b) => b.seats.compareTo(a.seats)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(context, isDark, tc),
          if (!_isLoading) _buildFilterBar(isDark),
          if (!_isLoading) _buildResultsBar(isDark),
          Expanded(child: _isLoading ? _buildSkeleton(isDark) : _buildList(isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeController tc) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(colors: [Color(0xFF062415), Color(0xFF0A3D26)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : _carGreen,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(children: [
            const CustomBackButton(useLightStyle: true),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Available Cars',
                  style: TextStyle(color: Colors.white, fontSize: AppSizes.fontXL, fontWeight: FontWeight.w800)),
              Text('Dubai  ·  Jun 15 – Jun 18  ·  3 days',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: AppSizes.fontSM)),
            ])),
            GestureDetector(
              onTap: tc.toggleTheme,
              child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 18)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isActive = _activeFilters.contains(f);
          return GestureDetector(
            onTap: () => setState(() => isActive ? _activeFilters.remove(f) : _activeFilters.add(f)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive ? _carGreen : null,
                color: isActive ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                boxShadow: isActive ? [BoxShadow(color: const Color(0xFF0A7D46).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 3))] : null,
              ),
              child: Text(f, style: TextStyle(
                fontSize: AppSizes.fontSM,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        Text('${_filtered.length} cars available',
            style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const Spacer(),
        GestureDetector(
          onTap: () => _showSortSheet(isDark),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(children: [
              const Icon(Icons.sort_rounded, size: 15, color: Color(0xFF0A7D46)),
              const SizedBox(width: 5),
              Text(_sortBy, style: const TextStyle(
                  fontSize: AppSizes.fontSM, fontWeight: FontWeight.w600, color: Color(0xFF0A7D46))),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildList(bool isDark) {
    final results = _filtered;
    if (results.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.no_crash_rounded, size: 64,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        const SizedBox(height: 16),
        Text('No cars match\nyour filters', textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppSizes.fontLG, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _activeFilters.clear()),
          child: const Text('Clear filters',
              style: TextStyle(color: Color(0xFF0A7D46), fontWeight: FontWeight.w600)),
        ),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final delay = i * 0.12;
        final start = delay.clamp(0.0, 0.8);
        final end = (delay + 0.4).clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _listAnim,
          builder: (_, child) {
            final t = ((_listAnim.value - start) / (end - start)).clamp(0.0, 1.0);
            final curve = Curves.easeOutCubic.transform(t);
            return Opacity(opacity: curve,
                child: Transform.translate(offset: Offset(0, 30 * (1 - curve)), child: child));
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CarCard(car: results[i], isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.carDetails, arguments: results[i])),
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

  void _showSortSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2)))),
          Text('Sort By', style: TextStyle(fontSize: AppSizes.fontXL, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 16),
          ..._sortOptions.map((o) => GestureDetector(
            onTap: () { setState(() => _sortBy = o['label'] as String); Navigator.pop(context); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: _sortBy == o['label'] ? _carGreen : null,
                color: _sortBy != o['label'] ? (isDark ? AppColors.darkInputBg : AppColors.lightInputBg) : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(o['icon'] as IconData,
                    color: _sortBy == o['label'] ? Colors.white : const Color(0xFF0A7D46), size: 20),
                const SizedBox(width: 14),
                Expanded(child: Text(o['label'] as String,
                    style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
                        color: _sortBy == o['label'] ? Colors.white :
                        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)))),
                if (_sortBy == o['label'])
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _shimmer.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppColors.darkCard : const Color(0xFFE8F5E9);
    final highlight = widget.isDark ? AppColors.darkBorder : const Color(0xFFC8E6C9);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          gradient: LinearGradient(
            colors: [base, highlight, base],
            stops: [(_shimmer.value - 0.3).clamp(0.0, 1.0), _shimmer.value.clamp(0.0, 1.0),
              (_shimmer.value + 0.3).clamp(0.0, 1.0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}