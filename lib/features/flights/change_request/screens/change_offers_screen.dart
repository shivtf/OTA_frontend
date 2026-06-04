// lib/features/flights/change_request/screens/change_offers_screen.dart
//
// Step 2 — lists available change offers for the user to pick from.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../change_request/models/flight_change_model.dart';
import '../providers/flight_change_provider.dart';

class ChangeOffersScreen extends StatelessWidget {
  final FlightChangeProvider provider;

  const ChangeOffersScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.offers.isEmpty) {
      return _NoOffersBody(onRetry: provider.goBackToForm);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      children: [
        _SectionHeader(
          text: '${provider.offers.length} option${provider.offers.length == 1 ? '' : 's'} found',
        ),
        const SizedBox(height: AppSizes.paddingMD),
        ...provider.offers.map(
              (offer) => _OfferCard(
            offer: offer,
            onConfirm: () => provider.confirmOffer(offer),
          ),
        ),
        const SizedBox(height: AppSizes.paddingXL),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offer card (with countdown timer)
// ─────────────────────────────────────────────────────────────────────────────

class _OfferCard extends StatefulWidget {
  final ChangeOffer offer;
  final VoidCallback onConfirm;

  const _OfferCard({required this.offer, required this.onConfirm});

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.offer.timeUntilExpiry;
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _remaining = widget.offer.timeUntilExpiry;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    if (_remaining == Duration.zero) return 'Expired';
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = _remaining.inHours;
    if (h > 0) return '${h}h ${m}m ${s}s';
    return '${m}m ${s}s';
  }

  bool get _isExpired => _remaining == Duration.zero;
  bool get _isUrgent => _remaining.inMinutes < 5 && !_isExpired;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offer = widget.offer;
    final slice =
    offer.addSlices.isNotEmpty ? offer.addSlices.first : null;
    final segment =
    slice != null && slice.segments.isNotEmpty ? slice.segments.first : null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _isExpired ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(
            color: _isUrgent
                ? AppColors.warning.withValues(alpha:0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: _isUrgent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha:0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Countdown pill at top
            _CountdownBanner(
              text: _countdownText,
              isExpired: _isExpired,
              isUrgent: _isUrgent,
            ),

            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route header
                  if (slice != null)
                    _RouteRow(
                      isDark: isDark,
                      slice: slice,
                      segment: segment,
                    ),
                  const SizedBox(height: AppSizes.paddingMD),

                  // Divider
                  Divider(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                    height: 1,
                  ),
                  const SizedBox(height: AppSizes.paddingMD),

                  // Pricing row
                  _PricingRow(isDark: isDark, offer: offer),
                  const SizedBox(height: AppSizes.paddingMD),

                  // Conditions
                  if (offer.conditions != null)
                    _ConditionsRow(isDark: isDark, conditions: offer.conditions!),
                  const SizedBox(height: AppSizes.paddingLG),

                  // CTA button
                  _SelectButton(
                    isExpired: _isExpired,
                    onConfirm: widget.onConfirm,
                    currency: offer.changeTotalCurrency,
                    changeAmount: offer.changeAmount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBanner extends StatelessWidget {
  final String text;
  final bool isExpired;
  final bool isUrgent;

  const _CountdownBanner({
    required this.text,
    required this.isExpired,
    required this.isUrgent,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;

    if (isExpired) {
      bgColor = AppColors.error.withValues(alpha:0.1);
      textColor = AppColors.error;
      icon = Icons.timer_off_rounded;
    } else if (isUrgent) {
      bgColor = AppColors.warning.withValues(alpha:0.12);
      textColor = AppColors.warning;
      icon = Icons.timer_rounded;
    } else {
      bgColor = AppColors.primaryStart.withValues(alpha:0.08);
      textColor = AppColors.primaryStart;
      icon = Icons.access_time_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.paddingSM,
        horizontal: AppSizes.paddingMD,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusLarge),
          topRight: Radius.circular(AppSizes.radiusLarge),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Offer expired' : 'Offer expires in $text',
            style: GoogleFonts.nunito(
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final bool isDark;
  final ChangeOfferSlice slice;
  final ChangeSegment? segment;

  const _RouteRow({
    required this.isDark,
    required this.slice,
    required this.segment,
  });

  @override
  Widget build(BuildContext context) {
    final depDt = segment?.departingDateTime;
    final arrDt = segment?.arrivingDateTime;
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('d MMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Airline + flight number
        if (segment != null)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSM,
                  vertical: AppSizes.paddingXS,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Text(
                  '${segment!.marketingCarrier.iataCode} ${segment!.marketingCarrierFlightNumber}',
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingSM),
              Expanded(
                child: Text(
                  segment!.marketingCarrier.name,
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontSM,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (slice.fareBrandName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSM, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    slice.fareBrandName!,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSizes.paddingMD),

        // Route display
        Row(
          children: [
            // Origin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slice.origin.iataCode,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontXXL,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    slice.origin.cityName,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontXS,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (depDt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeFmt.format(depDt),
                      style: GoogleFonts.nunito(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryStart,
                      ),
                    ),
                    Text(
                      dateFmt.format(depDt),
                      style: GoogleFonts.nunito(
                        fontSize: AppSizes.fontXS,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Duration + plane icon
            Column(
              children: [
                Text(
                  slice.durationHuman,
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontXS,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                    const Icon(
                      Icons.flight_rounded,
                      color: AppColors.primaryStart,
                      size: 20,
                    ),
                    Container(
                      width: 32,
                      height: 1,
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Non-stop',
                  style: GoogleFonts.nunito(
                    fontSize: AppSizes.fontXS,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Destination
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    slice.destination.iataCode,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontXXL,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    slice.destination.cityName,
                    style: GoogleFonts.nunito(
                      fontSize: AppSizes.fontXS,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (arrDt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeFmt.format(arrDt),
                      style: GoogleFonts.nunito(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryStart,
                      ),
                    ),
                    Text(
                      dateFmt.format(arrDt),
                      style: GoogleFonts.nunito(
                        fontSize: AppSizes.fontXS,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PricingRow extends StatelessWidget {
  final bool isDark;
  final ChangeOffer offer;

  const _PricingRow({required this.isDark, required this.offer});

  @override
  Widget build(BuildContext context) {
    final currency = offer.changeTotalCurrency;
    final secondaryColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Row(
      children: [
        Expanded(
          child: _PriceChip(
            label: 'Change fee',
            amount: '${offer.changeTotalAmount} $currency',
            color: offer.changeAmount > 0 ? AppColors.accent : AppColors.success,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _PriceChip(
            label: 'New total',
            amount: '${offer.newTotalAmount} $currency',
            color: AppColors.primaryStart,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: _PriceChip(
            label: 'Cancel penalty',
            amount: '${offer.penaltyTotalAmount} $currency',
            color: secondaryColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  const _PriceChip({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: AppSizes.fontXS,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: GoogleFonts.nunito(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ConditionsRow extends StatelessWidget {
  final bool isDark;
  final ChangeOfferConditions conditions;

  const _ConditionsRow({required this.isDark, required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ConditionBadge(
          label: 'Changeable',
          allowed: conditions.changeAllowed,
        ),
        const SizedBox(width: AppSizes.paddingSM),
        _ConditionBadge(
          label: 'Refundable',
          allowed: conditions.refundAllowed,
        ),
      ],
    );
  }
}

class _ConditionBadge extends StatelessWidget {
  final String label;
  final bool allowed;

  const _ConditionBadge({required this.label, required this.allowed});

  @override
  Widget build(BuildContext context) {
    final color = allowed ? AppColors.success : AppColors.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          allowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color,
          size: 14,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: AppSizes.fontXS,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isExpired;
  final VoidCallback onConfirm;
  final String currency;
  final double changeAmount;

  const _SelectButton({
    required this.isExpired,
    required this.onConfirm,
    required this.currency,
    required this.changeAmount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: isExpired
          ? OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha:0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        child: Text(
          'Offer Expired',
          style: GoogleFonts.nunito(
              fontSize: AppSizes.fontMD,
              color: AppColors.error,
              fontWeight: FontWeight.w700),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha:0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
          ),
          child: Text(
            changeAmount > 0
                ? 'Select — Pay $currency ${changeAmount.toStringAsFixed(2)} extra'
                : 'Select This Flight',
            style: GoogleFonts.nunito(
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoOffersBody extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoOffersBody({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flight_rounded,
                color: AppColors.primaryStart,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              'No Flights Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              'No available options were found for your selected route and date. Try different dates or routes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Modify Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
