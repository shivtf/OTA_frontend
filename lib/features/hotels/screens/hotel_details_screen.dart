// lib/features/hotels/screens/hotel_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/auth/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/hotel_model.dart';

class HotelDetailsScreen extends StatefulWidget {
  const HotelDetailsScreen({super.key});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  bool _isFavorited = false;
  int _selectedImageIndex = 0;

  static const _hotelBlue = LinearGradient(
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
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
    final hotel = ModalRoute.of(context)!.settings.arguments as HotelModel?
        ?? HotelData.search().first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _anim, curve: Curves.easeOut),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildImageHeader(context, hotel, isDark, tc)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(hotel, isDark),
                    const SizedBox(height: 16),
                    _buildInfoStrip(hotel, isDark),
                    const SizedBox(height: 20),
                    _buildDescription(hotel, isDark),
                    const SizedBox(height: 20),
                    _buildAmenities(hotel, isDark),
                    const SizedBox(height: 20),
                    _buildPolicies(hotel, isDark),
                    const SizedBox(height: 20),
                    _buildReviews(hotel, isDark),
                    const SizedBox(height: 32),
                    _buildBookBar(context, hotel, isDark),
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

  Widget _buildImageHeader(BuildContext context, HotelModel hotel, bool isDark, ThemeController tc) {
    final images = hotel.images;
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Main image
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _selectedImageIndex = i),
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientForCategory(hotel.category),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: Text(images[i], style: const TextStyle(fontSize: 100))),
            ),
          ),
          // Dark overlay at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent,
                    isDark ? AppColors.darkBackground.withOpacity(0.95) : Colors.black.withOpacity(0.4)],
                ),
              ),
            ),
          ),
          // Top nav
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const CustomBackButton(useLightStyle: true),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                            _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _isFavorited ? AppColors.accent : Colors.white, size: 18)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: tc.toggleTheme,
                    child: Container(width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: Colors.white, size: 18)),
                  ),
                ],
              ),
            ),
          ),
          // Image dots
          Positioned(
            bottom: 14, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _selectedImageIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _selectedImageIndex == i ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow(HotelModel hotel, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(hotel.name,
                  style: TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              ShaderMask(
                shaderCallback: (b) => _hotelBlue.createShader(b),
                child: Text('\$${hotel.pricePerNight.toInt()}',
                    style: const TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              Text('per night', style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_rounded, size: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            const SizedBox(width: 3),
            Expanded(child: Text(hotel.address,
                style: TextStyle(fontSize: AppSizes.fontSM,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          ],
        ),
        const SizedBox(height: 10),
        Row(children: [
          ...List.generate(5, (i) => Icon(
              i < hotel.rating.floor() ? Icons.star_rounded : Icons.star_half_rounded,
              color: AppColors.accentGold, size: 16)),
          const SizedBox(width: 6),
          Text('${hotel.rating}', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          Text('  (${hotel.reviewCount} reviews)',
              style: TextStyle(fontSize: AppSizes.fontSM,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ]),
      ],
    );
  }

  Widget _buildInfoStrip(HotelModel hotel, bool isDark) {
    final items = [
      {'icon': Icons.category_rounded, 'label': 'Type', 'value': hotel.category},
      {'icon': Icons.login_rounded, 'label': 'Check-in', 'value': hotel.checkIn},
      {'icon': Icons.logout_rounded, 'label': 'Check-out', 'value': hotel.checkOut},
      {'icon': Icons.near_me_rounded, 'label': 'Distance', 'value': '${hotel.distanceFromCenter} km'},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => Column(
          children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData, color: const Color(0xFF1565C0), size: 18)),
            const SizedBox(height: 6),
            Text(item['label'] as String,
                style: TextStyle(fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            Text(item['value'] as String,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildDescription(HotelModel hotel, bool isDark) {
    return _Section(title: 'About', isDark: isDark, blueAccent: true,
        child: Text(hotel.description, style: TextStyle(
            fontSize: AppSizes.fontMD, height: 1.6,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)));
  }

  Widget _buildAmenities(HotelModel hotel, bool isDark) {
    final iconMap = {
      'Pool': Icons.pool_rounded,
      'Spa': Icons.spa_rounded,
      'Wi-Fi': Icons.wifi_rounded,
      'Restaurant': Icons.restaurant_rounded,
      'Gym': Icons.fitness_center_rounded,
      'Bar': Icons.local_bar_rounded,
      'Beach': Icons.beach_access_rounded,
      'Private Beach': Icons.beach_access_rounded,
      'Concierge': Icons.support_agent_rounded,
      'Room Service': Icons.room_service_rounded,
      'Valet': Icons.directions_car_rounded,
      'Water Park': Icons.waves_rounded,
      'Kids Club': Icons.child_care_rounded,
      'Tennis': Icons.sports_tennis_rounded,
      'Watersports': Icons.kitesurfing_rounded,
      'Self Laundry': Icons.local_laundry_service_rounded,
    };
    return _Section(title: 'Amenities', isDark: isDark, blueAccent: true,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.5,
        children: hotel.amenities.map((a) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(iconMap[a] ?? Icons.check_rounded, color: const Color(0xFF1565C0), size: 14),
              const SizedBox(width: 5),
              Expanded(child: Text(a, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  overflow: TextOverflow.ellipsis)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildPolicies(HotelModel hotel, bool isDark) {
    return _Section(title: 'Policies', isDark: isDark, blueAccent: true,
      child: Column(
        children: [
          _PolicyRow(icon: Icons.replay_rounded, label: 'Cancellation',
              value: hotel.freeCancellation ? 'Free cancellation available' : 'Non-refundable',
              positive: hotel.freeCancellation, isDark: isDark),
          const SizedBox(height: 10),
          _PolicyRow(icon: Icons.free_breakfast_rounded, label: 'Breakfast',
              value: hotel.breakfastIncluded ? 'Complimentary breakfast included' : 'Breakfast not included',
              positive: hotel.breakfastIncluded, isDark: isDark),
          const SizedBox(height: 10),
          _PolicyRow(icon: Icons.people_rounded, label: 'Check-in / Check-out',
              value: '${hotel.checkIn} check-in  ·  ${hotel.checkOut} check-out',
              positive: true, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildReviews(HotelModel hotel, bool isDark) {
    final dummyReviews = [
      {'name': 'Arjun P.', 'rating': 5, 'comment': 'Absolutely stunning property, exceeded all expectations!', 'date': '2 weeks ago'},
      {'name': 'Sara M.', 'rating': 4, 'comment': 'Great location and amazing staff. Breakfast was outstanding.', 'date': '1 month ago'},
    ];
    return _Section(title: 'Guest Reviews', isDark: isDark, blueAccent: true,
      child: Column(
        children: [
          Row(children: [
            ShaderMask(
                shaderCallback: (b) => _hotelBlue.createShader(b),
                child: Text('${hotel.rating}', style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(5, (i) => Icon(
                  i < hotel.rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.accentGold, size: 18))),
              const SizedBox(height: 4),
              Text('${hotel.reviewCount} verified reviews',
                  style: TextStyle(fontSize: AppSizes.fontSM,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ])),
          ]),
          const SizedBox(height: 16),
          ...dummyReviews.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 16,
                    backgroundColor: const Color(0xFF1565C0).withOpacity(0.15),
                    child: Text((r['name'] as String).substring(0, 1),
                        style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.w700))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['name'] as String, style: TextStyle(fontWeight: FontWeight.w700,
                      fontSize: AppSizes.fontSM,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  Text(r['date'] as String, style: TextStyle(fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ])),
                Row(children: List.generate(r['rating'] as int, (_) =>
                const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 13))),
              ]),
              const SizedBox(height: 8),
              Text(r['comment'] as String, style: TextStyle(fontSize: AppSizes.fontSM, height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildBookBar(BuildContext context, HotelModel hotel, bool isDark) {
    final total = hotel.pricePerNight * 3; // 3 nights
    return Row(
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('3 nights total', style: TextStyle(fontSize: AppSizes.fontSM,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ShaderMask(
              shaderCallback: (b) => _hotelBlue.createShader(b),
              child: Text('\$${total.toInt()}', style: const TextStyle(
                  fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: Colors.white))),
        ]),
        const SizedBox(width: 20),
        Expanded(
          child: GestureDetector(
            onTap: () => _showBookingSheet(context, hotel, isDark),
            child: Container(
              height: AppSizes.buttonHeight,
              decoration: BoxDecoration(
                gradient: _hotelBlue,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.4),
                      blurRadius: 16, offset: const Offset(0, 6))
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Reserve Now', style: TextStyle(
                      fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBookingSheet(BuildContext context, HotelModel hotel, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2))),
            Container(width: 64, height: 64,
                decoration: BoxDecoration(gradient: _hotelBlue, shape: BoxShape.circle),
                child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 30)),
            const SizedBox(height: 16),
            Text('Confirm Reservation', style: TextStyle(fontSize: AppSizes.fontXXL,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 6),
            Text(hotel.name, style: TextStyle(fontSize: AppSizes.fontMD,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _ConfirmItem(label: 'Check-in', value: 'Jun 15', isDark: isDark),
                _ConfirmItem(label: 'Check-out', value: 'Jun 18', isDark: isDark),
                _ConfirmItem(label: 'Total', value: '\$${(hotel.pricePerNight * 3).toInt()}',
                    isDark: isDark, highlight: true),
              ]),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Hotel reserved! 🏨', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              child: Container(
                height: AppSizes.buttonHeight,
                decoration: BoxDecoration(gradient: _hotelBlue,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
                child: const Center(child: Text('Confirm & Pay',
                    style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white))),
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
      default: return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
    }
  }
}

// ── shared sub-widgets ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark, blueAccent;
  const _Section({required this.title, required this.child, required this.isDark, this.blueAccent = false});

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
            decoration: BoxDecoration(
                gradient: blueAccent
                    ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2)),
          ),
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

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool positive, isDark;
  const _PolicyRow({required this.icon, required this.label, required this.value, required this.positive, required this.isDark});

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
      Text(label, style: TextStyle(fontSize: 11,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      const SizedBox(height: 4),
      highlight
          ? ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]).createShader(b),
          child: Text(value, style: const TextStyle(
              fontSize: AppSizes.fontLG, fontWeight: FontWeight.w800, color: Colors.white)))
          : Text(value, style: TextStyle(fontSize: AppSizes.fontLG, fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
    ]);
  }
}