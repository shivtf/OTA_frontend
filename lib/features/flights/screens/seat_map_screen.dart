// lib/features/flights/screens/seat_map_screen.dart
//
// Usage: Navigate with arguments:
//   Navigator.pushNamed(context, AppRoutes.seatMap, arguments: {
//     'offerId':        'off_xxx',
//     'flightInfo':     'DEL → DXB · Economy · Jun 15',
//     'passengerCount': 3,                          // total pax
//     'passengerNames': ['Adult 1','Child 1', ...], // optional display names
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

  // ── Multi-passenger seat assignment ───────────────────────────────────────
  // _assignments[passengerIndex] = _SelectedSeat | null
  late List<_SelectedSeat?> _assignments;
  // Reverse lookup: serviceId → passengerIndex
  final Map<String, int> _serviceToPassenger = {};

  // Which passenger the user is currently assigning a seat for
  int _activePassengerIndex = 0;

  // Which segment/deck we're viewing
  int _currentSegmentIndex = 0;

  String _offerId = '';
  String _flightInfo = '';
  int _passengerCount = 1;
  List<String> _passengerNames = [];

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
      _passengerNames = (args['passengerNames'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }

    // Ensure names list is exactly passengerCount long
    while (_passengerNames.length < _passengerCount) {
      _passengerNames.add('Passenger ${_passengerNames.length + 1}');
    }

    // Initialise assignment slots
    _assignments = List.filled(_passengerCount, null);

    if (_offerId.isNotEmpty && _isLoading) {
      _loadSeatMap();
    } else if (_offerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _seatMapResult = _buildMockSeatMap();
      });
      _animController.forward();
    }
  }

  Future<void> _loadSeatMap() async {
    try {
      final result = await _flightService.getSeatMap(_offerId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _seatMapResult = (!result.available || result.seatMaps.isEmpty)
            ? _buildMockSeatMap()
            : result;
      });
      _animController.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _seatMapResult = _buildMockSeatMap();
      });
      _animController.forward();
    }
  }

  // ── Mock data ──────────────────────────────────────────────────────────────

  SeatMapResult _buildMockSeatMap() =>
      SeatMapResult(available: true, seatMaps: [_mockSegment()]);

  Map<String, dynamic> _mockSegment() {
    final cabins = <Map<String, dynamic>>[];

    // Business — rows 1–4, 2-2 layout
    final bizRows = <Map<String, dynamic>>[];
    for (int row = 1; row <= 4; row++) {
      bizRows.add({
        'sections': [
          {
            'elements': [
              _mockSeat(row, 'A', row <= 2),
              _mockSeat(row, 'B', row == 1)
            ]
          },
          {
            'elements': [
              {'type': 'bassinet', 'designator': 'aisle'}
            ]
          },
          {
            'elements': [
              _mockSeat(row, 'C', row == 2),
              _mockSeat(row, 'D', false)
            ]
          },
        ],
      });
    }
    cabins.add({
      'cabin_class': 'business',
      'deck': 'main',
      'rows': bizRows,
      'wings': {'first_row_index': 99, 'last_row_index': 99},
    });

    // Economy — rows 10–35, 3-3 layout
    final ecoRows = <Map<String, dynamic>>[];
    for (int row = 10; row <= 35; row++) {
      ecoRows.add({
        'sections': [
          {
            'elements': [
              _mockSeat(row, 'A', row % 5 == 0 || row % 7 == 2),
              _mockSeat(row, 'B', row % 4 == 0),
              _mockSeat(row, 'C', row % 6 == 0 || row % 3 == 1),
            ],
          },
          {
            'elements': [
              {'type': 'bassinet', 'designator': 'aisle'}
            ]
          },
          {
            'elements': [
              _mockSeat(row, 'D', row % 5 == 1),
              _mockSeat(row, 'E', row % 4 == 2 || row % 7 == 0),
              _mockSeat(row, 'F', row % 6 == 3),
            ],
          },
        ],
      });
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
              }
            ],
      'disclosures': [],
    };
  }

  // ── Parsed cabins ──────────────────────────────────────────────────────────

  List<_CabinData> get _parsedCabins {
    if (_seatMapResult == null || _seatMapResult!.seatMaps.isEmpty) return [];
    final segment = _seatMapResult!.seatMaps[
        _currentSegmentIndex.clamp(0, _seatMapResult!.seatMaps.length - 1)];
    return (segment['cabins'] as List<dynamic>? ?? [])
        .map((c) => _CabinData.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ── Seat tap ───────────────────────────────────────────────────────────────

  void _toggleSeat(_SeatInfo seat) {
    if (!seat.isAvailable || seat.serviceId == null) return;
    HapticFeedback.lightImpact();

    setState(() {
      final sid = seat.serviceId!;

      // If tapping a seat already owned by any passenger → deassign it
      if (_serviceToPassenger.containsKey(sid)) {
        final ownerIdx = _serviceToPassenger.remove(sid)!;
        _assignments[ownerIdx] = null;
        // Set that passenger as the new active one so they can re-pick
        _activePassengerIndex = ownerIdx;
        return;
      }

      // If the active passenger already has a seat → free the old one first
      final current = _assignments[_activePassengerIndex];
      if (current != null) {
        _serviceToPassenger.remove(current.serviceId);
      }

      // Assign new seat to active passenger
      _assignments[_activePassengerIndex] = _SelectedSeat(
        serviceId: sid,
        designator: seat.designator,
        amount: seat.amount,
        currency: seat.currency,
      );
      _serviceToPassenger[sid] = _activePassengerIndex;

      // Auto-advance to the next unassigned passenger
      _advanceToNextUnassigned();
    });
  }

  /// Move _activePassengerIndex to the next passenger without a seat.
  /// Wraps around; if all are assigned, stays on current.
  void _advanceToNextUnassigned() {
    for (int offset = 1; offset <= _passengerCount; offset++) {
      final idx = (_activePassengerIndex + offset) % _passengerCount;
      if (_assignments[idx] == null) {
        _activePassengerIndex = idx;
        return;
      }
    }
    // All assigned — keep current so the user can still swap
  }

  int get _assignedCount => _assignments.where((s) => s != null).length;

  double get _totalExtra =>
      _assignments.fold(0.0, (s, seat) => s + (seat?.amount ?? 0.0));

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPri =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: _isLoading
          ? _buildLoading(bg)
          : FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _buildAppBar(context, isDark, textPri, surface),
                  _buildPassengerSelector(isDark, surface, textPri, textSec),
                  _buildLegend(isDark),
                  Expanded(
                      child: _buildSeatMap(isDark, surface, textPri, textSec)),
                  _buildBottomBar(context, isDark, surface, textPri, textSec),
                ],
              ),
            ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  Widget _buildLoading(Color bg) => Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
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

  Widget _buildAppBar(
      BuildContext context, bool isDark, Color textPri, Color surface) {
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
            onTap: () => Navigator.pop(context, <String>[]),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textPri, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Seats',
                  style: TextStyle(
                      color: textPri,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                if (_flightInfo.isNotEmpty)
                  Text(_flightInfo,
                      style: const TextStyle(
                          color: AppColors.lightTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Assigned / total badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryStart, AppColors.primaryEnd]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.event_seat_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$_assignedCount/$_passengerCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Passenger selector tabs ────────────────────────────────────────────────

  Widget _buildPassengerSelector(
      bool isDark, Color surface, Color textPri, Color textSec) {
    if (_passengerCount <= 1) return const SizedBox.shrink();

    return Container(
      color: isDark ? AppColors.darkCard : const Color(0xFFF4F2FA),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a passenger, then tap their seat:',
            style: TextStyle(
                color: textSec, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _passengerCount,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isActive = i == _activePassengerIndex;
                final isAssigned = _assignments[i] != null;
                final seat = _assignments[i];

                return GestureDetector(
                  onTap: () => setState(() => _activePassengerIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [
                              AppColors.primaryStart,
                              AppColors.primaryEnd
                            ])
                          : null,
                      color: isActive
                          ? null
                          : isDark
                              ? AppColors.darkSurface
                              : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.transparent
                            : isAssigned
                                ? _seatAssignedBorderColor
                                : AppColors.lightTextSecondary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAssigned
                              ? Icons.event_seat_rounded
                              : Icons.person_outline_rounded,
                          size: 14,
                          color: isActive
                              ? Colors.white
                              : isAssigned
                                  ? _seatAssignedBorderColor
                                  : textSec,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAssigned
                              ? '${_passengerNames[i]}: ${seat!.designator}'
                              : _passengerNames[i],
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : isAssigned
                                    ? _seatAssignedBorderColor
                                    : textSec,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        // Show ✕ to deassign if assigned but not active
                        if (isAssigned && !isActive) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() {
                              _serviceToPassenger
                                  .remove(_assignments[i]!.serviceId);
                              _assignments[i] = null;
                              _activePassengerIndex = i;
                            }),
                            child: Icon(Icons.close_rounded,
                                size: 12, color: _seatAssignedBorderColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Hint for active passenger
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primaryStart, AppColors.primaryEnd]),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Now picking for: ${_passengerNames[_activePassengerIndex]}',
                style: const TextStyle(
                  color: AppColors.primaryStart,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Legend ─────────────────────────────────────────────────────────────────

  Widget _buildLegend(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkCard : const Color(0xFFF4F2FA),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem(_seatAvailableColor, 'Available'),
          _legendItem(_seatActiveColor, 'Yours (active)'),
          _legendItem(_seatAssignedColor, 'Assigned'),
          _legendItem(_seatOccupiedColor, 'Taken'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.lightTextSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Seat grid ──────────────────────────────────────────────────────────────

  Widget _buildSeatMap(
      bool isDark, Color surface, Color textPri, Color textSec) {
    final cabins = _parsedCabins;
    if (cabins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded,
                size: 64, color: AppColors.lightTextSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Seat map not available\nfor this flight',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.lightTextSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: cabins
            .map((cabin) =>
                _buildCabin(cabin, cabins, isDark, surface, textPri, textSec))
            .toList(),
      ),
    );
  }

  Widget _buildCabin(
    _CabinData cabin,
    List<_CabinData> allCabins,
    bool isDark,
    Color surface,
    Color textPri,
    Color textSec,
  ) {
    return Column(
      children: [
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
                    fontSize: 13),
              ),
            ],
          ),
        ),
        if (allCabins.indexOf(cabin) == 0) _buildPlaneNose(isDark),
        ...cabin.rows.asMap().entries.map((e) {
          final rowIndex = e.key;
          final row = e.value;
          final isWing =
              rowIndex >= cabin.wingsFirst && rowIndex <= cabin.wingsLast;
          return _buildRow(row, rowIndex, isWing, isDark);
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlaneNose(bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: CustomPaint(
          size: const Size(200, 50),
          painter: _PlaneNosePainter(
            isDark: isDark,
            color: isDark ? AppColors.darkCard : const Color(0xFFE8E4F0),
          ),
        ),
      );

  Widget _buildRow(_RowData row, int rowIndex, bool isWingRow, bool isDark) {
    return Container(
      color: isWingRow
          ? AppColors.primaryStart.withOpacity(isDark ? 0.05 : 0.03)
          : Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: isWingRow
                ? Icon(Icons.airplanemode_active_rounded,
                    size: 14, color: AppColors.primaryStart.withOpacity(0.4))
                : null,
          ),
          ...row.sections.map((section) {
            if (section.isAisle) return const SizedBox(width: 20);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: section.seats
                  .map((seat) => _buildSeatCell(seat, isDark))
                  .toList(),
            );
          }),
          SizedBox(
            width: 24,
            child: isWingRow
                ? Icon(Icons.airplanemode_active_rounded,
                    size: 14, color: AppColors.primaryStart.withOpacity(0.4))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSeatCell(_SeatInfo seat, bool isDark) {
    final sid = seat.serviceId;
    final ownerIdx = sid != null ? _serviceToPassenger[sid] : null;
    final isOwnedByActive =
        ownerIdx != null && ownerIdx == _activePassengerIndex;
    final isOwnedByOther =
        ownerIdx != null && ownerIdx != _activePassengerIndex;

    Color seatColor;
    Color borderColor;
    Color iconColor = Colors.white;
    Widget? label;

    if (!seat.isAvailable) {
      seatColor = _seatOccupiedColor;
      borderColor = _seatOccupiedColor.withOpacity(0.6);
      iconColor = Colors.white.withOpacity(0.5);
    } else if (isOwnedByActive) {
      // Active passenger's current seat
      seatColor = _seatActiveColor;
      borderColor = _seatActiveColor;
      label = Text(
        '${ownerIdx! + 1}',
        style: const TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
      );
    } else if (isOwnedByOther) {
      // Another passenger's seat
      seatColor = _seatAssignedColor;
      borderColor = _seatAssignedBorderColor;
      label = Text(
        '${ownerIdx! + 1}',
        style: const TextStyle(
            color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
      );
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
          boxShadow: (isOwnedByActive || isOwnedByOther)
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null)
              label
            else
              Icon(
                !seat.isAvailable
                    ? Icons.close_rounded
                    : Icons.event_seat_rounded,
                color: !seat.isAvailable ? iconColor : iconColor,
                size: 14,
              ),
            if (seat.designator.isNotEmpty)
              Text(
                seat.designator,
                style: TextStyle(
                  color: (isOwnedByActive || isOwnedByOther)
                      ? Colors.white
                      : !seat.isAvailable
                          ? Colors.white.withOpacity(0.5)
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

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context,
    bool isDark,
    Color surface,
    Color textPri,
    Color textSec,
  ) {
    final hasAny = _assignedCount > 0;
    final allAssigned = _assignedCount == _passengerCount;

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
          // Per-passenger seat chips
          if (hasAny) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _passengerCount,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final assigned = _assignments[i];
                  final isActive = i == _activePassengerIndex;

                  return GestureDetector(
                    onTap: () => setState(() => _activePassengerIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: assigned != null
                            ? const LinearGradient(colors: [
                                AppColors.primaryStart,
                                AppColors.primaryEnd,
                              ])
                            : null,
                        color: assigned == null
                            ? isDark
                                ? AppColors.darkCard
                                : const Color(0xFFF0EEF8)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primaryStart
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            assigned != null
                                ? Icons.event_seat_rounded
                                : Icons.person_outline_rounded,
                            color: assigned != null ? Colors.white : textSec,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            assigned != null
                                ? '${_passengerNames[i]}: ${assigned.designator}'
                                : _passengerNames[i],
                            style: TextStyle(
                              color: assigned != null ? Colors.white : textSec,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (assigned != null) ...[
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => setState(() {
                                _serviceToPassenger.remove(assigned.serviceId);
                                _assignments[i] = null;
                                _activePassengerIndex = i;
                              }),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white70, size: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Progress hint when not all assigned
          if (!allAssigned && _passengerCount > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.primaryStart),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      allAssigned
                          ? 'All seats selected!'
                          : 'Tap a seat for ${_passengerNames[_activePassengerIndex]}',
                      style: const TextStyle(
                        color: AppColors.primaryStart,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAny ? 'Seat upgrade' : 'No seats selected',
                      style: TextStyle(color: textSec, fontSize: 12),
                    ),
                    Text(
                      hasAny
                          ? '+\$${_totalExtra.toStringAsFixed(2)}'
                          : 'Free random seats',
                      style: TextStyle(
                          color: textPri,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (hasAny)
                    GestureDetector(
                      onTap: () => Navigator.pop(context, <String>[]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.lightInputBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('Skip',
                            style: TextStyle(
                                color: textSec, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      // Return only the assigned serviceIds (non-null)
                      final serviceIds = _assignments
                          .where((s) => s != null)
                          .map((s) => s!.serviceId)
                          .toList();
                      Navigator.pop(context, serviceIds);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
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
                        hasAny ? 'Confirm Seats' : 'Skip',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
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

  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color _seatAvailableColor = Color(0xFF4CAF82);
  static const Color _seatActiveColor = AppColors.primaryStart;
  static const Color _seatAssignedColor = Color(0xFF7B61FF);
  static const Color _seatAssignedBorderColor = Color(0xFF5E48CC);
  static const Color _seatOccupiedColor = Color(0xFFB0A8C8);
  static const Color _seatExitColor = Color(0xFFFF9800);
}

// ── Data models ───────────────────────────────────────────────────────────────

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
    if (elements.any((e) {
      final el = e as Map<String, dynamic>;
      return el['designator'] == 'aisle' || el['type'] == 'bassinet';
    })) {
      final first = elements.first as Map<String, dynamic>;
      if (first['designator'] == 'aisle' ||
          (elements.length == 1 && first['type'] != 'seat')) {
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

    if (isAvailable) {
      final svc = services.first as Map<String, dynamic>;
      serviceId = svc['id'] as String?;
      amount = double.tryParse(svc['total_amount']?.toString() ?? '0') ?? 0.0;
      currency = svc['total_currency'] as String? ?? 'USD';
    }

    final disclosures = j['disclosures'] as List<dynamic>? ?? [];
    final isExit =
        disclosures.any((d) => (d as String).toLowerCase().contains('exit'));

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

// ── Plane nose painter ─────────────────────────────────────────────────────────

class _PlaneNosePainter extends CustomPainter {
  final bool isDark;
  final Color color;
  const _PlaneNosePainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width * 0.8, size.height)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.5, size.width * 0.3,
            size.height * 0.35),
        const Radius.circular(4),
      ),
      Paint()
        ..color = AppColors.primaryStart.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
