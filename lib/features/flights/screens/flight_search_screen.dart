// lib/features/flights/screens/flight_search_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/meta_service.dart';
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

  // Each field has a display controller (shows "DEL · Indira Gandhi...")
  // and a stored iataCode used for the actual search
  final _fromDisplayController = TextEditingController();
  final _toDisplayController = TextEditingController();
  String _fromCode = 'JFK';
  String _toCode = 'LAX';
  String _fromCity = 'New York';
  String _toCity = 'Los Angeles';

  DateTime _departDateTime = DateTime.now().add(const Duration(days: 14));
  DateTime _returnDateTime = DateTime.now().add(const Duration(days: 21));
  int _adults = 1;
  int _children = 0;
  String _cabin = 'Economy';
  bool _isSearching = false;

  // Recent searches — loaded from shared_preferences, persisted on every search
  static const _kRecentSearchesKey = 'flight_recent_searches';
  List<Map<String, String>> _recentSearches = [];

  late TabController _tabController;
  final List<String> _tripTypes = ['One Way', 'Round Trip', 'Multi-City'];
  final List<String> _cabins = ['Economy', 'Business', 'First Class'];

  String get _departDate =>
      '${_departDateTime.year}-${_departDateTime.month.toString().padLeft(2, '0')}-${_departDateTime.day.toString().padLeft(2, '0')}';
  String get _returnDate =>
      '${_returnDateTime.year}-${_returnDateTime.month.toString().padLeft(2, '0')}-${_returnDateTime.day.toString().padLeft(2, '0')}';

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

  String get _departDisplay =>
      '${_departDateTime.day} ${_monthName(_departDateTime.month)}, ${_departDateTime.year}';
  String get _returnDisplay =>
      '${_returnDateTime.day} ${_monthName(_returnDateTime.month)}, ${_returnDateTime.year}';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Set initial display values
    _fromDisplayController.text = 'JFK · New York';
    _toDisplayController.text = 'LAX · Los Angeles';
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _fromDisplayController.dispose();
    _toDisplayController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentSearchesKey) ?? [];
    if (!mounted) return;
    setState(() {
      _recentSearches = raw
          .map((e) => Map<String, String>.from(
          (jsonDecode(e) as Map).cast<String, String>()))
          .toList();
    });
  }

  Future<void> _saveRecentSearch({
    required String from,
    required String to,
    required String fromCity,
    required String toCity,
    required String date,
  }) async {
    final entry = {
      'from': from,
      'to': to,
      'fromCity': fromCity,
      'toCity': toCity,
      'date': date,
    };
    // Remove duplicate if same route already exists, then insert at front
    _recentSearches
        .removeWhere((r) => r['from'] == from && r['to'] == to);
    _recentSearches.insert(0, entry);
    // Keep only the 5 most recent
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kRecentSearchesKey,
      _recentSearches.map((e) => jsonEncode(e)).toList(),
    );
    if (mounted) setState(() {});
  }

  void _swapAirports() {
    setState(() {
      final tmpCode = _fromCode;
      final tmpCity = _fromCity;
      final tmpDisplay = _fromDisplayController.text;
      _fromCode = _toCode;
      _fromCity = _toCity;
      _fromDisplayController.text = _toDisplayController.text;
      _toCode = tmpCode;
      _toCity = tmpCity;
      _toDisplayController.text = tmpDisplay;
    });
  }

  Future<void> _onSearch() async {
    if (_fromCode.isEmpty || _toCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select origin and destination airports'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_fromCode == _toCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin and destination cannot be the same'),
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
      origin: _fromCode,
      destination: _toCode,
      departureDate: _departDate,
      returnDate: _tripType == 'Round Trip' ? _returnDate : null,
      adults: _adults,
      children: _children,
      cabinClass: cabinMap[_cabin] ?? 'economy',
    );

    if (!mounted) return;
    setState(() => _isSearching = false);

    if (ok) {
      // Persist to recent searches before navigating
      await _saveRecentSearch(
        from: _fromCode,
        to: _toCode,
        fromCity: _fromCity,
        toCity: _toCity,
        date: _departDisplay,
      );
      Navigator.of(context).pushNamed(
        AppRoutes.flightResults,
        arguments: {
          'from': _fromCode,
          'to': _toCode,
          'fromCity': _fromCity,
          'toCity': _toCity,
          'departureDate': _departDate,
          // Total seat-holding passengers (adults + children; infants sit on laps)
          'passengerCount': _adults + _children,
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

  /// Opens the airport/city search bottom sheet and returns selected place
  Future<void> _openPlacePicker({required bool isFrom}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlacePickerSheet(isDark: isDark),
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _fromCode = result.iataCode;
        _fromCity = result.city.isNotEmpty ? result.city : result.name;
        _fromDisplayController.text = result.shortLabel;
      } else {
        _toCode = result.iataCode;
        _toCity = result.city.isNotEmpty ? result.city : result.name;
        _toDisplayController.text = result.shortLabel;
      }
    });
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
                  _buildTripTypeTabs(isDark),
                  const SizedBox(height: 24),
                  _buildRouteCard(isDark),
                  const SizedBox(height: 16),
                  _buildDateRow(isDark),
                  const SizedBox(height: 16),
                  _buildPassengerCabinRow(isDark),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: 'Search Flights',
                    icon: Icons.search_rounded,
                    isLoading: _isSearching,
                    onPressed: _isSearching ? null : _onSearch,
                  ),
                  const SizedBox(height: 32),
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
              // From — tappable, opens picker
              _AirportTile(
                label: 'From',
                icon: Icons.flight_takeoff_rounded,
                iataCode: _fromCode,
                displayText: _fromDisplayController.text,
                isDark: isDark,
                onTap: () => _openPlacePicker(isFrom: true),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                indent: 56,
              ),
              // To — tappable, opens picker
              _AirportTile(
                label: 'To',
                icon: Icons.flight_land_rounded,
                iataCode: _toCode,
                displayText: _toDisplayController.text,
                isDark: isDark,
                onTap: () => _openPlacePicker(isFrom: false),
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
            date: _departDisplay,
            icon: Icons.calendar_today_rounded,
            isDark: isDark,
            onTap: () => _pickDate(context, isDark, isDepart: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateCard(
            label: 'Return',
            date: _tripType == 'One Way' ? 'Add date' : _returnDisplay,
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
            value: () {
              final total = _adults + _children;
              return '$total Traveller${total > 1 ? 's' : ''}';
            }(),
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
    if (_recentSearches.isEmpty) return const SizedBox.shrink();
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
        ..._recentSearches.map((r) => _RecentSearchTile(
          from: r['from']!,
          to: r['to']!,
          date: r['date']!,
          isDark: isDark,
          onTap: () {
            setState(() {
              _fromCode = r['from']!;
              _toCode = r['to']!;
              _fromCity = r['fromCity'] ?? r['from']!;
              _toCity = r['toCity'] ?? r['to']!;
              _fromDisplayController.text =
              '${r['from']} · ${r['fromCity'] ?? r['from']}';
              _toDisplayController.text =
              '${r['to']} · ${r['toCity'] ?? r['to']}';
            });
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
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Passengers',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
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
                  if (_adults > 1) setSheetState(() => _adults--);
                },
                onIncrement: () => setSheetState(() => _adults++),
              ),
              const SizedBox(height: 16),
              _CounterRow(
                label: 'Children',
                sublabel: '2–11 years',
                value: _children,
                isDark: isDark,
                onDecrement: () {
                  if (_children > 0) setSheetState(() => _children--);
                },
                onIncrement: () => setSheetState(() => _children++),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Done',
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
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
            Text('Cabin Class',
                style: TextStyle(
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
            const SizedBox(height: 16),
            ..._cabins.map((c) => ListTile(
              title: Text(c,
                  style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)),
              trailing: _cabin == c
                  ? Icon(Icons.check_circle_rounded,
                  color: AppColors.primaryStart)
                  : null,
              onTap: () {
                setState(() => _cabin = c);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Airport tile (tappable, not editable directly) ────────────────────────────

class _AirportTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String iataCode;
  final String displayText;
  final bool isDark;
  final VoidCallback onTap;

  const _AirportTile({
    required this.label,
    required this.icon,
    required this.iataCode,
    required this.displayText,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                  const SizedBox(height: 2),
                  // Big IATA code
                  Text(
                    iataCode,
                    style: TextStyle(
                      fontSize: AppSizes.fontXXL,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  // City / airport name below
                  if (displayText.isNotEmpty)
                    Text(
                      displayText.contains('·')
                          ? displayText.split('·').last.trim()
                          : displayText,
                      style: TextStyle(
                        fontSize: AppSizes.fontXS,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Place Picker bottom sheet with live search ────────────────────────────────

class _PlacePickerSheet extends StatefulWidget {
  final bool isDark;
  const _PlacePickerSheet({required this.isDark});

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _searchController = TextEditingController();
  final _metaService = MetaService();
  final _focusNode = FocusNode();

  List<PlaceResult> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchController.text.trim();
    if (q == _lastQuery) return;
    _lastQuery = q;

    _debounce?.cancel();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    // 400ms debounce — avoids hammering the API on every keystroke
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _metaService.searchPlaces(query);
      if (mounted) setState(() => _results = results);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Search Airport or City',
                style: TextStyle(
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color:
                  isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded,
                        color: AppColors.primaryStart, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. New York, Los Angeles, JFK...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: AppSizes.fontSM,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.close_rounded,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                              size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Results
            Expanded(
              child: _buildResults(isDark, scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(bool isDark, ScrollController scrollController) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryStart),
      );
    }

    if (_searchController.text.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded,
                size: 56,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(height: 12),
            Text(
              'Type to search airports & cities',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: AppSizes.fontSM,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 56,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
            const SizedBox(height: 12),
            Text(
              'No results for "${_searchController.text}"',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontSize: AppSizes.fontSM,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        indent: 56,
      ),
      itemBuilder: (_, i) {
        final place = _results[i];
        final isCity = place.type == 'city';
        return ListTile(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCity
                  ? AppColors.primaryStart.withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCity ? Icons.location_city_rounded : Icons.flight_rounded,
              color: isCity ? AppColors.primaryStart : AppColors.success,
              size: 20,
            ),
          ),
          title: Text(
            place.name,
            style: TextStyle(
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          subtitle: Text(
            '${place.iataCode} · ${place.city} · ${place.countryCode}${isCity ? ' · All airports' : ''}',
            style: TextStyle(
              fontSize: AppSizes.fontXS,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.primaryStart.withValues(alpha: 0.2)),
            ),
            child: Text(
              place.iataCode,
              style: const TextStyle(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryStart,
                letterSpacing: 1,
              ),
            ),
          ),
          onTap: () => Navigator.pop(context, place),
        );
      },
    );
  }
}

// ── Shared sub-widgets (unchanged) ────────────────────────────────────────────

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
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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