// lib/features/home/widgets/destination_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';

class DestinationCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  final bool isDark;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.flightSearch),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          gradient: LinearGradient(
            colors: _gradientForCity(destination['city'] as String),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _gradientForCity(destination['city'] as String)
                  .first
                  .withValues(alpha:0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Big emoji background
            Positioned(
              right: -8,
              bottom: -4,
              child: Text(
                destination['emoji'] as String,
                style: const TextStyle(fontSize: 70),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      destination['code'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    destination['city'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    destination['country'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.8),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'from ',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        '\$${destination['price']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _gradientForCity(String city) {
    final map = {
      'Paris': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'Tokyo': [const Color(0xFFFF6B6B), const Color(0xFFEE2A7B)],
      'New York': [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      'Dubai': [const Color(0xFFFA8231), const Color(0xFFEB3349)],
      'Bali': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'London': [const Color(0xFF6C3CE1), const Color(0xFF9B5CFF)],
    };
    return map[city] ??
        [AppColors.primaryStart, AppColors.primaryEnd];
  }
}