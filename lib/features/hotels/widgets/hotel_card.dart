// lib/features/hotels/widgets/hotel_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/hotel_model.dart';

class HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final bool isDark;
  final VoidCallback onTap;

  const HotelCard({super.key, required this.hotel, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: isDark ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area (emoji placeholder with gradient)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge),
                  topRight: Radius.circular(AppSizes.radiusLarge),
                ),
                gradient: LinearGradient(
                  colors: _gradientForCategory(hotel.category),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Big emoji
                  Center(child: Text(hotel.images.first, style: const TextStyle(fontSize: 72))),
                  // Badges
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(hotel.category,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (hotel.isFeatured)
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Featured',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  // Rating overlay
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 13),
                          const SizedBox(width: 3),
                          Text('${hotel.rating}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(hotel.name,
                            style: TextStyle(
                              fontSize: AppSizes.fontMD,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      ShaderMask(
                        shaderCallback: (b) =>
                            const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)])
                                .createShader(b),
                        child: Text('\$${hotel.pricePerNight.toInt()}',
                            style: const TextStyle(
                                fontSize: AppSizes.fontLG, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 3),
                      Text('${hotel.city}  ·  ${hotel.distanceFromCenter} km from center',
                          style: TextStyle(
                            fontSize: AppSizes.fontXS,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Amenities chips (first 4)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hotel.amenities.take(4).map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(a, style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF1565C0))),
                    )).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (hotel.breakfastIncluded)
                        _Badge(label: 'Breakfast', positive: true),
                      if (hotel.breakfastIncluded) const SizedBox(width: 6),
                      if (hotel.freeCancellation)
                        _Badge(label: 'Free Cancel', positive: true),
                      const Spacer(),
                      Text('per night',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          )),
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

  List<Color> _gradientForCategory(String cat) {
    switch (cat) {
      case 'Resort': return [const Color(0xFF0077B6), const Color(0xFF00B4D8)];
      case 'Boutique': return [const Color(0xFF6D28D9), const Color(0xFFA78BFA)];
      case 'Hostel': return [const Color(0xFF059669), const Color(0xFF34D399)];
      default: return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool positive;
  const _Badge({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (positive ? AppColors.success : AppColors.warning).withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w600,
        color: positive ? AppColors.success : AppColors.warning,
      )),
    );
  }
}