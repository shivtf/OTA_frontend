// lib/features/payment/widgets/saved_card_tile.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/payment_model.dart';

class SavedCardTile extends StatelessWidget {
  final SavedCard card;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const SavedCardTile({
    super.key,
    required this.card,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryStart.withOpacity(0.06)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryStart
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Card art
            Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                gradient: _gradientForBrand(card.brand),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _shortBrand(card.brand),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${card.brand}  •••• ${card.last4}',
                    style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    'Expires ${card.expiry}',
                    style: TextStyle(
                      fontSize: AppSizes.fontXS,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (card.isDefault)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primaryStart : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryStart
                      : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _gradientForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const LinearGradient(
            colors: [Color(0xFF1A1F71), Color(0xFF2563EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'mastercard':
        return const LinearGradient(
            colors: [Color(0xFFEB5757), Color(0xFFFF9F43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case 'amex':
        return const LinearGradient(
            colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      default:
        return AppColors.primaryGradient;
    }
  }

  String _shortBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa': return 'VISA';
      case 'mastercard': return 'MC';
      case 'amex': return 'AMEX';
      default: return brand.substring(0, 2).toUpperCase();
    }
  }
}
