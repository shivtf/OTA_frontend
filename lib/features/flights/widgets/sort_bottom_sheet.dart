// lib/features/flights/widgets/sort_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SortBottomSheet {
  static void show(
      BuildContext context, {
        required String current,
        required bool isDark,
        required ValueChanged<String> onSelected,
      }) {
    final options = [
      {'label': 'Cheapest', 'icon': Icons.attach_money_rounded},
      {'label': 'Fastest', 'icon': Icons.speed_rounded},
      {'label': 'Best', 'icon': Icons.star_rounded},
      {'label': 'Earliest', 'icon': Icons.schedule_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color:
                  isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: AppSizes.fontXL,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) {
              final isActive = current == o['label'];
              return GestureDetector(
                onTap: () {
                  onSelected(o['label'] as String);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isActive ? AppColors.primaryGradient : null,
                    color: isActive
                        ? null
                        : (isDark
                        ? AppColors.darkInputBg
                        : AppColors.lightInputBg),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        o['icon'] as IconData,
                        color: isActive ? Colors.white : AppColors.primaryStart,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        o['label'] as String,
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.white
                              : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}