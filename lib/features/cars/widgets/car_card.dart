// lib/features/cars/widgets/car_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/car_model.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final bool isDark;
  final VoidCallback onTap;

  const CarCard({super.key, required this.car, required this.isDark, required this.onTap});

  static const _carGreen = LinearGradient(
    colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
            // Car visual header
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLarge),
                  topRight: Radius.circular(AppSizes.radiusLarge),
                ),
                gradient: _gradientForCategory(car.category),
              ),
              child: Stack(
                children: [
                  // Big emoji centered
                  Center(
                    child: Text(car.emoji, style: const TextStyle(fontSize: 80)),
                  ),
                  // Category badge
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(car.category,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  // Fuel badge
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: car.fuelType == 'Electric'
                            ? Colors.blue.withOpacity(0.85)
                            : Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            car.fuelType == 'Electric' ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                            color: Colors.white, size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(car.fuelType,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Rating bottom right
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 13),
                          const SizedBox(width: 3),
                          Text('${car.rating}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${car.brand} ${car.name}',
                                style: TextStyle(
                                  fontSize: AppSizes.fontMD,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                )),
                            Text(car.rentalCompany,
                                style: TextStyle(fontSize: AppSizes.fontXS,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => _carGreen.createShader(b),
                            child: Text('\$${car.pricePerDay.toInt()}',
                                style: const TextStyle(fontSize: AppSizes.fontXL,
                                    fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                          Text('per day', style: TextStyle(fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Specs row
                  Row(
                    children: [
                      _SpecChip(icon: Icons.people_rounded, label: '${car.seats} seats', isDark: isDark),
                      const SizedBox(width: 8),
                      _SpecChip(icon: Icons.settings_rounded, label: car.transmission, isDark: isDark),
                      const SizedBox(width: 8),
                      _SpecChip(icon: Icons.luggage_rounded, label: '${car.luggage} bags', isDark: isDark),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Bottom badges
                  Row(
                    children: [
                      if (car.unlimitedMileage)
                        _Badge(label: 'Unlimited KM', positive: true),
                      if (car.unlimitedMileage) const SizedBox(width: 6),
                      if (car.freeCancellation)
                        _Badge(label: 'Free Cancel', positive: true),
                      const Spacer(),
                      Text('${car.reviewCount} reviews',
                          style: TextStyle(fontSize: 10,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
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

  LinearGradient _gradientForCategory(String cat) {
    switch (cat) {
      case 'Luxury': return const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF4A0E8F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'SUV': return const LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF40916C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
      case 'Van': return const LinearGradient(colors: [Color(0xFF1D3557), Color(0xFF457B9D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
      default: return const LinearGradient(colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
          begin: Alignment.topLeft, end: Alignment.bottomRight);
    }
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _SpecChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A7D46).withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFF0A7D46).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0A7D46)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: Color(0xFF0A7D46))),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool positive;
  const _Badge({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}