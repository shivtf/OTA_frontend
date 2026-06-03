// lib/features/profiles/screens/eticket_screen.dart
//
// Native in-app e-ticket viewer.
// Fetches GET /flights/bookings/:bookingId/eticket/data and renders
// a boarding-pass–style ticket without requiring the user to check email.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';

class ETicketScreen extends StatefulWidget {
  final String bookingId;
  final String bookingRef;

  const ETicketScreen({
    super.key,
    required this.bookingId,
    required this.bookingRef,
  });

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _ticket;
  bool _disposed = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    _shimmerController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _load() async {
    _safeSetState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get(
        '/flights/bookings/${widget.bookingId}/eticket/data',
        auth: true,
      );
      _safeSetState(() {
        _ticket = res['data'] as Map<String, dynamic>? ?? res;
        _loading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          _isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? _buildSkeleton()
                : _error != null
                    ? _buildError()
                    : _buildTicketView(),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: _isDark
            ? const LinearGradient(
                colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'E-Ticket',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontXL,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.bookingRef,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppSizes.fontXS,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _load,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Skeleton loader ──────────────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        final shimmer = LinearGradient(
          colors: [
            (_isDark ? AppColors.darkCard : AppColors.lightCard),
            (_isDark
                ? AppColors.darkCard.withValues(alpha: 0.4)
                : AppColors.lightBorder),
            (_isDark ? AppColors.darkCard : AppColors.lightCard),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment(-1.5 + _shimmerController.value * 3, 0),
          end: Alignment(1.5 + _shimmerController.value * 3, 0),
        );

        Widget skeletonBox(double w, double h, {double radius = 8}) =>
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                gradient: shimmer,
                borderRadius: BorderRadius.circular(radius),
              ),
            );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            // Boarding pass skeleton
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      skeletonBox(100, 48, radius: 10),
                      skeletonBox(40, 40, radius: 20),
                      skeletonBox(100, 48, radius: 10),
                    ],
                  ),
                  const SizedBox(height: 20),
                  skeletonBox(double.infinity, 1),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      skeletonBox(120, 14),
                      skeletonBox(80, 14),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      skeletonBox(100, 14),
                      skeletonBox(60, 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            skeletonBox(double.infinity, 80, radius: AppSizes.radiusMedium),
          ],
        );
      },
    );
  }

  // ── Error ────────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.confirmation_number_outlined,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load ticket',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w700,
                color: _isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: _isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main ticket view ─────────────────────────────────────────────────────────

  Widget _buildTicketView() {
    final t = _ticket!;
    final journeys = (t['journeys'] as List<dynamic>? ?? []);
    final passengers = (t['passengers'] as List<dynamic>? ?? []);
    final payment = t['payment'] as Map<String, dynamic>?;
    final booker = t['booker'] as Map<String, dynamic>?;
    final pnr = t['pnr'] as String?;
    final allRefs = t['allReferences'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      children: [
        // ── Per-journey boarding pass cards ──────────────────────────────────
        ...journeys.asMap().entries.map((e) {
          return _buildJourneyCard(e.value as Map<String, dynamic>, e.key,
              journeys.length, passengers);
        }),

        // ── Passengers section ───────────────────────────────────────────────
        if (passengers.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Passengers'),
          const SizedBox(height: 12),
          ...passengers
              .map((p) => _buildPassengerCard(p as Map<String, dynamic>)),
        ],

        // ── Booking references ───────────────────────────────────────────────
        if (pnr != null || allRefs.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle('Booking Reference'),
          const SizedBox(height: 12),
          _buildPnrCard(pnr, allRefs),
        ],

        // ── Payment summary ──────────────────────────────────────────────────
        if (payment != null) ...[
          const SizedBox(height: 20),
          _sectionTitle('Payment'),
          const SizedBox(height: 12),
          _buildPaymentCard(payment),
        ],

        // ── Booker info ──────────────────────────────────────────────────────
        if (booker != null) ...[
          const SizedBox(height: 20),
          _sectionTitle('Booked By'),
          const SizedBox(height: 12),
          _buildBookerCard(booker),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  // ── Journey / boarding-pass card ─────────────────────────────────────────────

  Widget _buildJourneyCard(
    Map<String, dynamic> journey,
    int index,
    int total,
    List<dynamic> passengers,
  ) {
    final segments = (journey['segments'] as List<dynamic>? ?? []);
    final label = journey['journeyLabel'] as String? ??
        (total == 1 ? 'Flight' : 'Journey ${index + 1}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 1) ...[
          if (index > 0) const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        ...segments.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                _buildBoardingPassCard(s as Map<String, dynamic>, passengers),
          ),
        ),
      ],
    );
  }

  // ── Boarding-pass style card for one flight segment ──────────────────────────

  Widget _buildBoardingPassCard(
    Map<String, dynamic> seg,
    List<dynamic> passengers,
  ) {
    final origin = seg['origin'] as Map<String, dynamic>? ?? {};
    final dest = seg['destination'] as Map<String, dynamic>? ?? {};
    final departure = seg['departure'] as Map<String, dynamic>? ?? {};
    final arrival = seg['arrival'] as Map<String, dynamic>? ?? {};
    final airline = seg['airline'] as Map<String, dynamic>? ?? {};
    final passengerInfo = seg['passengerInfo'] as List<dynamic>? ?? [];
    final duration = seg['duration'] as String?;
    final flightNum = seg['flightNumber'] as String? ?? '--';
    final aircraft = seg['aircraft'] as String?;
    final stops = seg['stops'] as List<dynamic>? ?? [];

    final originCode = origin['iataCode'] as String? ?? '--';
    final destCode = dest['iataCode'] as String? ?? '--';
    final originCity = origin['cityName'] as String? ?? originCode;
    final destCity = dest['cityName'] as String? ?? destCode;
    final originTerminal = origin['terminal'] as String?;
    final destTerminal = dest['terminal'] as String?;
    final depTime = departure['time'] as String? ?? '--:--';
    final arrTime = arrival['time'] as String? ?? '--:--';
    final depDate = departure['date'] as String? ?? '';
    final arrDate = arrival['date'] as String? ?? '';
    final airlineName = airline['name'] as String? ?? 'Airline';
    final airlineCode = airline['iataCode'] as String? ?? '';
    final logoUrl = airline['logoUrl'] as String?;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
      child: Stack(
        children: [
          // Card body
          Container(
            decoration: BoxDecoration(
              color: _isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              border: Border.all(
                color: _isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: _isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              children: [
                // ── Top: gradient header with airline + flight number ─────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    gradient: _isDark
                        ? const LinearGradient(
                            colors: [Color(0xFF2A1F5C), Color(0xFF1E1840)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLarge),
                      topRight: Radius.circular(AppSizes.radiusLarge),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Airline logo / icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _airlineIcon(),
                                ),
                              )
                            : _airlineIcon(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              airlineName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              [
                                flightNum,
                                if (aircraft != null) aircraft,
                              ].join(' · '),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: AppSizes.fontXS,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Airline code badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          airlineCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.fontXS,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flight route display ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                  child: Row(
                    children: [
                      // Origin
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              originCode,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: _isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              originCity,
                              style: TextStyle(
                                fontSize: AppSizes.fontXS,
                                color: _isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (originTerminal != null)
                              Text(
                                'Terminal $originTerminal',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryStart,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Centre: duration + route line
                      Expanded(
                        child: Column(
                          children: [
                            if (duration != null)
                              Text(
                                duration,
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  fontWeight: FontWeight.w600,
                                  color: _isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            const SizedBox(height: 6),
                            _buildRouteLine(stops.length),
                            const SizedBox(height: 6),
                            if (stops.isEmpty)
                              Text(
                                'Direct',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Text(
                                '${stops.length} stop${stops.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Destination
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              destCode,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: _isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destCity,
                              style: TextStyle(
                                fontSize: AppSizes.fontXS,
                                color: _isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                            if (destTerminal != null)
                              Text(
                                'Terminal $destTerminal',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXS,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryStart,
                                ),
                                textAlign: TextAlign.right,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Departure / arrival time row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              depTime,
                              style: TextStyle(
                                fontSize: AppSizes.fontLG,
                                fontWeight: FontWeight.w800,
                                color: _isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              depDate,
                              style: TextStyle(
                                fontSize: AppSizes.fontXS,
                                color: _isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arrTime,
                              style: TextStyle(
                                fontSize: AppSizes.fontLG,
                                fontWeight: FontWeight.w800,
                                color: _isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              arrDate,
                              style: TextStyle(
                                fontSize: AppSizes.fontXS,
                                color: _isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tear line ─────────────────────────────────────────────────
                _buildTearLine(),

                // ── Seat / class info per passenger ───────────────────────────
                if (passengerInfo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      children: passengerInfo.asMap().entries.map((e) {
                        final idx = e.key;
                        final pi = e.value as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.only(top: idx == 0 ? 0 : 10),
                          child: _buildSeatRow(pi),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tear/perforation line between the main ticket body and seat stub
  Widget _buildTearLine() {
    return Row(
      children: [
        _notch(isLeft: true),
        Expanded(
          child: LayoutBuilder(
            builder: (_, constraints) {
              final count = (constraints.maxWidth / 12).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  count,
                  (_) => Container(
                    width: 6,
                    height: 1.5,
                    color:
                        _isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              );
            },
          ),
        ),
        _notch(isLeft: false),
      ],
    );
  }

  Widget _notch({required bool isLeft}) {
    return SizedBox(
      width: 16,
      height: 32,
      child: CustomPaint(
        painter: _NotchPainter(
          isDark: _isDark,
          isLeft: isLeft,
        ),
      ),
    );
  }

  Widget _buildRouteLine(int stops) {
    return SizedBox(
      height: 20,
      child: CustomPaint(
        painter: _RouteLinePainter(
          color: _isDark ? AppColors.darkBorder : AppColors.lightBorder,
          accentColor: AppColors.primaryStart,
          stops: stops,
        ),
        size: const Size(double.infinity, 20),
      ),
    );
  }

  Widget _airlineIcon() => const Icon(
        Icons.flight_rounded,
        color: Colors.white70,
        size: 22,
      );

  Widget _buildSeatRow(Map<String, dynamic> pi) {
    final name = pi['passengerName'] as String? ?? 'Passenger';
    final seat = pi['seat'] as String?;
    final cabin =
        pi['cabinClassName'] as String? ?? pi['cabinClass'] as String?;
    final baggages = pi['baggages'] as List<dynamic>? ?? [];

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline_rounded,
              color: AppColors.primaryStart, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w700,
                  color: _isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (cabin != null)
                Text(
                  cabin,
                  style: TextStyle(
                    fontSize: AppSizes.fontXS,
                    color: _isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
            ],
          ),
        ),
        // Baggage icons
        if (baggages.isNotEmpty)
          Row(
            children: baggages.map((b) {
              final type = (b as Map<String, dynamic>)['type'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Tooltip(
                  message: type,
                  child: Icon(
                    type.toLowerCase().contains('carry')
                        ? Icons.backpack_outlined
                        : Icons.luggage_outlined,
                    size: 16,
                    color: _isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(width: 8),
        // Seat number bubble
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            seat ?? 'N/A',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Passengers section ───────────────────────────────────────────────────────

  Widget _buildPassengerCard(Map<String, dynamic> p) {
    final first = p['firstName'] as String? ?? '';
    final last = p['lastName'] as String? ?? '';
    final type = (p['type'] as String? ?? 'adult').toLowerCase();
    final passport = p['passportNumber'] as String?;
    final nationality = p['nationality'] as String?;
    final dob = p['dateOfBirth'] as String?;
    final tickets = p['ticketNumbers'] as List<dynamic>? ?? [];

    String typeLabel;
    IconData typeIcon;
    switch (type) {
      case 'child':
        typeLabel = 'Child';
        typeIcon = Icons.child_care_rounded;
        break;
      case 'infant_without_seat':
        typeLabel = 'Infant';
        typeIcon = Icons.child_friendly_rounded;
        break;
      default:
        typeLabel = 'Adult';
        typeIcon = Icons.person_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$first $last',
                      style: TextStyle(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                        color: _isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: AppSizes.fontXS,
                        color: _isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (passport != null ||
              nationality != null ||
              dob != null ||
              tickets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: _isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 12),
          ],
          if (dob != null)
            _infoRow(Icons.cake_outlined, 'Date of Birth', _formatDate(dob)),
          if (nationality != null)
            _infoRow(Icons.public_rounded, 'Nationality', nationality),
          if (passport != null)
            _infoRow(Icons.credit_card_rounded, 'Passport', passport),
          if (tickets.isNotEmpty) ...[
            ...tickets.map((t) => _infoRow(
                  Icons.confirmation_number_outlined,
                  'E-Ticket No.',
                  t.toString(),
                  copyable: true,
                )),
          ],
        ],
      ),
    );
  }

  // ── PNR card ─────────────────────────────────────────────────────────────────

  Widget _buildPnrCard(String? pnr, List<dynamic> allRefs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (pnr != null)
            _infoRow(Icons.tag_rounded, 'PNR / Booking Code', pnr,
                copyable: true, large: true),
          ...allRefs.asMap().entries.map((e) {
            final ref = e.value as Map<String, dynamic>;
            final reference = ref['reference'] as String? ?? '';
            final airline = ref['airlineName'] as String?;
            final code = ref['airlineCode'] as String?;
            final label = [
              if (airline != null) airline,
              if (code != null) '($code)',
            ].join(' ');
            return Padding(
              padding: EdgeInsets.only(top: e.key == 0 && pnr != null ? 10 : 0),
              child: _infoRow(
                Icons.airline_stops_outlined,
                label.isNotEmpty ? label : 'Reference',
                reference,
                copyable: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Payment card ─────────────────────────────────────────────────────────────

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final amount = payment['totalAmount'] as String?;
    final currency = payment['currency'] as String? ?? '';
    final status = payment['status'] as String? ?? '';
    final paidAt = payment['paidAt'] as String?;
    final provider = payment['provider'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: _isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                amount != null ? '$currency $amount' : '--',
                style: TextStyle(
                  fontSize: AppSizes.fontXL,
                  fontWeight: FontWeight.w900,
                  color: _isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          if (paidAt != null || status.isNotEmpty || provider != null) ...[
            const SizedBox(height: 10),
            Divider(
                height: 1,
                color: _isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 10),
          ],
          if (status.isNotEmpty) _payRow('Status', status),
          if (paidAt != null) _payRow('Paid On', _formatDate(paidAt)),
          if (provider != null) _payRow('Provider', provider),
        ],
      ),
    );
  }

  // ── Booker card ──────────────────────────────────────────────────────────────

  Widget _buildBookerCard(Map<String, dynamic> booker) {
    final first = booker['firstName'] as String? ?? '';
    final last = booker['lastName'] as String? ?? '';
    final email = booker['email'] as String?;
    final phone = booker['phone'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(Icons.person_outline_rounded, 'Name', '$first $last'),
          if (email != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _infoRow(Icons.email_outlined, 'Email', email),
            ),
          if (phone != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _infoRow(Icons.phone_outlined, 'Phone', phone),
            ),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w800,
        color: _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool copyable = false,
    bool large = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primaryStart,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontXS,
                  color: _isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: large ? AppSizes.fontLG : AppSizes.fontSM,
                  fontWeight: FontWeight.w700,
                  color: _isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  letterSpacing: large ? 1.5 : 0,
                ),
              ),
            ],
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: $value'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.primaryStart),
            ),
          ),
      ],
    );
  }

  Widget _payRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            color: _isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: _isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: _isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: _isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
      );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = [
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
        'Dec',
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Custom painters ──────────────────────────────────────────────────────────

/// Paints the semicircular notch on the left or right edge of the tear line.
class _NotchPainter extends CustomPainter {
  final bool isDark;
  final bool isLeft;
  const _NotchPainter({required this.isDark, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final paint = Paint()..color = bg;
    final cx = isLeft ? size.width : 0.0;
    final cy = size.height / 2;
    canvas.drawCircle(Offset(cx, cy), size.height / 2, paint);
  }

  @override
  bool shouldRepaint(_NotchPainter old) =>
      old.isDark != isDark || old.isLeft != isLeft;
}

/// Paints the dashed flight route line with an airplane icon in the middle
/// and small dots for intermediate stops.
class _RouteLinePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final int stops;
  const _RouteLinePainter({
    required this.color,
    required this.accentColor,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cy = size.height / 2;
    final planeHalf = 14.0;
    final left = 6.0;
    final right = size.width - 6.0;

    // Left segment
    canvas.drawLine(
        Offset(left, cy), Offset(size.width / 2 - planeHalf, cy), paint);
    // Right segment
    canvas.drawLine(
        Offset(size.width / 2 + planeHalf, cy), Offset(right, cy), paint);

    // Endpoint dots
    final dotPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(left, cy), 3, dotPaint);
    canvas.drawCircle(Offset(right, cy), 3, dotPaint);

    // Airplane icon using a rotated path approximation
    final planePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, cy);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 2); // point right
    _drawPlane(canvas, planePaint, 10);
    canvas.restore();

    // Stop dots between segments
    if (stops > 0) {
      final stopPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      for (int i = 1; i <= stops; i++) {
        final x = left + (right - left) * i / (stops + 1);
        canvas.drawCircle(Offset(x, cy), 3.5, stopPaint);
      }
    }
  }

  void _drawPlane(Canvas canvas, Paint paint, double scale) {
    final path = Path()
      ..moveTo(0, -scale)
      ..lineTo(scale * 0.3, scale * 0.2)
      ..lineTo(0, 0)
      ..lineTo(-scale * 0.3, scale * 0.2)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RouteLinePainter old) =>
      old.color != color ||
      old.accentColor != accentColor ||
      old.stops != stops;
}
