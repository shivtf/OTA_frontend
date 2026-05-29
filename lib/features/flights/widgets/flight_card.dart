import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/flight_service.dart';

class FlightCard extends StatelessWidget {
  final FlightOffer offer;
  final VoidCallback onTap;

  const FlightCard({
    super.key,
    required this.offer,
    required this.onTap,
  });

  String _formatDuration(String iso) {
    // PT2H5M → 2h 5m
    final h = RegExp(r'(\d+)H').firstMatch(iso)?.group(1) ?? '0';
    final m = RegExp(r'(\d+)M').firstMatch(iso)?.group(1) ?? '0';
    return '${h}h ${m}m';
  }

  String _formatTime(String iso) {
    // 2026-07-15T10:50:00 → 10:50
    if (iso.length < 16) return iso;
    return iso.substring(11, 16);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slice = offer.outbound;
    final departTime = _formatTime(slice.departureAt);
    final arriveTime = _formatTime(slice.arrivalAt);
    final duration = _formatDuration(slice.duration);
    final stops = offer.stops;

    return GestureDetector(
      key: ValueKey(offer.offerId),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Airline row
              Row(
                children: [
                  // Airline logo or placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Builder(builder: (context) {
                      // owner.logoUrl from list endpoint is often null;
                      // marketingCarrier.logoUrl is always populated per segment
                      final logoUrl = offer.airlineLogoUrl.isNotEmpty
                          ? offer.airlineLogoUrl
                          : (offer.outbound.segments.isNotEmpty
                          ? offer.outbound.segments.first.marketingCarrier?.logoUrl ?? ''
                          : '');
                      if (logoUrl.isEmpty) {
                        return const Icon(
                          Icons.flight_rounded,
                          color: AppColors.primaryStart,
                          size: 20,
                        );
                      }
                      // Duffel CDN serves SVG logos — use SvgPicture
                      final isSvg = logoUrl.toLowerCase().endsWith('.svg');
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isSvg
                            ? SvgPicture.network(
                          logoUrl,
                          key: ValueKey(logoUrl),
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          placeholderBuilder: (_) => const SizedBox(
                            width: 28,
                            height: 28,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primaryStart,
                              ),
                            ),
                          ),
                        )
                            : Image.network(
                          logoUrl,
                          key: ValueKey(logoUrl),
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.flight_rounded,
                            color: AppColors.primaryStart,
                            size: 20,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final mc = offer.outbound.segments.isNotEmpty
                              ? offer.outbound.segments.first.marketingCarrier
                              : null;
                          final airlineName = offer.airline.isNotEmpty
                              ? offer.airline
                              : (mc?.name ?? 'Unknown Airline');
                          final airlineIata = offer.airlineIata.isNotEmpty
                              ? offer.airlineIata
                              : (mc?.iataCode ?? '');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                airlineName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppSizes.fontMD,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                airlineIata,
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${offer.currency} ${offer.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      Text(
                        'per person',
                        style: TextStyle(
                          fontSize: AppSizes.fontXS,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Route row
              Row(
                children: [
                  // Departure
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        departTime,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        slice.origin.iataCode,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      Text(
                        slice.origin.cityName,
                        style: TextStyle(
                          fontSize: AppSizes.fontXS,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Duration / stops bar
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: AppSizes.fontXS,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryStart,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppColors.primaryStart
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            Icon(
                              Icons.flight_rounded,
                              color: AppColors.primaryStart,
                              size: 18,
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: AppColors.primaryStart
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryStart,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stops == 0
                              ? 'Direct'
                              : '$stops Stop${stops > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: AppSizes.fontXS,
                            color: stops == 0
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrival
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        arriveTime,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        slice.destination.iataCode,
                        style: const TextStyle(
                          fontSize: AppSizes.fontSM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryStart,
                        ),
                      ),
                      Text(
                        slice.destination.cityName,
                        style: TextStyle(
                          fontSize: AppSizes.fontXS,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 1,
              ),
              const SizedBox(height: 10),

              // Bottom badges
              Row(
                children: [
                  if (offer.conditions?.refundable == true)
                    _Badge(
                      icon: Icons.undo_rounded,
                      label: 'Refundable',
                      color: AppColors.success,
                    ),
                  if (offer.conditions?.changeable == true) ...[
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Changeable',
                      color: AppColors.primaryStart,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Select →',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}