// lib/features/flights/change_request/screens/change_success_screen.dart
//
// Shown after Step 3 succeeds. Displays the confirmed change summary
// and a "Back to booking" button.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../providers/flight_change_provider.dart';

class ChangeSuccessScreen extends StatefulWidget {
  final FlightChangeProvider provider;
  final VoidCallback onDone;

  const ChangeSuccessScreen({
    super.key,
    required this.provider,
    required this.onDone,
  });

  @override
  State<ChangeSuccessScreen> createState() => _ChangeSuccessScreenState();
}

class _ChangeSuccessScreenState extends State<ChangeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = widget.provider.confirmedChange;
    final offer = widget.provider.selectedOffer;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingXL),

          // Animated checkmark
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, Color(0xFF2E9E6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingLG),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  'Flight Changed!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingSM),
                Text(
                  'Your flight has been successfully changed.\nA confirmation email will be sent shortly.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // Summary card
                if (confirmed != null || offer != null)
                  _SummaryCard(
                    isDark: isDark,
                    confirmed: confirmed,
                    offer: offer,
                  ),
                const SizedBox(height: AppSizes.paddingXXL),

                // Info box
                _InfoBox(isDark: isDark),
                const SizedBox(height: AppSizes.paddingXL),

                // CTA
                Container(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStart.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: widget.onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                    icon: const Icon(Icons.confirmation_number_rounded),
                    label: Text(
                      'View Updated Booking',
                      style: GoogleFonts.nunito(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final dynamic confirmed;
  final dynamic offer;

  const _SummaryCard({
    required this.isDark,
    required this.confirmed,
    required this.offer,
  });

  @override
  Widget build(BuildContext context) {
    final currency = confirmed?.changeTotalCurrency ??
        offer?.changeTotalCurrency ??
        'GBP';
    final changeAmt =
        confirmed?.changeTotalAmount ?? offer?.changeTotalAmount ?? '0.00';
    final newTotal =
        confirmed?.newTotalAmount ?? offer?.newTotalAmount ?? '0.00';

    // New slice details from offer
    final slice =
    (offer?.addSlices?.isNotEmpty == true) ? offer!.addSlices.first : null;
    final segment = (slice?.segments?.isNotEmpty == true)
        ? slice!.segments.first
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // New route
          if (slice != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slice.origin.iataCode,
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSM),
                  child: Icon(
                    Icons.flight_rounded,
                    color: AppColors.primaryStart,
                    size: AppSizes.iconMD,
                  ),
                ),
                Text(
                  slice.destination.iataCode,
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          if (segment != null) ...[
            const SizedBox(height: AppSizes.paddingXS),
            Text(
              '${segment.marketingCarrier.name} · ${segment.marketingCarrier.iataCode}${segment.marketingCarrierFlightNumber}',
              style: GoogleFonts.nunito(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.paddingMD),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: AppSizes.paddingMD),

          // Pricing summary
          _SummaryRow(
            label: 'Change fee charged',
            value: '$currency $changeAmt',
            valueColor: double.tryParse(changeAmt) == 0
                ? AppColors.success
                : AppColors.accent,
            isDark: isDark,
          ),
          const SizedBox(height: AppSizes.paddingSM),
          _SummaryRow(
            label: 'New booking total',
            value: '$currency $newTotal',
            valueColor: AppColors.primaryStart,
            isDark: isDark,
            isBold: true,
          ),

          if (confirmed != null) ...[
            const SizedBox(height: AppSizes.paddingMD),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSM,
                vertical: AppSizes.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                'Ref: ${confirmed.id}',
                style: GoogleFonts.nunito(
                  fontSize: AppSizes.fontXS,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isDark;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isDark,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: AppSizes.fontSM,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: isBold ? AppSizes.fontMD : AppSizes.fontSM,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool isDark;
  const _InfoBox({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.email_outlined, 'Confirmation email sent with new itinerary'),
      (Icons.account_balance_wallet_outlined,
      'Booking total updated in your account'),
      (Icons.history_rounded, 'Change logged in your booking history'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withOpacity(0.6)
            : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
            padding:
            const EdgeInsets.only(bottom: AppSizes.paddingSM),
            child: Row(
              children: [
                Icon(
                  item.$1,
                  size: AppSizes.iconSM,
                  color: AppColors.primaryStart,
                ),
                const SizedBox(width: AppSizes.paddingSM),
                Expanded(
                  child: Text(
                    item.$2,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontSM,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}
