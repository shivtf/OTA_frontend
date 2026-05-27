// lib/features/cars/screens/car_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/car_model.dart';

class CarDetailsScreen extends StatefulWidget {
  const CarDetailsScreen({super.key});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _isFavorited = false;
  int _days = 3;

  static const _carGreen = LinearGradient(
    colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final car = ModalRoute.of(context)!.settings.arguments as CarModel?
        ?? CarData.search().first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, car, isDark, tc)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(car, isDark),
                    const SizedBox(height: 16),
                    _buildSpecsGrid(car, isDark),
                    const SizedBox(height: 20),
                    _buildFeatures(car, isDark),
                    const SizedBox(height: 20),
                    _buildRentalInfo(car, isDark),
                    const SizedBox(height: 20),
                    _buildDaysSelector(car, isDark),
                    const SizedBox(height: 20),
                    _buildPriceBreakdown(car, isDark),
                    const SizedBox(height: 20),
                    _buildPolicies(car, isDark),
                    const SizedBox(height: 32),
                    _buildBookBar(context, car, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CarModel car, bool isDark, ThemeController tc) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        gradient: _gradientForCategory(car.category),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Big emoji
          Center(child: Text(car.emoji, style: const TextStyle(fontSize: 120))),
          // Dark overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
              ),
            ),
          ),
          // Nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const CustomBackButton(useLightStyle: true),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isFavorited = !_isFavorited),
                  child: Container(width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorited ? AppColors.accent : Colors.white, size: 18)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: tc.toggleTheme,
                  child: Container(width: 38, height: 38,
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: Colors.white, size: 18)),
                ),
              ]),
            ),
          ),
          // Bottom badges
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(children: [
              _HeaderBadge(label: car.category),
              const SizedBox(width: 8),
              _HeaderBadge(label: car.fuelType,
                  icon: car.fuelType == 'Electric' ? Icons.bolt_rounded : Icons.local_gas_station_rounded),
              const Spacer(),
              _HeaderBadge(label: '⭐ ${car.rating}'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(CarModel car, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${car.brand} ${car.name}',
                style: TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.store_rounded, size: 14, color: Color(0xFF0A7D46)),
              const SizedBox(width: 4),
              Text('by ${car.rentalCompany}', style: TextStyle(fontSize: AppSizes.fontSM,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.star_rounded, size: 14, color: AppColors.accentGold),
              const SizedBox(width: 3),
              Text('${car.rating} (${car.reviewCount})', style: TextStyle(fontSize: AppSizes.fontSM,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ShaderMask(
              shaderCallback: (b) => _carGreen.createShader(b),
              child: Text('\$${car.pricePerDay.toInt()}',
                  style: const TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: Colors.white))),
          Text('per day', style: TextStyle(fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ]),
      ],
    );
  }

  Widget _buildSpecsGrid(CarModel car, bool isDark) {
    final specs = [
      {'icon': Icons.people_rounded, 'label': 'Seats', 'value': '${car.seats} people'},
      {'icon': Icons.settings_rounded, 'label': 'Transmission', 'value': car.transmission},
      {'icon': Icons.local_gas_station_rounded, 'label': 'Fuel', 'value': car.fuelType},
      {'icon': Icons.luggage_rounded, 'label': 'Luggage', 'value': '${car.luggage} bags'},
    ];

    return _Section(title: 'Specifications', isDark: isDark,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.8),
        itemCount: specs.length,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(children: [
            Icon(specs[i]['icon'] as IconData, color: const Color(0xFF0A7D46), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(specs[i]['label'] as String, style: TextStyle(fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  Text(specs[i]['value'] as String, style: TextStyle(fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      overflow: TextOverflow.ellipsis),
                ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildFeatures(CarModel car, bool isDark) {
    return _Section(title: 'Features & Extras', isDark: isDark,
      child: Wrap(
        spacing: 10, runSpacing: 10,
        children: car.features.map((f) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A7D46).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0A7D46).withOpacity(0.2)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF0A7D46), size: 14),
            const SizedBox(width: 6),
            Text(f, style: TextStyle(fontSize: AppSizes.fontSM, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildRentalInfo(CarModel car, bool isDark) {
    return _Section(title: 'Rental Details', isDark: isDark,
      child: Column(children: [
        _InfoRow(icon: Icons.location_on_rounded, label: 'Pick-up',
            value: car.pickupLocation, isDark: isDark),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.flag_rounded, label: 'Drop-off',
            value: car.dropoffLocation, isDark: isDark),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.calendar_today_rounded, label: 'Pick-up Date',
            value: 'Jun 15, 2025 · 10:00 AM', isDark: isDark),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.calendar_today_rounded, label: 'Drop-off Date',
            value: 'Jun 18, 2025 · 10:00 AM', isDark: isDark),
      ]),
    );
  }

  Widget _buildDaysSelector(CarModel car, bool isDark) {
    return _Section(title: 'Rental Duration', isDark: isDark,
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Number of Days', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          Text('Adjust to see updated pricing', style: TextStyle(fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ])),
        Row(children: [
          GestureDetector(
            onTap: () { if (_days > 1) setState(() => _days--); },
            child: Container(width: 36, height: 36,
                decoration: BoxDecoration(
                    gradient: _days > 1 ? _carGreen : null,
                    color: _days <= 1 ? Colors.grey.withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.remove, color: Colors.white, size: 18)),
          ),
          SizedBox(width: 40,
              child: Center(child: Text('$_days', style: TextStyle(fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)))),
          GestureDetector(
            onTap: () { if (_days < 30) setState(() => _days++); },
            child: Container(width: 36, height: 36,
                decoration: BoxDecoration(gradient: _carGreen, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add, color: Colors.white, size: 18)),
          ),
        ]),
      ]),
    );
  }

  Widget _buildPriceBreakdown(CarModel car, bool isDark) {
    final base = car.pricePerDay * _days;
    final insurance = 15.0 * _days;
    final fee = 12.0;
    final total = base + insurance + fee;

    return _Section(title: 'Price Breakdown', isDark: isDark,
      child: Column(children: [
        _PriceRow(label: 'Car rental (${_days}d × \$${car.pricePerDay.toInt()})',
            amount: base, isDark: isDark),
        _PriceRow(label: 'Insurance (\$15/day)', amount: insurance, isDark: isDark),
        _PriceRow(label: 'Service fee', amount: fee, isDark: isDark),
        Divider(height: 20, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Row(children: [
          Text('Total', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const Spacer(),
          ShaderMask(
              shaderCallback: (b) => _carGreen.createShader(b),
              child: Text('\$${total.toInt()}',
                  style: const TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: Colors.white))),
        ]),
      ]),
    );
  }

  Widget _buildPolicies(CarModel car, bool isDark) {
    return _Section(title: 'Policies', isDark: isDark,
      child: Column(children: [
        _PolicyRow(icon: Icons.replay_rounded, label: 'Cancellation',
            value: car.freeCancellation ? 'Free cancellation up to 48h before pickup' : 'Non-refundable',
            positive: car.freeCancellation, isDark: isDark),
        const SizedBox(height: 10),
        _PolicyRow(icon: Icons.speed_rounded, label: 'Mileage',
            value: car.unlimitedMileage ? 'Unlimited kilometres included' : 'Limited mileage — surcharge may apply',
            positive: car.unlimitedMileage, isDark: isDark),
        const SizedBox(height: 10),
        _PolicyRow(icon: Icons.local_gas_station_rounded, label: 'Fuel Policy',
            value: 'Full-to-full — return with same fuel level',
            positive: true, isDark: isDark),
      ]),
    );
  }

  Widget _buildBookBar(BuildContext context, CarModel car, bool isDark) {
    final total = (car.pricePerDay * _days) + (15.0 * _days) + 12.0;
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$_days day${_days > 1 ? 's' : ''} total',
            style: TextStyle(fontSize: AppSizes.fontSM,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ShaderMask(
            shaderCallback: (b) => _carGreen.createShader(b),
            child: Text('\$${total.toInt()}',
                style: const TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: Colors.white))),
      ]),
      const SizedBox(width: 20),
      Expanded(
        child: GestureDetector(
          onTap: () => _showBookingSheet(context, car, isDark, total),
          child: Container(
            height: AppSizes.buttonHeight,
            decoration: BoxDecoration(
              gradient: _carGreen,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              boxShadow: [BoxShadow(color: const Color(0xFF0A7D46).withOpacity(0.4),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Book Now', style: TextStyle(
                    fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  void _showBookingSheet(BuildContext context, CarModel car, bool isDark, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2))),
          Container(width: 64, height: 64,
              decoration: BoxDecoration(gradient: _carGreen, shape: BoxShape.circle),
              child: Text(car.emoji, style: const TextStyle(fontSize: 32),
                  textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Text('Confirm Booking', style: TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          Text('${car.brand} ${car.name}  ·  ${car.rentalCompany}',
              style: TextStyle(fontSize: AppSizes.fontMD,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ConfirmItem(label: 'Pick-up', value: 'Jun 15', isDark: isDark),
              _ConfirmItem(label: 'Return', value: 'Jun 18', isDark: isDark),
              _ConfirmItem(label: 'Duration', value: '$_days days', isDark: isDark),
              _ConfirmItem(label: 'Total', value: '\$${total.toInt()}', isDark: isDark, highlight: true),
            ]),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Row(children: [
                  Text(car.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Text('Car booked successfully! 🎉',
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            },
            child: Container(
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(gradient: _carGreen,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
              child: const Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Confirm & Pay', style: TextStyle(
                      fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              )),
            ),
          ),
        ]),
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
      default: return _carGreen;
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeaderBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon!, color: Colors.white, size: 12), const SizedBox(width: 4)],
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _Section({required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(gradient: const LinearGradient(
                  colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(
              color: const Color(0xFF0A7D46).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF0A7D46), size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        Text(value, style: TextStyle(fontSize: AppSizes.fontSM, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      ])),
    ]);
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDark;
  const _PriceRow({required this.label, required this.amount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: AppSizes.fontSM,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const Spacer(),
        Text('\$${amount.toInt()}', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      ]),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool positive, isDark;
  const _PolicyRow({required this.icon, required this.label, required this.value,
    required this.positive, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 36, height: 36,
          decoration: BoxDecoration(
              color: (positive ? AppColors.success : AppColors.warning).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: positive ? AppColors.success : AppColors.warning, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: AppSizes.fontSM, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        Text(value, style: TextStyle(fontSize: 11,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      ])),
    ]);
  }
}

class _ConfirmItem extends StatelessWidget {
  final String label, value;
  final bool isDark, highlight;
  const _ConfirmItem({required this.label, required this.value, required this.isDark, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(fontSize: 10,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      const SizedBox(height: 4),
      highlight
          ? ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF0A7D46), Color(0xFF34D399)]).createShader(b),
          child: Text(value, style: const TextStyle(
              fontSize: AppSizes.fontMD, fontWeight: FontWeight.w800, color: Colors.white)))
          : Text(value, style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
    ]);
  }
}