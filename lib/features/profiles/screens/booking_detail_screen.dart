// lib/features/profiles/screens/booking_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../flights/screens/cancel_booking_screen.dart';
import '../../flights/change_request/widgets/change_flight_button.dart';
import 'eticket_screen.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String bookingRef;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    required this.bookingRef,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _booking;
  bool _viewingTicket = false;

  // FIX: track whether the widget is still mounted before calling setState
  // after async operations so back-navigation doesn't cause freezes.
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    // Load directly — ApiClient decodes JSON in a background isolate
    // and reads tokens from memory cache, so this is non-blocking.
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Safe setState that no-ops after dispose, preventing the post-navigation
  // freeze caused by async callbacks firing on a dead widget.
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
        '/flights/bookings/${widget.bookingId}',
        auth: true,
      );
      _safeSetState(() {
        _booking = res['data'] as Map<String, dynamic>? ?? res;
        _loading = false;
      });
    } catch (e) {
      _safeSetState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _viewTicket() async {
    _safeSetState(() => _viewingTicket = true);
    try {
      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => ETicketScreen(
            bookingId: widget.bookingId,
            bookingRef: widget.bookingRef,
          ),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 380),
        ),
      );
    } finally {
      _safeSetState(() => _viewingTicket = false);
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String get _status => (_booking?['status'] as String? ?? '').toUpperCase();

  bool get _isConfirmed => _status == 'CONFIRMED';
  bool get _isCancelled => _status == 'CANCELLED';

  bool get _isCancellable =>
      ['CONFIRMED', 'PENDING_PAYMENT', 'PAYMENT_PROCESSING'].contains(_status);

  bool get _isChangeable =>
      _isConfirmed &&
          ((_booking?['conditions'] as Map<String, dynamic>?)?['changeable'] as bool? ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      _isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryStart,
              ),
            )
                : _error != null
                ? _buildError()
                : _buildBody(),
          ),
          if (!_loading && _error == null && _booking != null)
            _buildBottomActions(),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
                      'Booking Details',
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

  // ── Error ───────────────────────────────────────────────────────────────────

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
              child: Icon(Icons.wifi_off_rounded,
                  color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load booking',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w700,
                color: _isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
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

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final b = _booking!;
    final slices = (b['slices'] as List<dynamic>? ?? []);
    final passengers = (b['passengers'] as List<dynamic>? ?? []);
    final payment = b['paymentSummary'] as Map<String, dynamic>?;
    final refund = b['refundSummary'] as Map<String, dynamic>?;
    final conditions = b['conditions'] as Map<String, dynamic>?;
    final pricing = b['pricing'] as Map<String, dynamic>?;

    // FIX: Extract cancellation info from top-level fields since
    // cancellationInfo object may be null while the fields are present directly.
    final cancellationReason = b['cancellationReason'] as String?;
    final cancelledAt = b['cancelledAt'] as String?;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        // Status badge
        _buildStatusBadge(),
        const SizedBox(height: 12),

        // FIX: Show cancellation info block when cancelled
        if (_isCancelled &&
            (cancellationReason != null || cancelledAt != null)) ...[
          _buildCancellationInfoCard(
              reason: cancellationReason, cancelledAt: cancelledAt),
          const SizedBox(height: 20),
        ],

        // Flight route card
        if (slices.isNotEmpty) ...[
          _buildSectionTitle('Flight Details'),
          const SizedBox(height: 12),
          ...slices.asMap().entries.map(
                  (e) => _buildSliceCard(e.value as Map<String, dynamic>, e.key)),
          const SizedBox(height: 20),
        ] else ...[
          // Fallback for test/manual bookings with no Duffel data
          _buildSectionTitle('Flight Details'),
          const SizedBox(height: 12),
          _buildFallbackFlightCard(b),
          const SizedBox(height: 20),
        ],

        // PNR / Booking reference — only show if at least one value is non-null
        if (_hasBookingReference(b)) ...[
          _buildSectionTitle('Booking Reference'),
          const SizedBox(height: 12),
          _buildPnrCard(b),
          const SizedBox(height: 20),
        ],

        // Passengers
        if (passengers.isNotEmpty) ...[
          _buildSectionTitle('Passengers'),
          const SizedBox(height: 12),
          ...passengers.map(
                  (p) => _buildPassengerCard(p as Map<String, dynamic>, slices)),
          const SizedBox(height: 20),
        ],

        // Payment summary
        if (payment != null) ...[
          _buildSectionTitle('Payment'),
          const SizedBox(height: 12),
          _buildPaymentCard(payment, b),
          const SizedBox(height: 20),
        ] else if (pricing != null || b['total_amount'] != null) ...[
          _buildSectionTitle('Payment'),
          const SizedBox(height: 12),
          _buildSimplePaymentCard(b),
          const SizedBox(height: 20),
        ],

        // Refund info
        if (refund != null) ...[
          _buildSectionTitle('Refund'),
          const SizedBox(height: 12),
          _buildRefundCard(refund),
          const SizedBox(height: 20),
        ],

        // Cancellation policy
        if (conditions != null) ...[
          _buildSectionTitle('Policies'),
          const SizedBox(height: 12),
          _buildPoliciesCard(conditions),
          const SizedBox(height: 20),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  // FIX: Helper to check whether at least one booking reference field is
  // non-null/non-empty, preventing an empty card from rendering.
  bool _hasBookingReference(Map<String, dynamic> b) {
    final refs = b['bookingReferences'] as List<dynamic>? ?? [];
    return b['pnr'] != null || b['bookingReference'] != null || refs.isNotEmpty;
  }

  // ── Status Badge ────────────────────────────────────────────────────────────

  Widget _buildStatusBadge() {
    final color = _statusColor(_status);
    final label = _statusLabel(_status);
    final icon = _statusIcon(_status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontSize: AppSizes.fontXS,
                  color: _isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.fontMD,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          // FIX: Removed inline cancelled-date here; it's now in its own card
          // below the status badge so it doesn't get clipped on narrow screens.
        ],
      ),
    );
  }

  // ── Cancellation Info Card ───────────────────────────────────────────────────

  // FIX: New dedicated card to show cancellation date + reason clearly.
  Widget _buildCancellationInfoCard({String? reason, String? cancelledAt}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          if (cancelledAt != null)
            _payRow(
              'Cancelled On',
              _formatDate(cancelledAt),
            ),
          if (cancelledAt != null && reason != null) const Divider(height: 16),
          if (reason != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    color: _isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: _isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Section Title ───────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w800,
        color: _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  // ── Slice Card (one per flight leg) ─────────────────────────────────────────

  Widget _buildSliceCard(Map<String, dynamic> slice, int index) {
    final segments = slice['segments'] as List<dynamic>? ?? [];
    final origin = slice['origin'] as Map<String, dynamic>?;
    final dest = slice['destination'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                _airportBlock(
                  iata: origin?['iataCode'] as String? ?? '—',
                  city: origin?['cityName'] as String? ?? '',
                  time: _formatTime(slice['departureAt'] as String?),
                  align: CrossAxisAlignment.start,
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (segments.isNotEmpty)
                        Text(
                          (segments.first as Map<String, dynamic>?)?[
                          'marketingCarrier']?['iataCode'] as String? ??
                              '—',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle)),
                          Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          const Icon(Icons.flight_rounded,
                              color: Colors.white, size: 18),
                          Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.4)),
                          ),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(slice['duration'] as String?),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: AppSizes.fontXS,
                        ),
                      ),
                    ],
                  ),
                ),
                _airportBlock(
                  iata: dest?['iataCode'] as String? ?? '—',
                  city: dest?['cityName'] as String? ?? '',
                  time: _formatTime(slice['arrivalAt'] as String?),
                  align: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
          ...segments
              .map((seg) => _buildSegmentDetail(seg as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _airportBlock({
    required String iata,
    required String city,
    required String time,
    required CrossAxisAlignment align,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          iata,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        if (time.isNotEmpty)
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (city.isNotEmpty)
          Text(
            city,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: AppSizes.fontXS,
            ),
          ),
      ],
    );
  }

  Widget _buildSegmentDetail(Map<String, dynamic> seg) {
    final marketing = seg['marketingCarrier'] as Map<String, dynamic>?;
    final flightNum = seg['marketingCarrierFlightNumber'] as String?;
    final aircraft = seg['aircraft'] as Map<String, dynamic>?;
    final originTerminal = seg['originTerminal'] as String?;
    final destTerminal = seg['destinationTerminal'] as String?;
    final passengers = seg['passengers'] as List<dynamic>? ?? [];

    final firstPax = passengers.isNotEmpty
        ? passengers.first as Map<String, dynamic>?
        : null;
    final seat = firstPax?['seat'] as Map<String, dynamic>?;
    final cabinClass = firstPax?['cabinClass'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _detailChip(
                Icons.flight_takeoff_rounded,
                flightNum != null
                    ? '${marketing?['iataCode'] ?? ''}$flightNum'
                    : '—',
              ),
              const SizedBox(width: 8),
              if (aircraft != null)
                _detailChip(Icons.airplanemode_active_rounded,
                    aircraft['name'] as String? ?? ''),
              const SizedBox(width: 8),
              if (cabinClass != null)
                _detailChip(Icons.airline_seat_recline_normal_rounded,
                    cabinClass.toUpperCase()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (originTerminal != null)
                Expanded(
                  child: _infoTile(
                    'Departure Terminal',
                    'Terminal $originTerminal',
                    Icons.login_rounded,
                  ),
                ),
              if (originTerminal != null && destTerminal != null)
                const SizedBox(width: 8),
              if (destTerminal != null)
                Expanded(
                  child: _infoTile(
                    'Arrival Terminal',
                    'Terminal $destTerminal',
                    Icons.logout_rounded,
                  ),
                ),
            ],
          ),
          if (seat != null) ...[
            const SizedBox(height: 8),
            _infoTile(
              'Seat',
              seat['designator'] as String? ?? '—',
              Icons.event_seat_rounded,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }

  // ── Fallback flight card ─────────────────────────────────────────────────────

  Widget _buildFallbackFlightCard(Map<String, dynamic> b) {
    final fb = (b['flight_booking'] as List<dynamic>?)?.isNotEmpty == true
        ? (b['flight_booking'] as List<dynamic>).first as Map<String, dynamic>
        : null;

    final origin = fb?['origin'] as String? ?? '—';
    final destination = fb?['destination'] as String? ?? '—';
    final departureTime = fb?['departure_time'] as String?;
    final tripType = fb?['trip_type'] as String? ?? 'ONE_WAY';
    final cabinClass = fb?['cabin_class'] as String? ?? 'ECONOMY';
    final carrier = fb?['carrier'] as String?;

    // FIX: When there's no flight_booking data either, show a graceful
    // "No flight details available" tile instead of a broken card with
    // placeholder values like "XX" and dashes.
    final hasData = fb != null;

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_rounded,
              size: 20,
              color: _isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              'Flight details not available',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: _isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                _airportBlock(
                  iata: origin,
                  city: '',
                  time: _formatTime(departureTime),
                  align: CrossAxisAlignment.start,
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (carrier != null)
                        Text(carrier,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle)),
                        Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.4))),
                        const Icon(Icons.flight_rounded,
                            color: Colors.white, size: 18),
                        Expanded(
                            child: Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.4))),
                        Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                shape: BoxShape.circle)),
                      ]),
                      const SizedBox(height: 4),
                      Text(tripType == 'ROUND_TRIP' ? 'Round Trip' : 'One Way',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: AppSizes.fontXS)),
                    ],
                  ),
                ),
                _airportBlock(
                  iata: destination,
                  city: '',
                  time: '',
                  align: CrossAxisAlignment.end,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _detailChip(
                    Icons.airline_seat_recline_normal_rounded, cabinClass),
                // FIX: Only show date chip when departure_time is non-null
                if (departureTime != null)
                  _detailChip(
                      Icons.calendar_today_rounded, _formatDate(departureTime)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PNR Card ────────────────────────────────────────────────────────────────

  Widget _buildPnrCard(Map<String, dynamic> b) {
    final pnr = b['pnr'] as String?;
    final bookingRef = b['bookingReference'] as String?;
    final refs = (b['bookingReferences'] as List<dynamic>? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (pnr != null) _pnrRow('Airline PNR', pnr),
          if (bookingRef != null) ...[
            if (pnr != null) const Divider(height: 20),
            _pnrRow('Booking Reference', bookingRef),
          ],
          ...refs.map((r) {
            final ref = r as Map<String, dynamic>;
            return Column(
              children: [
                const Divider(height: 20),
                _pnrRow(
                  ref['carrier']?['name'] as String? ?? 'Carrier Ref',
                  ref['reference'] as String? ?? '—',
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _pnrRow(String label, String value) {
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
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.primaryStart,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                if (!_disposed && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: Icon(Icons.copy_rounded,
                  size: 15,
                  color: _isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ── Passenger Card ──────────────────────────────────────────────────────────

  Widget _buildPassengerCard(Map<String, dynamic> p, List<dynamic> slices) {
    final firstName =
        p['givenName'] as String? ?? p['first_name'] as String? ?? '';
    final lastName =
        p['familyName'] as String? ?? p['last_name'] as String? ?? '';
    final name = '$firstName $lastName'.trim();

    final rawType =
        p['type'] as String? ?? p['travel_type'] as String? ?? 'ADULT';
    final type = rawType.toUpperCase();

    // FIX: Accept both camelCase and snake_case date-of-birth field names
    final dob = p['bornOn'] as String? ?? p['date_of_birth'] as String?;
    final nationality = p['nationality'] as String?;

    // FIX: Normalise gender — backend sends uppercase e.g. "FEMALE"
    final rawGender = p['gender'] as String?;
    final gender =
    rawGender != null ? _capitalize(rawGender.toLowerCase()) : null;

    final List<String> seats = [];
    for (final slice in slices) {
      final segs =
          (slice as Map<String, dynamic>)['segments'] as List<dynamic>? ?? [];
      for (final seg in segs) {
        final paxList =
            (seg as Map<String, dynamic>)['passengers'] as List<dynamic>? ?? [];
        for (final pax in paxList) {
          final paxMap = pax as Map<String, dynamic>;
          if (paxMap['passengerId'] == p['id']) {
            final seat = paxMap['seat'] as Map<String, dynamic>?;
            if (seat?['designator'] != null) {
              seats.add(seat!['designator'] as String);
            }
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child:
            const Icon(Icons.person_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Passenger',
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w700,
                    color: _isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _miniChip(_passengerTypeLabel(type)),
                    if (gender != null) _miniChip(gender),
                    if (nationality != null) _miniChip(nationality),
                    if (dob != null) _miniChip('DOB: ${_formatDate(dob)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (seats.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Seat',
                  style: TextStyle(
                    fontSize: AppSizes.fontXS,
                    color: _isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  seats.join(', '),
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryStart,
                  ),
                ),
              ],
            )
          else
            Text(
              'No seat\nassigned',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppSizes.fontXS,
                color: _isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _passengerTypeLabel(String type) {
    switch (type) {
      case 'ADULT':
        return 'Adult';
      case 'CHILD':
        return 'Child';
      case 'INFANT_WITHOUT_SEAT':
      case 'INFANT':
        return 'Infant';
      default:
        return _capitalize(type);
    }
  }

  // ── Payment Card ────────────────────────────────────────────────────────────

  Widget _buildPaymentCard(
      Map<String, dynamic> payment, Map<String, dynamic> b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _payRow(
              'Amount Paid',
              '${payment['currency'] ?? b['currency'] ?? 'USD'} '
                  '${_formatAmount(payment['amount'])}',
              bold: true,
              color: AppColors.success),
          const Divider(height: 20),
          _payRow('Payment Method',
              _capitalize(payment['provider'] as String? ?? 'Card')),
          _payRow('Payment Status',
              _capitalize(payment['status'] as String? ?? '—')),
          if (payment['paidAt'] != null)
            _payRow('Paid On', _formatDate(payment['paidAt'] as String?)),
        ],
      ),
    );
  }

  Widget _buildSimplePaymentCard(Map<String, dynamic> b) {
    final pricing = b['pricing'] as Map<String, dynamic>?;
    final amount = pricing?['totalAmount'] ??
        pricing?['total_amount'] ??
        b['total_amount'];
    final currency = pricing?['currency'] ??
        pricing?['baseCurrency'] ??
        b['currency'] ??
        'USD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: _payRow(
        'Total Amount',
        '$currency ${_formatAmount(amount)}',
        bold: true,
      ),
    );
  }

  Widget _payRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ??
                  (_isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Refund Card ─────────────────────────────────────────────────────────────

  Widget _buildRefundCard(Map<String, dynamic> refund) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _payRow(
              'Refund Amount',
              '${refund['currency'] ?? 'USD'} '
                  '${_formatAmount(refund['amount'])}',
              bold: true,
              color: AppColors.warning),
          const Divider(height: 20),
          _payRow('Status', _capitalize(refund['status'] as String? ?? '—')),
          if (refund['instructions'] != null) ...[
            const SizedBox(height: 8),
            Text(
              refund['instructions'] as String,
              style: TextStyle(
                fontSize: AppSizes.fontXS,
                color: _isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Policies Card ───────────────────────────────────────────────────────────

  Widget _buildPoliciesCard(Map<String, dynamic> conditions) {
    final refundable = conditions['refundable'] as bool? ?? false;
    final changeable = conditions['changeable'] as bool? ?? false;
    final refundPenalty = conditions['refundPenaltyAmount'];
    final changePenalty = conditions['changePenaltyAmount'];
    final currency = conditions['refundPenaltyCurrency'] as String? ??
        conditions['changePenaltyCurrency'] as String? ??
        'USD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _policyRow(
            icon:
            refundable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: refundable ? AppColors.success : AppColors.error,
            label: 'Refundable',
            value: refundable
                ? (refundPenalty != null
                ? 'Penalty: $currency $refundPenalty'
                : 'Yes')
                : 'Non-refundable',
          ),
          const Divider(height: 20),
          _policyRow(
            icon:
            changeable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: changeable ? AppColors.success : AppColors.error,
            label: 'Changeable',
            value: changeable
                ? (changePenalty != null
                ? 'Penalty: $currency $changePenalty'
                : 'Yes')
                : 'Non-changeable',
          ),
        ],
      ),
    );
  }

  Widget _policyRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            color: _isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Bottom Actions ──────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    if (!_isChangeable && !_isCancellable) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: _isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Change Flight button — only visible for CONFIRMED + changeable bookings
          if (_isChangeable) ...[
            ChangeFlightButton(
              bookingId: widget.bookingId,
              bookingStatus: _status,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              if (_isCancellable) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final b = _booking!;
                      final slices = b['slices'] as List<dynamic>? ?? [];
                      String flightInfo = widget.bookingRef;
                      if (slices.isNotEmpty) {
                        final s = slices.first as Map<String, dynamic>;
                        final origin = (s['origin']
                        as Map<String, dynamic>?)?['iataCode'] as String? ??
                            '--';
                        final dest = (s['destination']
                        as Map<String, dynamic>?)?['iataCode'] as String? ??
                            '--';
                        final dep = s['departureAt'] as String?;
                        String dateStr = '';
                        if (dep != null) {
                          try {
                            final dt = DateTime.parse(dep).toLocal();
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
                              'Dec'
                            ];
                            dateStr = ' · ${dt.day} ${months[dt.month]}';
                          } catch (_) {}
                        }
                        flightInfo = '$origin → $dest$dateStr';
                      }

                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => CancelBookingScreen(
                            bookingId: widget.bookingId,
                            bookingRef: widget.bookingRef,
                            flightInfo: flightInfo,
                          ),
                          transitionsBuilder: (_, anim, __, child) =>
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                    parent: anim, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                          transitionDuration: const Duration(milliseconds: 320),
                        ),
                      );

                      // Reload booking after returning — status may now be CANCELLED
                      _load();
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text(
                      'Cancel Booking',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: AppSizes.fontSM),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                if (_isConfirmed) const SizedBox(width: 12),
              ],
              if (_isConfirmed)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewingTicket ? null : _viewTicket,
                    icon: _viewingTicket
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text(
                      'View Ticket',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: AppSizes.fontSM),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
            ],
          ),  // end Row
        ],
      ),      // end Column
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

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

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryStart),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w600,
              color: _isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryStart.withValues(alpha: 0.08)
            : (_isDark ? AppColors.darkSurface : AppColors.lightBackground),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: AppColors.primaryStart.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 14,
              color: highlight
                  ? AppColors.primaryStart
                  : (_isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: 9,
                    color: _isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  )),
              Text(value,
                  style: TextStyle(
                    fontSize: AppSizes.fontXS,
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? AppColors.primaryStart
                        : (_isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.darkSurface : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppSizes.fontXS,
          color: _isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────────────────

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = [
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
      ];
      return '${m[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatDuration(String? iso) {
    if (iso == null) return '';
    final h = RegExp(r'(\d+)H').firstMatch(iso)?.group(1);
    final min = RegExp(r'(\d+)M').firstMatch(iso)?.group(1);
    if (h != null && min != null) return '${h}h ${min}m';
    if (h != null) return '${h}h';
    if (min != null) return '${min}m';
    return iso;
  }

  String _formatAmount(dynamic val) {
    if (val == null) return '0.00';
    return double.tryParse(val.toString())?.toStringAsFixed(2) ?? '0.00';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING_PAYMENT':
        return AppColors.warning;
      case 'PAYMENT_PROCESSING':
        return const Color(0xFF4FC3F7);
      case 'CANCELLED':
        return AppColors.error;
      case 'REFUND_REQUESTED':
      case 'REFUND_PROCESSING':
        return AppColors.warning;
      case 'REFUNDED':
        return AppColors.success;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PENDING_PAYMENT':
        return 'Pending Payment';
      case 'PAYMENT_PROCESSING':
        return 'Processing Payment';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUND_REQUESTED':
        return 'Refund Requested';
      case 'REFUND_PROCESSING':
        return 'Refund Processing';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Icons.check_circle_rounded;
      case 'PENDING_PAYMENT':
        return Icons.schedule_rounded;
      case 'PAYMENT_PROCESSING':
        return Icons.sync_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      case 'REFUND_REQUESTED':
      case 'REFUND_PROCESSING':
        return Icons.currency_exchange_rounded;
      case 'REFUNDED':
        return Icons.price_check_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}

