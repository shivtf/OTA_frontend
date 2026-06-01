// lib/features/payment/widgets/booking_summary_card.dart
//
// Comprehensive booking summary shown on the PaymentScreen.
// Displays: flight info, passenger details, price breakdown,
// taxes & fees, and total amount.
// Fully provider-agnostic — works identically with Stripe and Duffel.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/payment_model.dart';

class BookingSummaryCard extends StatefulWidget {
  final BookingItem booking;
  final bool isDark;

  const BookingSummaryCard({
    super.key,
    required this.booking,
    required this.isDark,
  });

  @override
  State<BookingSummaryCard> createState() => _BookingSummaryCardState();
}

class _BookingSummaryCardState extends State<BookingSummaryCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1,
    );
  }

  @override
  void dispose() {
    _arrowAnim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _arrowAnim.forward() : _arrowAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Column(
        children: [
          // ── Gradient header strip ──────────────────────────────────────
          _buildHeader(b, isDark),

          // ── Collapsible body ───────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildBody(b, isDark),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BookingItem b, bool isDark) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(AppSizes.radiusLarge),
            bottom: _expanded
                ? Radius.zero
                : const Radius.circular(AppSizes.radiusLarge),
          ),
        ),
        child: Row(
          children: [
            // Emoji badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(b.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.typeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    b.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    b.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: AppSizes.fontXS,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Collapse arrow
            AnimatedRotation(
              turns: _expanded ? 0 : -0.5,
              duration: const Duration(milliseconds: 250),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(BookingItem b, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        children: [
          // ── Flight details row ───────────────────────────────────────
          _buildFlightDetailRow(b, isDark),

          _divider(isDark),

          // ── Passenger details ────────────────────────────────────────
          if (b.passengers.isNotEmpty) ...[
            _buildPassengers(b.passengers, isDark),
            _divider(isDark),
          ],

          // ── Price breakdown ──────────────────────────────────────────
          _buildPriceSection(b, isDark),
        ],
      ),
    );
  }

  Widget _buildFlightDetailRow(BookingItem b, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _DetailCell(
            icon: Icons.flight_takeoff_rounded,
            label: b.detail1Label,
            value: b.detail1Value,
            isDark: isDark,
          ),
        ),
        Container(
          width: 1,
          height: 44,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        Expanded(
          child: _DetailCell(
            icon: Icons.flight_land_rounded,
            label: b.detail2Label,
            value: b.detail2Value,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengers(List<PassengerSummary> passengers, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.people_alt_rounded,
              size: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Passenger${passengers.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...passengers.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.primaryStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.name,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkInputBg
                        : AppColors.lightInputBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                if (p.seatNumber != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primaryStart.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      p.seatNumber!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(BookingItem b, bool isDark) {
    return Column(
      children: [
        _PriceLine(
          label: 'Base fare',
          value: b.basePrice,
          currency: b.currency,
          isDark: isDark,
        ),
        const SizedBox(height: 7),
        _PriceLine(
          label: 'Taxes & fees',
          value: b.taxAmount,
          currency: b.currency,
          isDark: isDark,
          isSubtle: true,
        ),
        const SizedBox(height: 7),
        _PriceLine(
          label: 'Service fee',
          value: b.serviceFee,
          currency: b.currency,
          isDark: isDark,
          isSubtle: true,
        ),
        const SizedBox(height: 12),
        Divider(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          height: 1,
        ),
        const SizedBox(height: 12),
        // Total row
        Row(
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w800,
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
                _formatCurrency(b.total, b.currency),
                style: const TextStyle(
                  fontSize: AppSizes.fontXXL,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _divider(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          height: 1,
        ),
      );

  String _formatCurrency(double amount, String currency) {
    final symbol = currency.toUpperCase() == 'USD'
        ? '\$'
        : currency.toUpperCase() == 'EUR'
            ? '€'
            : currency.toUpperCase() == 'GBP'
                ? '£'
                : '${currency.toUpperCase()} ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DetailCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryStart.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 4),
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
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final bool isDark;
  final bool isSubtle;

  const _PriceLine({
    required this.label,
    required this.value,
    required this.currency,
    required this.isDark,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = currency.toUpperCase() == 'USD'
        ? '\$'
        : currency.toUpperCase() == 'EUR'
            ? '€'
            : currency.toUpperCase() == 'GBP'
                ? '£'
                : '${currency.toUpperCase()} ';

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            color: isSubtle
                ? (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
        const Spacer(),
        Text(
          '$symbol${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: isSubtle
                ? (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
          ),
        ),
      ],
    );
  }
}
