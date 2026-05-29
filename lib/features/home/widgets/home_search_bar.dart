// lib/features/home/widgets/home_search_bar.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class HomeSearchBar extends StatelessWidget {
  final bool isDark;
  const HomeSearchBar({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.flightSearch),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha:0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: AppColors.primaryStart,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Search flights, hotels, cars...',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const Spacer(),
            // Container(
            //   margin: const EdgeInsets.only(right: 8),
            //   padding: const EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     gradient: AppColors.primaryGradient,
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: const Icon(Icons.tune_rounded,
            //       color: Colors.white, size: 16),
            // ),
          ],
        ),
      ),
    );
  }
}