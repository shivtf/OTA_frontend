// lib/features/hotels/screens/hotel_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/hotel_model.dart';
import '../widgets/hotel_card.dart';

class HotelResultsScreen extends StatefulWidget {
  const HotelResultsScreen({super.key});

  @override
  State<HotelResultsScreen> createState() => _HotelResultsScreenState();
}

class _HotelResultsScreenState extends State<HotelResultsScreen>
    with SingleTickerProviderStateMixin {
  late List<HotelModel> _hotels;
  bool _isLoading = true;
  String _sortBy = 'Top Rated';
  Set<String> _activeFilters = {};
  late AnimationController _listAnim;

  final List<String> _filters = ['Breakfast', 'Free Cancel', 'Pool', 'Spa', 'Under \$200'];
  final List<String> _sortOptions = ['Top Rated', 'Cheapest', 'Most Reviewed', 'Nearest'];

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
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() { _hotels = HotelData.search(); _isLoading = false; });
      _listAnim.forward();
    }
  }

  List<HotelModel> get _filtered {
    var list = List<HotelModel>.from(_hotels);
    if (_activeFilters.contains('Breakfast')) list = list.where((h) => h.breakfastIncluded).toList();
    if (_activeFilters.contains('Free Cancel')) list = list.where((h) => h.freeCancellation).toList();
    if (_activeFilters.contains('Pool')) list = list.where((h) => h.amenities.contains('Pool')).toList();
    if (_activeFilters.contains('Spa')) list = list.where((h) => h.amenities.contains('Spa')).toList();
    if (_activeFilters.contains('Under \$200')) list = list.where((h) => h.pricePerNight < 200).toList();
    switch (_sortBy) {
      case 'Top Rated': list.sort((a, b) => b.rating.compareTo(a.rating)); break;
      case 'Cheapest': list.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight)); break;
      case 'Most Reviewed': list.sort((a, b) => b.reviewCount.compareTo(a.reviewCount)); break;
      case 'Nearest': list.sort((a, b) => a.distanceFromCenter.compareTo(b.distanceFromCenter)); break;
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
            ? const LinearGradient(colors: [Color(0xFF0B1A2E), Color(0xFF0F2744)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              const CustomBackButton(useLightStyle: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Dubai Hotels',
                      style: TextStyle(color: Colors.white, fontSize: AppSizes.fontXL, fontWeight: FontWeight.w800)),
                  Text('Jun 15 – Jun 18  ·  2 Guests  ·  1 Room',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: AppSizes.fontSM)),
                ]),
              ),
              GestureDetector(
                onTap: tc.toggleTheme,
                child: Container(width: 38, height: 38,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 18)),
              ),
            ],
          ),
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
                gradient: isActive
                    ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: isActive ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
      child: Row(
        children: [
          Text('${_filtered.length} hotels found',
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
                const Icon(Icons.sort_rounded, size: 15, color: Color(0xFF1565C0)),
                const SizedBox(width: 5),
                Text(_sortBy, style: const TextStyle(
                    fontSize: AppSizes.fontSM, fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
              ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hotel_rounded, size: 64,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          const SizedBox(height: 16),
          Text('No hotels match\nyour filters', textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppSizes.fontLG, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _activeFilters.clear()),
            child: const Text('Clear filters',
                style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w600)),
          ),
        ]),
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
          animation: _listAnim,
          builder: (_, child) {
            final t = ((_listAnim.value - start) / (end - start)).clamp(0.0, 1.0);
            final curve = Curves.easeOutCubic.transform(t);
            return Opacity(opacity: curve,
                child: Transform.translate(offset: Offset(0, 30 * (1 - curve)), child: child));
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HotelCard(hotel: results[i], isDark: isDark,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.hotelDetails, arguments: results[i])),
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      itemCount: 3,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, borderRadius: BorderRadius.circular(2)))),
            Text('Sort By', style: TextStyle(fontSize: AppSizes.fontXL, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 16),
            ..._sortOptions.map((o) => GestureDetector(
              onTap: () { setState(() => _sortBy = o); Navigator.pop(context); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _sortBy == o
                      ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : null,
                  color: _sortBy != o ? (isDark ? AppColors.darkInputBg : AppColors.lightInputBg) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Expanded(child: Text(o, style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
                      color: _sortBy == o ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)))),
                  if (_sortBy == o) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                ]),
              ),
            )),
          ],
        ),
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
    final base = widget.isDark ? AppColors.darkCard : const Color(0xFFE8EAF6);
    final highlight = widget.isDark ? AppColors.darkBorder : const Color(0xFFC5CAE9);
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          gradient: LinearGradient(
            colors: [base, highlight, base],
            stops: [(_shimmer.value - 0.3).clamp(0.0, 1.0), _shimmer.value.clamp(0.0, 1.0), (_shimmer.value + 0.3).clamp(0.0, 1.0)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}