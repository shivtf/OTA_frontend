// lib/features/cars/screens/car_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/auth/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_back_button.dart';

class CarSearchScreen extends StatefulWidget {
  const CarSearchScreen({super.key});

  @override
  State<CarSearchScreen> createState() => _CarSearchScreenState();
}

class _CarSearchScreenState extends State<CarSearchScreen> {
  final _pickupController = TextEditingController(text: 'Dubai Airport, UAE');
  bool _differentDropoff = false;
  final _dropoffController = TextEditingController(text: 'Dubai Airport, UAE');
  String _pickupDate = 'Jun 15, 2025';
  String _pickupTime = '10:00 AM';
  String _dropoffDate = 'Jun 18, 2025';
  String _dropoffTime = '10:00 AM';
  String _selectedCategory = 'All';
  bool _driverIncluded = false;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': '🚗'},
    {'label': 'Economy', 'icon': '🚙'},
    {'label': 'Compact', 'icon': '🚘'},
    {'label': 'SUV', 'icon': '🚐'},
    {'label': 'Luxury', 'icon': '🏎️'},
    {'label': 'Van', 'icon': '🚌'},
  ];

  static const _carGreen = LinearGradient(
    colors: [Color(0xFF0A7D46), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isDark, tc)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup location
                  _buildLocationCard(isDark, isPickup: true),
                  const SizedBox(height: 12),

                  // Different dropoff toggle
                  GestureDetector(
                    onTap: () => setState(() => _differentDropoff = !_differentDropoff),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20, height: 20,
                        decoration: BoxDecoration(
                          gradient: _differentDropoff ? _carGreen : null,
                          color: _differentDropoff ? null : (isDark ? AppColors.darkCard : AppColors.lightInputBg),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: _differentDropoff
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text('Return to different location',
                          style: TextStyle(fontSize: AppSizes.fontSM, fontWeight: FontWeight.w500,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ]),
                  ),

                  if (_differentDropoff) ...[
                    const SizedBox(height: 12),
                    _buildLocationCard(isDark, isPickup: false),
                  ],

                  const SizedBox(height: 16),

                  // Pickup date/time row
                  _buildDateTimeRow(isDark, isPickup: true),
                  const SizedBox(height: 12),

                  // Dropoff date/time row
                  _buildDateTimeRow(isDark, isPickup: false),
                  const SizedBox(height: 20),

                  // Driver included toggle
                  _buildDriverToggle(isDark),
                  const SizedBox(height: 24),

                  // Car category
                  _buildCategoryRow(isDark),
                  const SizedBox(height: 28),

                  // Search button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.carResults),
                    child: Container(
                      height: AppSizes.buttonHeight,
                      decoration: BoxDecoration(
                        gradient: _carGreen,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0A7D46).withValues(alpha:0.4),
                              blurRadius: 16, offset: const Offset(0, 6))
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Search Cars', style: TextStyle(
                              fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildWhyRent(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, ThemeController tc) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(colors: [Color(0xFF062415), Color(0xFF0A3D26)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)
            : _carGreen,
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(children: [
            const CustomBackButton(useLightStyle: true),
            const SizedBox(width: 14),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rent a Car', style: TextStyle(color: Colors.white, fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800)),
                Text('Best deals on car rentals worldwide', style: TextStyle(color: Colors.white70, fontSize: AppSizes.fontSM)),
              ],
            )),
            GestureDetector(
              onTap: tc.toggleTheme,
              child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: Colors.white, size: 18)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLocationCard(bool isDark, {required bool isPickup}) {
    final controller = isPickup ? _pickupController : _dropoffController;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF0A7D46).withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(isPickup ? Icons.my_location_rounded : Icons.location_on_rounded,
                color: const Color(0xFF0A7D46), size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isPickup ? 'Pick-up Location' : 'Drop-off Location',
              style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          TextField(
            controller: controller,
            style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            decoration: const InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, filled: false),
          ),
        ])),
      ]),
    );
  }

  Widget _buildDateTimeRow(bool isDark, {required bool isPickup}) {
    final label = isPickup ? 'Pick-up' : 'Drop-off';
    final date = isPickup ? _pickupDate : _dropoffDate;
    final time = isPickup ? _pickupTime : _dropoffTime;

    return Row(children: [
      Expanded(child: _InfoTile(
        label: '$label Date', value: date,
        icon: Icons.calendar_today_rounded, isDark: isDark,
        accentColor: const Color(0xFF0A7D46),
        onTap: () => _pickDate(isDark, isPickup: isPickup),
      )),
      const SizedBox(width: 12),
      Expanded(child: _InfoTile(
        label: '$label Time', value: time,
        icon: Icons.access_time_rounded, isDark: isDark,
        accentColor: const Color(0xFF0A7D46),
        onTap: () => _pickTime(isDark, isPickup: isPickup),
      )),
    ]);
  }

  Widget _buildDriverToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(
                color: const Color(0xFF0A7D46).withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.person_rounded, color: Color(0xFF0A7D46), size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Include Driver', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          Text('Add a professional driver (+\$30/day)', style: TextStyle(fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ])),
        Switch(
          value: _driverIncluded,
          onChanged: (v) => setState(() => _driverIncluded = v),
          activeThumbColor: const Color(0xFF0A7D46),
        ),
      ]),
    );
  }

  Widget _buildCategoryRow(bool isDark) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Car Category', style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((c) {
            final isActive = _selectedCategory == c['label'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = c['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isActive ? _carGreen : null,
                  color: isActive ? null : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(20),
                  border: isActive ? null : Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  boxShadow: isActive ? [BoxShadow(color: const Color(0xFF0A7D46).withValues(alpha:0.3),
                      blurRadius: 8, offset: const Offset(0, 3))] : null,
                ),
                child: Row(children: [
                  Text(c['icon'] as String, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(c['label'] as String, style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _buildWhyRent(bool isDark) {
    final perks = [
      {'icon': Icons.verified_rounded, 'title': 'Verified Fleet', 'desc': 'All cars inspected & insured'},
      {'icon': Icons.support_agent_rounded, 'title': '24/7 Support', 'desc': 'Help whenever you need it'},
      {'icon': Icons.no_crash_rounded, 'title': 'Free Cancellation', 'desc': 'Cancel up to 48h before'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Why Rent with Wanderly?', style: TextStyle(fontSize: AppSizes.fontLG, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
      const SizedBox(height: 14),
      ...perks.map((p) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFF0A7D46).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(p['icon'] as IconData, color: const Color(0xFF0A7D46), size: 20)),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['title'] as String, style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            Text(p['desc'] as String, style: TextStyle(fontSize: AppSizes.fontSM,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ]),
        ]),
      )),
    ]);
  }

  Future<void> _pickDate(bool isDark, {required bool isPickup}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: isDark ? ThemeData.dark() : ThemeData.light(), child: child!),
    );
    if (picked != null) {
      final months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final f = '${months[picked.month]} ${picked.day}, ${picked.year}';
      setState(() { if (isPickup) _pickupDate = f; else _dropoffDate = f; });
    }
  }

  Future<void> _pickTime(bool isDark, {required bool isPickup}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(data: isDark ? ThemeData.dark() : ThemeData.light(), child: child!),
    );
    if (picked != null) {
      final f = picked.format(context);
      setState(() { if (isPickup) _pickupTime = f; else _dropoffTime = f; });
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isDark;
  final Color accentColor;
  final VoidCallback onTap;

  const _InfoTile({required this.label, required this.value, required this.icon,
    required this.isDark, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            Text(value, style: TextStyle(fontSize: AppSizes.fontSM, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}