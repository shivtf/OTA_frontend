// lib/features/flights/widgets/flight_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/flight_model.dart';

class FlightCard extends StatelessWidget {
  final FlightModel flight;
  final bool isDark;
  final VoidCallback onTap;

  const FlightCard({
    super.key,
    required this.flight,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top: airline + price
                  Row(
                    children: [
                      // Airline badge
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            flight.airlineCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flight.airline,
                              style: TextStyle(
                                fontSize: AppSizes.fontMD,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              flight.aircraft,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.primaryGradient.createShader(b),
                            child: Text(
                              '\$${flight.price.toInt()}',
                              style: const TextStyle(
                                fontSize: AppSizes.fontXL,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'per person',
                            style: TextStyle(
                              fontSize: 10,
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

                  // Flight path row
                  Row(
                    children: [
                      // Departure
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            flight.departure,
                            style: TextStyle(
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            flight.from,
                            style: TextStyle(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),

                      // Duration line
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            children: [
                              Text(
                                flight.duration,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _FlightPathLine(stops: flight.stops),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: flight.stops == 0
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  flight.stops == 0
                                      ? 'Non-stop'
                                      : '${flight.stops} stop',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: flight.stops == 0
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Arrival
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            flight.arrival,
                            style: TextStyle(
                              fontSize: AppSizes.fontXL,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            flight.to,
                            style: TextStyle(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom strip: amenities + rating + refundable
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkInputBg
                    : AppColors.lightInputBg,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusLarge),
                  bottomRight: Radius.circular(AppSizes.radiusLarge),
                ),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Amenities icons
                  if (flight.hasMeal)
                    _AmenityIcon(
                      icon: Icons.restaurant_rounded,
                      tooltip: 'Meal',
                      isDark: isDark,
                    ),
                  if (flight.hasWifi)
                    _AmenityIcon(
                      icon: Icons.wifi_rounded,
                      tooltip: 'Wi-Fi',
                      isDark: isDark,
                    ),
                  if (flight.hasEntertainment)
                    _AmenityIcon(
                      icon: Icons.tv_rounded,
                      tooltip: 'Entertainment',
                      isDark: isDark,
                    ),

                  const Spacer(),

                  // Seats left
                  if (flight.seatsLeft <= 5)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '${flight.seatsLeft} left',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),

                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.accentGold, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${flight.rating}',
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

                  const SizedBox(width: 10),

                  // Refundable badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: flight.isRefundable
                          ? AppColors.success.withOpacity(0.12)
                          : AppColors.lightTextSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      flight.isRefundable ? 'Refundable' : 'Non-refund',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: flight.isRefundable
                            ? AppColors.success
                            : AppColors.lightTextSecondary,
                      ),
                    ),
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

class _FlightPathLine extends StatelessWidget {
  final int stops;
  const _FlightPathLine({required this.stops});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryStart,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: CustomPaint(painter: _DashedLinePainter()),
        ),
        const Icon(Icons.flight_rounded, color: AppColors.primaryStart, size: 16),
        Expanded(
          child: CustomPaint(painter: _DashedLinePainter()),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primaryEnd,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryStart.withOpacity(0.3)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset((x + 4).clamp(0, size.width), size.height / 2), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _AmenityIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;

  const _AmenityIcon(
      {required this.icon, required this.tooltip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: AppColors.primaryStart),
      ),
    );
  }
}