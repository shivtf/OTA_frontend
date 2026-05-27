// lib/features/hotels/screens/hotel_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/auth/widgets/gradient_button.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/hotel_model.dart';

class HotelSearchScreen extends StatefulWidget {
  const HotelSearchScreen({super.key});

  @override
  State<HotelSearchScreen> createState() => _HotelSearchScreenState();
}

class _HotelSearchScreenState extends State<HotelSearchScreen> {
  final _cityController = TextEditingController(text: 'Dubai');
  String _checkIn = 'Jun 15, 2025';
  String _checkOut = 'Jun 18, 2025';
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Hotel', 'Resort', 'Boutique', 'Hostel'];

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  int get _nights {
    // simplified night count from dummy dates
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isDark, tc)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // City search
                  _buildCityField(isDark),
                  const SizedBox(height: 16),

                  // Check-in / Check-out
                  Row(
                    children: [
                      Expanded(
                        child: _DateCard(
                          label: 'Check-in',
                          date: _checkIn,
                          isDark: isDark,
                          onTap: () => _pickDate(context, isDark, isCheckIn: true),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_nights\nnights',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryStart,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _DateCard(
                          label: 'Check-out',
                          date: _checkOut,
                          isDark: isDark,
                          onTap: () => _pickDate(context, isDark, isCheckIn: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Rooms & guests
                  _buildGuestsCard(context, isDark),
                  const SizedBox(height: 24),

                  // Category filter
                  _buildCategoryRow(isDark),
                  const SizedBox(height: 28),

                  // Search button
                  GradientButton(
                    text: 'Search Hotels',
                    icon: Icons.search_rounded,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.hotelResults),
                  ),

                  const SizedBox(height: 32),

                  // Popular cities
                  _buildPopularCities(context, isDark),
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
            ? const LinearGradient(
          colors: [Color(0xFF0B1A2E), Color(0xFF0F2744)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
            : const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            children: [
              const CustomBackButton(useLightStyle: true),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Find Hotels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontXXL,
                          fontWeight: FontWeight.w800,
                        )),
                    Text('Search thousands of hotels worldwide',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppSizes.fontSM,
                        )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: tc.toggleTheme,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destination',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
                TextField(
                  controller: _cityController,
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestsCard(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showGuestsSheet(context, isDark),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_rounded,
                color: Color(0xFF1565C0), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Guests & Rooms',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                  Text(
                    '$_rooms Room${_rooms > 1 ? 's' : ''}  ·  ${_adults + _children} Guest${_adults + _children > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Property Type',
            style: TextStyle(
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            )),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) {
              final isActive = _selectedCategory == c;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isActive
                        ? null
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    borderRadius: BorderRadius.circular(20),
                    border: isActive
                        ? null
                        : Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder),
                    boxShadow: isActive
                        ? [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha:0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                        : null,
                  ),
                  child: Text(
                    c,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularCities(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular Destinations',
            style: TextStyle(
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            )),
        const SizedBox(height: 14),
        ...HotelData.popularCities.map((city) => GestureDetector(
          onTap: () {
            _cityController.text = city['city'] as String;
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Text(city['emoji'] as String,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(city['city'] as String,
                          style: TextStyle(
                            fontSize: AppSizes.fontMD,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          )),
                      Text(city['country'] as String,
                          style: TextStyle(
                            fontSize: AppSizes.fontXS,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          )),
                    ],
                  ),
                ),
                Text(
                  '${city['hotels']} hotels',
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, bool isDark,
      {required bool isCheckIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) =>
          Theme(data: isDark ? ThemeData.dark() : ThemeData.light(), child: child!),
    );
    if (picked != null) {
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final formatted = '${months[picked.month]} ${picked.day}, ${picked.year}';
      setState(() {
        if (isCheckIn) _checkIn = formatted;
        else _checkOut = formatted;
      });
    }
  }

  void _showGuestsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Guests & Rooms',
                  style: TextStyle(
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  )),
              const SizedBox(height: 20),
              _CounterRow(label: 'Rooms', sublabel: 'Max 9', value: _rooms, isDark: isDark,
                onDecrement: () { if (_rooms > 1) setLocal(() { setState(() => _rooms--); }); },
                onIncrement: () { if (_rooms < 9) setLocal(() { setState(() => _rooms++); }); },
              ),
              const SizedBox(height: 14),
              _CounterRow(label: 'Adults', sublabel: '18+ years', value: _adults, isDark: isDark,
                onDecrement: () { if (_adults > 1) setLocal(() { setState(() => _adults--); }); },
                onIncrement: () { if (_adults < 9) setLocal(() { setState(() => _adults++); }); },
              ),
              const SizedBox(height: 14),
              _CounterRow(label: 'Children', sublabel: '0–17 years', value: _children, isDark: isDark,
                onDecrement: () { if (_children > 0) setLocal(() { setState(() => _children--); }); },
                onIncrement: () { if (_children < 6) setLocal(() { setState(() => _children++); }); },
              ),
              const SizedBox(height: 24),
              GradientButton(text: 'Done', height: 48,
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── shared sub-widgets ─────────────────────────────────────────────────────

class _DateCard extends StatelessWidget {
  final String label, date;
  final bool isDark;
  final VoidCallback onTap;
  const _DateCard({required this.label, required this.date, required this.isDark, required this.onTap});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calendar_today_rounded, color: Color(0xFF1565C0), size: 14),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 10,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
            const SizedBox(height: 4),
            Text(date, style: TextStyle(
              fontSize: AppSizes.fontSM, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label, sublabel;
  final int value;
  final bool isDark;
  final VoidCallback onDecrement, onIncrement;
  const _CounterRow({required this.label, required this.sublabel, required this.value,
    required this.isDark, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            Text(sublabel, style: TextStyle(fontSize: AppSizes.fontXS,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ]),
        ),
        Row(children: [
          _Btn(icon: Icons.remove, onTap: onDecrement, enabled: value > 1),
          SizedBox(width: 36, child: Center(
            child: Text('$value', style: TextStyle(fontSize: AppSizes.fontLG,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          )),
          _Btn(icon: Icons.add, onTap: onIncrement, enabled: true),
        ]),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _Btn({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: enabled ? null : Colors.grey.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}