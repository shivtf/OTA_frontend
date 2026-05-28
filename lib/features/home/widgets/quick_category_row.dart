// lib/features/home/widgets/quick_category_row.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';

class QuickCategoryRow extends StatelessWidget {
  final bool isDark;
  const QuickCategoryRow({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.flight_rounded, 'label': 'Flights', 'route': AppRoutes.flightSearch},
      {'icon': Icons.hotel_rounded, 'label': 'Hotels', 'route': AppRoutes.hotelSearch},
      {'icon': Icons.directions_car_rounded, 'label': 'Cars', 'route': AppRoutes.carSearch},
      {'icon': Icons.card_giftcard_rounded, 'label': 'Packages', 'route': null},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore',
          style: TextStyle(
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.map((c) {
            return _CategoryItem(
              icon: c['icon'] as IconData,
              label: c['label'] as String,
              route: c['route'] as String?,
              isDark: isDark,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? route;
  final bool isDark;

  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route != null
          ? () => Navigator.of(context).pushNamed(route!)
          : null,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}