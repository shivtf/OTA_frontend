// lib/features/payment/widgets/order_summary_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/payment_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final BookingItem booking;
  final bool isDark;

  const OrderSummaryCard({
    super.key,
    required this.booking,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Text(booking.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking.typeLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        booking.subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: AppSizes.fontXS,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Trip details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _DetailItem(
                          label: booking.detail1Label,
                          value: booking.detail1Value,
                          isDark: isDark,
                        )),
                    Container(
                      width: 1,
                      height: 36,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    Expanded(
                        child: _DetailItem(
                          label: booking.detail2Label,
                          value: booking.detail2Value,
                          isDark: isDark,
                        )),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(
                    color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 14),

                // Price breakdown
                _PriceLine(
                    label: 'Base price',
                    amount: booking.basePrice,
                    isDark: isDark),
                const SizedBox(height: 6),
                _PriceLine(
                    label: 'Taxes & fees',
                    amount: booking.taxAmount,
                    isDark: isDark),
                const SizedBox(height: 6),
                _PriceLine(
                    label: 'Service fee',
                    amount: booking.serviceFee,
                    isDark: isDark),
                const SizedBox(height: 12),
                Divider(
                    color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder),
                const SizedBox(height: 12),

                // Total
                Row(
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const Spacer(),
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.primaryGradient.createShader(b),
                      child: Text(
                        '\$${booking.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: AppSizes.fontXXL,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _DetailItem(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDark;
  const _PriceLine(
      {required this.label, required this.amount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}
