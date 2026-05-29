// lib/features/profiles/screens/my_bookings_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/network/api_client.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _loading = true;
  String? _error;
  List<_Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/flights/bookings',
          query: {'page': '1', 'limit': '10'}, auth: true);
      final data = res['data'] as List<dynamic>? ?? [];
      setState(() {
        _bookings = data
            .map((e) => _Booking.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          _buildHeader(isDark, context),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontXL,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'All your flight reservations',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: AppSizes.fontXS,
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

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (_, __) => _SkeletonCard(isDark: isDark),
      );
    }
    if (_error != null) {
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
                'Failed to load bookings',
                style: TextStyle(
                  fontSize: AppSizes.fontMD,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: isDark
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
    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: AppSizes.fontLG,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your flight bookings will appear here',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryStart,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: _bookings.length,
        itemBuilder: (ctx, i) =>
            _BookingCard(booking: _bookings[i], isDark: isDark),
      ),
    );
  }
}

// ── Booking Card ────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final _Booking booking;
  final bool isDark;
  const _BookingCard({required this.booking, required this.isDark});

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return AppColors.success;
      case 'PENDING_PAYMENT':
        return AppColors.warning;
      case 'PAYMENT_PROCESSING':
        return const Color(0xFF4FC3F7);
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PENDING_PAYMENT':
        return 'Pending Payment';
      case 'PAYMENT_PROCESSING':
        return 'Processing';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Icons.check_circle_rounded;
      case 'PENDING_PAYMENT':
        return Icons.schedule_rounded;
      case 'PAYMENT_PROCESSING':
        return Icons.sync_rounded;
      case 'CANCELLED':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
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
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fb = booking.flightBooking;
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        children: [
          // Top strip: status
          Container(
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(_statusIcon(booking.status), color: statusColor, size: 15),
                const SizedBox(width: 6),
                Text(
                  _statusLabel(booking.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.bookingRef,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route row
                Row(
                  children: [
                    // Origin
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fb?.origin ?? '—',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _formatTime(fb?.departureTime),
                            style: TextStyle(
                              fontSize: AppSizes.fontXS,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Flight path
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            fb?.carrier ?? 'XX',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryStart,
                                    shape: BoxShape.circle)),
                            Container(
                              width: 60,
                              height: 1.5,
                              color:
                                  AppColors.primaryStart.withValues(alpha: 0.4),
                            ),
                            Icon(Icons.flight_rounded,
                                color: AppColors.primaryStart, size: 16),
                            Container(
                              width: 60,
                              height: 1.5,
                              color:
                                  AppColors.primaryStart.withValues(alpha: 0.4),
                            ),
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: AppColors.primaryStart,
                                    shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fb?.tripType == 'ONE_WAY' ? 'One Way' : 'Round Trip',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Destination
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            fb?.destination ?? '—',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            _formatDate(fb?.departureTime),
                            style: TextStyle(
                              fontSize: AppSizes.fontXS,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    height: 1),
                const SizedBox(height: 14),

                // Bottom row: cabin + amount
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.airline_seat_recline_normal_rounded,
                      label: fb?.cabinClass ?? 'Economy',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    if (fb?.pnr != null)
                      _InfoChip(
                        icon: Icons.confirmation_number_rounded,
                        label: 'PNR: ${fb!.pnr!}',
                        isDark: isDark,
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${booking.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: AppSizes.fontLG,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryStart,
                          ),
                        ),
                        Text(
                          booking.currency,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _InfoChip(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primaryStart),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: c),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────────

class _FlightBookingDetail {
  final String? pnr;
  final String? origin;
  final String? destination;
  final String? carrier;
  final String? tripType;
  final String? cabinClass;
  final String? departureTime;

  _FlightBookingDetail({
    this.pnr,
    this.origin,
    this.destination,
    this.carrier,
    this.tripType,
    this.cabinClass,
    this.departureTime,
  });

  factory _FlightBookingDetail.fromJson(Map<String, dynamic> j) {
    // origin/destination might be JSON strings
    String? parseAirport(dynamic v) {
      if (v == null) return null;
      if (v is String && v.startsWith('{')) {
        try {
          // crude parse for iataCode
          final match = RegExp(r'"iataCode"\s*:\s*"([^"]+)"').firstMatch(v);
          return match?.group(1);
        } catch (_) {}
      }
      return v as String?;
    }

    return _FlightBookingDetail(
      pnr: j['pnr'] as String?,
      origin: parseAirport(j['origin']),
      destination: parseAirport(j['destination']),
      carrier: j['carrier'] as String?,
      tripType: j['trip_type'] as String? ?? j['tripType'] as String?,
      cabinClass: (j['cabin_class'] as String? ?? j['cabinClass'] as String?)
          ?.toUpperCase(),
      departureTime:
          j['departure_time'] as String? ?? j['departureTime'] as String?,
    );
  }
}

class _Booking {
  final String id;
  final String bookingRef;
  final String status;
  final double totalAmount;
  final String currency;
  final _FlightBookingDetail? flightBooking;

  _Booking({
    required this.id,
    required this.bookingRef,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.flightBooking,
  });

  factory _Booking.fromJson(Map<String, dynamic> j) {
    final fbList = j['flight_booking'] as List<dynamic>? ?? [];
    return _Booking(
      id: j['id'] as String? ?? '',
      bookingRef:
          j['booking_ref'] as String? ?? j['bookingRef'] as String? ?? '',
      status: j['status'] as String? ?? '',
      totalAmount: (j['total_amount'] as num? ?? j['totalAmount'] as num? ?? 0)
          .toDouble(),
      currency: j['currency'] as String? ?? 'USD',
      flightBooking: fbList.isNotEmpty
          ? _FlightBookingDetail.fromJson(fbList.first as Map<String, dynamic>)
          : null,
    );
  }
}
