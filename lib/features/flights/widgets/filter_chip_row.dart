// lib/features/flights/widgets/filter_chip_row.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggle;
  final VoidCallback? onSort;
  final bool isDark;

  const FilterChipRow({
    super.key,
    required this.filters,
    required this.activeFilters,
    required this.onToggle,
    this.onSort,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final isActive = activeFilters.contains(f);
          return GestureDetector(
            onTap: () => onToggle(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive
                    ? null
                    : (isDark ? AppColors.darkCard : AppColors.lightCard),
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha:0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
                    : null,
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}