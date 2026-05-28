// lib/features/flights/screens/flight_search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../auth/widgets/gradient_button.dart';
import '../providers/flight_booking_provider.dart';

class FlightSearchScreen extends StatefulWidget {
  const FlightSearchScreen({super.key});

  @override
  State<FlightSearchScreen> createState() => _FlightSearchScreenState();
}

class _FlightSearchScreenState extends State<FlightSearchScreen>
    with SingleTickerProviderStateMixin {
  String _tripType = 'One Way';
  final _fromController = TextEditingController(text: 'DEL');
  final _toController = TextEditingController(text: 'DXB');
  // Store as DateTime internally, display formatted
  DateTime _departDateTime = DateTime.now().add(const Duration(days: 14));
  DateTime _returnDateTime = DateTime.now().add(const Duration(days: 21));
  int _adults = 1;
  int _children = 0;
  String _cabin = 'Economy';
  bool _isSearching = false;

  String get _departDate =>
      '${_departDateTime.year}-${_departDateTime.month.toString().padLeft(2, '0')}-${_departDateTime.day.toString().padLeft(2, '0')}';
  String get _returnDate =>
      '${_returnDateTime.year}-${_returnDateTime.month.toString().padLeft(2, '0')}-${_returnDateTime.day.toString().padLeft(2, '0')}';
  String get _departDisplay =>
      '${_departDateTime.day} ${_monthName(_departDateTime.month)}, ${_departDateTime.year}';
  String get _returnDisplay =>
      '${_returnDateTime.day} ${_monthName(_returnDateTime.month)}, ${_returnDateTime.year}';

  String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];

  late TabController _tabController;

  final List<String> _tripTypes = ['One Way', 'Round Trip', 'Multi-City'];
  final List<String> _cabins = ['Economy', 'Business', 'First Class'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _swapAirports() {
    final tmp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tmp;
    setState(() {});
  }

  Future<void> _onSearch() async {
    final from = _fromController.text.trim().toUpperCase();
    final to = _toController.text.trim().toUpperCase();
    if (from.isEmpty || to.isEmpty || from.length != 3 || to.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please enter valid 3-letter airport codes (e.g. DEL, BOM)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    final provider = context.read<FlightBookingProvider>();
    provider.reset();

    final cabinMap = {
      'Economy': 'economy',
      'Business': 'business',
      'First Class': 'first',
    };

    final ok = await provider.searchFlights(
      origin: from,
      destination: to,
      departureDate: _departDate,
      returnDate: _tripType == 'Round Trip' ? _returnDate : null,
      adults: _adults,
      children: _children,
      cabinClass: cabinMap[_cabin] ?? 'economy',
    );

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (ok) {
      Navigator.of(context).pushNamed(
        AppRoutes.flightResults,
        arguments: {
          'from': from,
          'to': to,
          'fromCity': from,
          'toCity': to,
          'departureDate': _departDate,
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Search failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          // App bar
          SliverToBoxAdapter(
            child: _buildHeader(context, isDark, tc),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip type tabs
                  _buildTripTypeTabs(isDark),
                  const SizedBox(height: 24),

                  // From / To card
                  _buildRouteCard(isDark),
                  const SizedBox(height: 16),

                  // Date row
                  _buildDateRow(isDark),
                  const SizedBox(height: 16),

                  // Passengers + cabin row
                  _buildPassengerCabinRow(isDark),
                  const SizedBox(height: 32),

                  // Search button
                  GradientButton(
                    text: 'Search Flights',
                    icon: Icons.search_rounded,
                    isLoading: _isSearching,
                    onPressed: _isSearching ? null : _onSearch,
                  ),

                  const SizedBox(height: 32),

                  // Recent searches
                  _buildRecentSearches(isDark),
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
                colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Color(0xFF6C3CE1), Color(0xFF9B5CFF)],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              CustomBackButton(useLightStyle: true),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Search Flights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: tc.toggleTheme,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
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

  Widget _buildTripTypeTabs(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: _tripTypes.map((t) {
          final isActive = _tripType == t;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tripType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteCard(bool isDark) {
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
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              // From
              _AirportField(
                label: 'From',
                icon: Icons.flight_takeoff_rounded,
                controller: _fromController,
                isDark: isDark,
                isTop: true,
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                indent: 56,
              ),
              // To
              _AirportField(
                label: 'To',
                icon: Icons.flight_land_rounded,
                controller: _toController,
                isDark: isDark,
                isTop: false,
              ),
            ],
          ),

          // Swap button
          Positioned(
            right: 16,
            child: GestureDetector(
              onTap: _swapAirports,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _DateCard(
            label: 'Departure',
            date: _departDate,
            icon: Icons.calendar_today_rounded,
            isDark: isDark,
            onTap: () => _pickDate(context, isDark, isDepart: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateCard(
            label: _tripType == 'One Way' ? 'Return' : 'Return',
            date: _tripType == 'One Way' ? 'Add date' : _returnDate,
            icon: Icons.calendar_today_rounded,
            isDark: isDark,
            disabled: _tripType == 'One Way',
            onTap: () {
              if (_tripType != 'One Way')
                _pickDate(context, isDark, isDepart: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerCabinRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _InfoCard(
            label: 'Passengers',
            value:
                '${_adults + _children} Traveller${_adults + _children > 1 ? 's' : ''}',
            icon: Icons.people_rounded,
            isDark: isDark,
            onTap: () => _showPassengerSheet(context, isDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoCard(
            label: 'Cabin Class',
            value: _cabin,
            icon: Icons.airline_seat_recline_extra_rounded,
            isDark: isDark,
            onTap: () => _showCabinSheet(context, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    final recents = [
      {'from': 'DEL', 'to': 'DXB', 'date': 'Jun 15'},
      {'from': 'BOM', 'to': 'LHR', 'date': 'Jul 3'},
      {'from': 'MAA', 'to': 'SIN', 'date': 'Jul 20'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Searches',
          style: TextStyle(
            fontSize: AppSizes.fontLG,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 14),
        ...recents.map((r) => _RecentSearchTile(
              from: r['from']!,
              to: r['to']!,
              date: r['date']!,
              isDark: isDark,
              onTap: () {
                _fromController.text = r['from']!;
                _toController.text = r['to']!;
                setState(() {});
              },
            )),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, bool isDark,
      {required bool isDepart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: isDark ? ThemeData.dark() : ThemeData.light(),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${_monthName(picked.month)} ${picked.day}, ${picked.year}';
      setState(() {
        if (isDepart)
          _departDateTime = picked;
        else
          _returnDateTime = picked;
      });
    }
  }

  void _showPassengerSheet(BuildContext context, bool isDark) {
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
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Passengers',
                  style: TextStyle(
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  )),
              const SizedBox(height: 24),
              _CounterRow(
                label: 'Adults',
                sublabel: '12+ years',
                value: _adults,
                isDark: isDark,
                onDecrement: () {
                  if (_adults > 1)
                    setLocal(() {
                      setState(() => _adults--);
                    });
                },
                onIncrement: () {
                  if (_adults < 9)
                    setLocal(() {
                      setState(() => _adults++);
                    });
                },
              ),
              const SizedBox(height: 16),
              _CounterRow(
                label: 'Children',
                sublabel: '2–11 years',
                value: _children,
                isDark: isDark,
                onDecrement: () {
                  if (_children > 0)
                    setLocal(() {
                      setState(() => _children--);
                    });
                },
                onIncrement: () {
                  if (_children < 8)
                    setLocal(() {
                      setState(() => _children++);
                    });
                },
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Done',
                height: 48,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCabinSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Cabin Class',
                style: TextStyle(
                  fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
            const SizedBox(height: 20),
            ..._cabins.map((c) => GestureDetector(
                  onTap: () {
                    setState(() => _cabin = c);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _cabin == c ? AppColors.primaryGradient : null,
                      color: _cabin != c
                          ? (isDark
                              ? AppColors.darkInputBg
                              : AppColors.lightInputBg)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      border: _cabin != c
                          ? Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.airline_seat_recline_extra_rounded,
                          color: _cabin == c
                              ? Colors.white
                              : AppColors.primaryStart,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          c,
                          style: TextStyle(
                            fontSize: AppSizes.fontMD,
                            fontWeight: FontWeight.w600,
                            color: _cabin == c
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                          ),
                        ),
                        const Spacer(),
                        if (_cabin == c)
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // String _monthName(int m) => const [
  //       '',
  //       'Jan',
  //       'Feb',
  //       'Mar',
  //       'Apr',
  //       'May',
  //       'Jun',
  //       'Jul',
  //       'Aug',
  //       'Sep',
  //       'Oct',
  //       'Nov',
  //       'Dec'
  //     ][m];
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AirportField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool isDark;
  final bool isTop;

  const _AirportField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.isDark,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryStart, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                TextField(
                  controller: controller,
                  style: TextStyle(
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    letterSpacing: 2,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final bool isDark;
  final bool disabled;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.date,
    required this.icon,
    required this.isDark,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: disabled
                    ? (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary)
                    : AppColors.primaryStart,
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: disabled
                          ? (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryStart, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 18),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final int value;
  final bool isDark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CounterRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.isDark,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  )),
              Text(sublabel,
                  style: TextStyle(
                    fontSize: AppSizes.fontXS,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  )),
            ],
          ),
        ),
        Row(
          children: [
            _CounterButton(
              icon: Icons.remove,
              onTap: onDecrement,
              enabled: value > (label == 'Adults' ? 1 : 0),
            ),
            SizedBox(
              width: 36,
              child: Center(
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
            _CounterButton(icon: Icons.add, onTap: onIncrement, enabled: true),
          ],
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CounterButton(
      {required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  final String from, to, date;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentSearchTile({
    required this.from,
    required this.to,
    required this.date,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.history_rounded,
                color: AppColors.primaryStart, size: 18),
            const SizedBox(width: 12),
            Text(from,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMD,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            Text(to,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.fontMD,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
            const Spacer(),
            Text(date,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
