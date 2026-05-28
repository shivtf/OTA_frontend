// lib/features/flights/screens/seat_map_screen.dart
//
// Usage: Navigate with arguments:
//   Navigator.pushNamed(context, AppRoutes.seatMap, arguments: {
//     'offerId': 'off_xxx',
//     'flightInfo': 'DEL → DXB · Economy · Jun 15',
//   });
// Returns: List<String> of selected service IDs via Navigator.pop()

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/flight_service.dart';

class SeatMapScreen extends StatefulWidget {
  const SeatMapScreen({super.key});

  @override
  State<SeatMapScreen> createState() => _SeatMapScreenState();
}

class _SeatMapScreenState extends State<SeatMapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  final FlightService _flightService = FlightService();

  bool _isLoading = true;
  String? _error;
  SeatMapResult? _seatMapResult;

  // Selected seats: serviceId → deck/cabin/row/column info
  final Map<String, _SelectedSeat> _selectedSeats = {};

  // Which segment/deck we're viewing
  int _currentSegmentIndex = 0;
  int _currentDeckIndex = 0;

  String _offerId = '';
  String _flightInfo = '';
  int _passengerCount = 1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _offerId = args['offerId'] as String? ?? '';
      _flightInfo = args['flightInfo'] as String? ?? '';
      _passengerCount = args['passengerCount'] as int? ?? 1;
    }
    if (_offerId.isNotEmpty && _isLoading) {
      _loadSeatMap();
    } else if (_offerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = null;
        _seatMapResult = _buildMockSeatMap();
      });
      _animController.forward();
    }
  }

  Future<void> _loadSeatMap() async {
    try {
      final result = await _flightService.getSeatMap(_offerId);
      if (!mounted) return;
      if (!result.available || result.seatMaps.isEmpty) {
        setState(() {
          _isLoading = false;
          _seatMapResult = _buildMockSeatMap();
        });
      } else {
        setState(() {
          _isLoading = false;
          _seatMapResult = result;
        });
      }
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      // Fall back to mock on error
      setState(() {
        _isLoading = false;
        _seatMapResult = _buildMockSeatMap();
      });
      _animController.forward();
    }
  }

  /// Builds a realistic mock seat map for when the API returns empty/unavailable
  SeatMapResult _buildMockSeatMap() {
    return SeatMapResult(available: true, seatMaps: [_mockSegment()]);
  }

  Map<String, dynamic> _mockSegment() {
    final cabins = <Map<String, dynamic>>[];

    // Business class — rows 1–4, 2-2 layout
    final bizRows = <Map<String, dynamic>>[];
    for (int row = 1; row <= 4; row++) {
      final sections = <Map<String, dynamic>>[];
      // Left pair
      sections.add({
        'elements': [
          _mockSeat(row, 'A', row <= 2),
          _mockSeat(row, 'B', row == 1),
        ],
      });
      // Aisle
      sections.add({
        'elements': [
          {'type': 'bassinet', 'designator': 'aisle'},
        ],
      });
      // Right pair
      sections.add({
        'elements': [_mockSeat(row, 'C', row == 2), _mockSeat(row, 'D', false)],
      });
      bizRows.add({'sections': sections});
    }
    cabins.add({
      'cabin_class': 'business',
      'deck': 'main',
      'rows': bizRows,
      'wings': {'first_row_index': 99, 'last_row_index': 99},
    });

    // Economy class — rows 10–35, 3-3 layout
    final ecoRows = <Map<String, dynamic>>[];
    for (int row = 10; row <= 35; row++) {
      final sections = <Map<String, dynamic>>[];
      // Left triple
      sections.add({
        'elements': [
          _mockSeat(row, 'A', row % 5 == 0 || row % 7 == 2),
          _mockSeat(row, 'B', row % 4 == 0),
          _mockSeat(row, 'C', row % 6 == 0 || row % 3 == 1),
        ],
      });
      // Aisle
      sections.add({
        'elements': [
          {'type': 'bassinet', 'designator': 'aisle'},
        ],
      });
      // Right triple
      sections.add({
        'elements': [
          _mockSeat(row, 'D', row % 5 == 1),
          _mockSeat(row, 'E', row % 4 == 2 || row % 7 == 0),
          _mockSeat(row, 'F', row % 6 == 3),
        ],
      });
      ecoRows.add({'sections': sections});
    }
    cabins.add({
      'cabin_class': 'economy',
      'deck': 'main',
      'rows': ecoRows,
      'wings': {'first_row_index': 8, 'last_row_index': 18},
    });

    return {'cabins': cabins, 'slice_id': 'slc_mock'};
  }

  Map<String, dynamic> _mockSeat(int row, String col, bool isOccupied) {
    final id = 'svc_${row}_$col';
    return {
      'type': 'seat',
      'designator': '$row$col',
      'available_services': isOccupied
          ? []
          : [
              {
                'id': id,
                'total_amount':
                    '${(15 + (row < 10 ? 80 : 0)).toStringAsFixed(2)}',
                'total_currency': 'USD',
              },
            ],
      'disclosures': [],
    };
  }

  List<_CabinData> get _parsedCabins {
    if (_seatMapResult == null || _seatMapResult!.seatMaps.isEmpty) return [];
    final segment =
        _seatMapResult!.seatMaps[_currentSegmentIndex.clamp(
          0,
          _seatMapResult!.seatMaps.length - 1,
        )];
    final cabins = (segment['cabins'] as List<dynamic>? ?? []);
    return cabins
        .map((c) => _CabinData.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  void _toggleSeat(_SeatInfo seat) {
    if (!seat.isAvailable) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedSeats.containsKey(seat.serviceId)) {
        _selectedSeats.remove(seat.serviceId);
      } else {
        if (_selectedSeats.length >= _passengerCount) {
          // Remove oldest selection
          _selectedSeats.remove(_selectedSeats.keys.first);
        }
        _selectedSeats[seat.serviceId!] = _SelectedSeat(
          serviceId: seat.serviceId!,
          designator: seat.designator,
          amount: seat.amount,
          currency: seat.currency,
        );
      }
    });
  }

  double get _totalExtra =>
      _selectedSeats.values.fold(0.0, (s, seat) => s + seat.amount);

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSec = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? _buildLoading(bg)
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildAppBar(context, isDark, textPrimary, surface),
                  _buildLegend(isDark, surface),
                  Expanded(
                    child: _buildSeatMap(isDark, surface, textPrimary, textSec),
                  ),
                  _buildBottomBar(
                    context,
                    isDark,
                    surface,
                    textPrimary,
                    textSec,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoading(Color bg) {
    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
            ),
            SizedBox(height: 20),
            Text(
              'Loading seat map...',
              style: TextStyle(
                color: AppColors.primaryStart,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color surface,
  ) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context, []),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Your Seat',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_flightInfo.isNotEmpty)
                  Text(
                    _flightInfo,
                    style: const TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // Passenger count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_selectedSeats.length}/$_passengerCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark, Color surface) {
    return Container(
      color: isDark ? AppColors.darkCard : const Color(0xFFF4F2FA),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(_seatAvailableColor, 'Available'),
          _legendItem(_seatSelectedColor, 'Selected'),
          _legendItem(_seatOccupiedColor, 'Occupied'),
          _legendItem(_seatExitColor, 'Exit Row'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.lightTextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatMap(
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSec,
  ) {
    final cabins = _parsedCabins;
    if (cabins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_seat_rounded,
              size: 64,
              color: AppColors.lightTextSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Seat map not available\nfor this flight',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: cabins.map((cabin) {
          return _buildCabin(cabin, isDark, surface, textPrimary, textSec);
        }).toList(),
      ),
    );
  }

  Widget _buildCabin(
    _CabinData cabin,
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSec,
  ) {
    return Column(
      children: [
        // Cabin header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cabin.cabinClass == 'business'
                  ? [const Color(0xFFFFD166), const Color(0xFFFFA500)]
                  : [AppColors.primaryStart, AppColors.primaryEnd],
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                cabin.cabinClass == 'business'
                    ? Icons.star_rounded
                    : Icons.airline_seat_recline_normal_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                cabin.cabinClass == 'business'
                    ? 'Business Class'
                    : 'Economy Class',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        // Nose of plane at top of first cabin
        if (cabins.indexOf(cabin) == 0) _buildPlaneNose(isDark),

        // Rows
        ...cabin.rows.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          final isWingRow =
              rowIndex >= cabin.wingsFirst && rowIndex <= cabin.wingsLast;
          return _buildRow(
            row,
            rowIndex,
            isWingRow,
            isDark,
            surface,
            textPrimary,
          );
        }),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlaneNose(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CustomPaint(
        size: const Size(200, 50),
        painter: _PlaneNosePainter(
          isDark: isDark,
          color: isDark ? AppColors.darkCard : const Color(0xFFE8E4F0),
        ),
      ),
    );
  }

  Widget _buildRow(
    _RowData row,
    int rowIndex,
    bool isWingRow,
    bool isDark,
    Color surface,
    Color textPrimary,
  ) {
    return Container(
      color: isWingRow
          ? (isDark
                ? AppColors.primaryStart.withOpacity(0.05)
                : AppColors.primaryStart.withOpacity(0.03))
          : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wing indicator (left)
          SizedBox(
            width: 24,
            child: isWingRow
                ? Icon(
                    Icons.airplanemode_active_rounded,
                    size: 14,
                    color: AppColors.primaryStart.withOpacity(0.4),
                  )
                : null,
          ),

          // Sections of this row
          ...row.sections.map((section) {
            if (section.isAisle) {
              return const SizedBox(width: 20);
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: section.seats.map((seat) {
                return _buildSeatCell(seat, isDark);
              }).toList(),
            );
          }),

          // Wing indicator (right)
          SizedBox(
            width: 24,
            child: isWingRow
                ? Icon(
                    Icons.airplanemode_active_rounded,
                    size: 14,
                    color: AppColors.primaryStart.withOpacity(0.4),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCell(_SeatInfo seat, bool isDark) {
    final isSelected =
        seat.serviceId != null && _selectedSeats.containsKey(seat.serviceId);
    Color seatColor;
    Color borderColor;
    Color iconColor;

    if (!seat.isAvailable) {
      seatColor = _seatOccupiedColor;
      borderColor = _seatOccupiedColor.withOpacity(0.6);
      iconColor = Colors.white.withOpacity(0.5);
    } else if (isSelected) {
      seatColor = _seatSelectedColor;
      borderColor = _seatSelectedColor;
      iconColor = Colors.white;
    } else if (seat.isExitRow) {
      seatColor = _seatExitColor.withOpacity(0.15);
      borderColor = _seatExitColor;
      iconColor = _seatExitColor;
    } else {
      seatColor = isDark
          ? _seatAvailableColor.withOpacity(0.15)
          : _seatAvailableColor.withOpacity(0.1);
      borderColor = _seatAvailableColor;
      iconColor = _seatAvailableColor;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _seatSelectedColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              !seat.isAvailable
                  ? Icons.close_rounded
                  : isSelected
                  ? Icons.check_rounded
                  : Icons.event_seat_rounded,
              color: isSelected || !seat.isAvailable ? Colors.white : iconColor,
              size: 14,
            ),
            if (seat.designator.isNotEmpty)
              Text(
                seat.designator,
                style: TextStyle(
                  color: isSelected || !seat.isAvailable
                      ? Colors.white
                      : iconColor,
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isDark,
    Color surface,
    Color textPrimary,
    Color textSec,
  ) {
    final hasSelection = _selectedSeats.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected seats chips
          if (hasSelection) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedSeats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final seat = _selectedSeats.values.elementAt(i);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryStart, AppColors.primaryEnd],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_seat_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          seat.designator,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => setState(
                            () => _selectedSeats.remove(seat.serviceId),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              // Price summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelection ? 'Seat upgrade' : 'No seat selected',
                      style: TextStyle(color: textSec, fontSize: 12),
                    ),
                    Text(
                      hasSelection
                          ? '+\$${_totalExtra.toStringAsFixed(2)}'
                          : 'Free random seat',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Confirm / Skip buttons
              Row(
                children: [
                  if (hasSelection)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, []),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightInputBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: textSec,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(
                        context,
                        _selectedSeats.values.map((s) => s.serviceId).toList(),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryStart,
                            AppColors.primaryEnd,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        hasSelection ? 'Confirm Seats' : 'Skip',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const Color _seatAvailableColor = Color(0xFF4CAF82);
  static const Color _seatSelectedColor = AppColors.primaryStart;
  static const Color _seatOccupiedColor = Color(0xFFB0A8C8);
  static const Color _seatExitColor = Color(0xFFFF9800);

  List<_CabinData> get cabins => _parsedCabins;
}

// ── Data models for parsed seat map ──────────────────────────────────────────

class _CabinData {
  final String cabinClass;
  final List<_RowData> rows;
  final int wingsFirst;
  final int wingsLast;

  _CabinData({
    required this.cabinClass,
    required this.rows,
    required this.wingsFirst,
    required this.wingsLast,
  });

  factory _CabinData.fromJson(Map<String, dynamic> j) {
    final rawRows = j['rows'] as List<dynamic>? ?? [];
    final wings = j['wings'] as Map<String, dynamic>?;
    return _CabinData(
      cabinClass: j['cabin_class'] as String? ?? 'economy',
      rows: rawRows
          .map((r) => _RowData.fromJson(r as Map<String, dynamic>))
          .toList(),
      wingsFirst: wings?['first_row_index'] as int? ?? 99,
      wingsLast: wings?['last_row_index'] as int? ?? 99,
    );
  }
}

class _RowData {
  final List<_SectionData> sections;
  _RowData({required this.sections});

  factory _RowData.fromJson(Map<String, dynamic> j) {
    final rawSections = j['sections'] as List<dynamic>? ?? [];
    return _RowData(
      sections: rawSections
          .map((s) => _SectionData.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _SectionData {
  final bool isAisle;
  final List<_SeatInfo> seats;

  _SectionData({required this.isAisle, required this.seats});

  factory _SectionData.fromJson(Map<String, dynamic> j) {
    final elements = j['elements'] as List<dynamic>? ?? [];
    if (elements.any(
      (e) =>
          (e as Map<String, dynamic>)['designator'] == 'aisle' ||
          (e as Map<String, dynamic>)['type'] == 'bassinet',
    )) {
      // Check if this is an aisle gap
      final first = elements.first as Map<String, dynamic>;
      if (first['designator'] == 'aisle' ||
          elements.length == 1 && first['type'] != 'seat') {
        return _SectionData(isAisle: true, seats: []);
      }
    }

    final seats = elements
        .where((e) {
          final el = e as Map<String, dynamic>;
          return el['type'] == 'seat' || el['designator'] != 'aisle';
        })
        .map((e) => _SeatInfo.fromJson(e as Map<String, dynamic>))
        .where((s) => s.designator.isNotEmpty)
        .toList();

    return _SectionData(isAisle: seats.isEmpty, seats: seats);
  }
}

class _SeatInfo {
  final String designator;
  final bool isAvailable;
  final bool isExitRow;
  final String? serviceId;
  final double amount;
  final String currency;

  _SeatInfo({
    required this.designator,
    required this.isAvailable,
    required this.isExitRow,
    this.serviceId,
    required this.amount,
    required this.currency,
  });

  factory _SeatInfo.fromJson(Map<String, dynamic> j) {
    final services = j['available_services'] as List<dynamic>? ?? [];
    final isAvailable = services.isNotEmpty;
    String? serviceId;
    double amount = 0.0;
    String currency = 'USD';

    if (isAvailable && services.isNotEmpty) {
      final svc = services.first as Map<String, dynamic>;
      serviceId = svc['id'] as String?;
      amount = double.tryParse(svc['total_amount']?.toString() ?? '0') ?? 0.0;
      currency = svc['total_currency'] as String? ?? 'USD';
    }

    final disclosures = j['disclosures'] as List<dynamic>? ?? [];
    final isExit = disclosures.any(
      (d) => (d as String).toLowerCase().contains('exit'),
    );

    return _SeatInfo(
      designator: j['designator'] as String? ?? '',
      isAvailable: isAvailable,
      isExitRow: isExit,
      serviceId: serviceId,
      amount: amount,
      currency: currency,
    );
  }
}

class _SelectedSeat {
  final String serviceId;
  final String designator;
  final double amount;
  final String currency;

  _SelectedSeat({
    required this.serviceId,
    required this.designator,
    required this.amount,
    required this.currency,
  });
}

// ── Plane nose painter ─────────────────────────────────────────────────────

class _PlaneNosePainter extends CustomPainter {
  final bool isDark;
  final Color color;
  const _PlaneNosePainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width * 0.8, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Window strip
    final windowPaint = Paint()
      ..color = AppColors.primaryStart.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.35,
          size.height * 0.5,
          size.width * 0.3,
          size.height * 0.35,
        ),
        const Radius.circular(4),
      ),
      windowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
