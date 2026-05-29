// lib/features/flights/screens/flight_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../auth/widgets/gradient_button.dart';
import '../models/flight_offer.dart';

class FlightDetailsScreen extends StatefulWidget {
  const FlightDetailsScreen({super.key});

  @override
  State<FlightDetailsScreen> createState() => _FlightDetailsScreenState();
}

class _FlightDetailsScreenState extends State<FlightDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isFavorited = false;
  bool _isLoadingDetails = false;
  FlightOffer? _fullOffer; // fetched via GET /flights/offers/:id
  String? _fetchError;

  final FlightService _flightService = FlightService();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch once
    if (_fullOffer == null && !_isLoadingDetails && _fetchError == null) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is FlightOffer) {
        // Same-library FlightOffer — ideal path
        _fetchFullOfferById(arg.offerId, seed: arg);
      } else if (arg is String && arg.isNotEmpty) {
        // Caller passed the offerId string directly
        _fetchFullOfferById(arg);
      } else if (arg != null) {
        // Cross-library FlightOffer (e.g. from flight_service.dart):
        // same field name, different Dart type identity — extract via dynamic
        try {
          final dynamic dynArg = arg;
          final String offerId = dynArg.offerId as String;
          _fetchFullOfferById(offerId);
        } catch (_) {
          // Unrecognised argument — error state shown in build()
        }
      }
    }
  }

  Future<void> _fetchFullOfferById(String offerId, {FlightOffer? seed}) async {
    setState(() {
      _isLoadingDetails = true;
      _fetchError = null;
    });
    try {
      final full = await _flightService.getOffer(offerId);
      if (mounted) {
        setState(() {
          _fullOffer = full;
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _fullOffer = seed;
          _isLoadingDetails = false;
          _fetchError = seed == null ? 'Failed to load offer details.' : null;
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    // While the full offer is loading we show a loading screen.
    // If _fullOffer is null and we haven't started loading yet, show a spinner.
    if (_fullOffer == null) {
      // Show loading state while we fetch — the fetch was kicked off in
      // didChangeDependencies using the navigation argument (any type).
      if (_isLoadingDetails || _fetchError == null) {
        return Scaffold(
          backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      // Fetch failed and no seed offer available
      return Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CustomBackButton(useLightStyle: false),
                ]),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                      const SizedBox(height: 16),
                      Text(
                        _fetchError ?? 'Failed to load flight details.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Full offer is ready
    final offer = _fullOffer!;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _buildHeader(context, offer, isDark, tc)),
              if (_isLoadingDetails)
                const SliverToBoxAdapter(child: _LoadingBanner()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFlightTimeline(offer, isDark),
                      const SizedBox(height: 20),
                      _buildAirlineSection(offer, isDark),
                      const SizedBox(height: 20),
                      _buildInfoGrid(offer, isDark),
                      const SizedBox(height: 20),
                      _buildCabinAmenities(offer, isDark),
                      const SizedBox(height: 20),
                      _buildBaggage(offer, isDark),
                      const SizedBox(height: 20),
                      _buildPriceBreakdown(offer, isDark),
                      const SizedBox(height: 20),
                      _buildPaymentInfo(offer, isDark),
                      const SizedBox(height: 20),
                      _buildPolicies(offer, isDark),
                      const SizedBox(height: 28),
                      _buildSeatMapButton(context, offer, isDark),
                      const SizedBox(height: 16),
                      _buildBookButton(context, offer, isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, FlightOffer offer, bool isDark,
      ThemeController tc) {
    final slice = offer.outbound;
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            children: [
              // Nav row
              Row(
                children: [
                  const CustomBackButton(useLightStyle: true),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Flight Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontXL,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFavorited = !_isFavorited),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _isFavorited
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isFavorited ? AppColors.accent : Colors.white,
                        size: 18,
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
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Airline card — logo + name + IATA + flight number
              if (offer.airline.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    children: [
                      // Logo box
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: _AirlineLogo(
                          logoUrl: offer.airlineLogoUrl.isNotEmpty
                              ? offer.airlineLogoUrl
                              : (offer.outbound.segments.isNotEmpty
                              ? offer.outbound.segments.first.marketingCarrier?.logoUrl ?? ''
                              : ''),
                          size: 28,
                          fallbackIcon: Icons.airlines_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Airline name + IATA
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.airline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: AppSizes.fontMD,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              offer.airlineIataCode.isNotEmpty
                                  ? offer.airlineIataCode
                                  : '',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: AppSizes.fontSM,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Flight number pill
                      if (offer.outbound.segments.isNotEmpty &&
                          offer.outbound.segments.first.flightNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${offer.outbound.segments.first.marketingCarrier?.iataCode ?? ''}${offer.outbound.segments.first.flightNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Big route display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoutePoint(
                      code: slice.origin.iataCode,
                      city: slice.origin.cityName,
                      align: CrossAxisAlignment.start),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(slice.duration),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: AppSizes.fontSM,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)),
                            Expanded(
                              child: CustomPaint(painter: _WhiteDashPainter()),
                            ),
                            const Icon(Icons.flight_rounded,
                                color: Colors.white, size: 20),
                            Expanded(
                              child: CustomPaint(painter: _WhiteDashPainter()),
                            ),
                            Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: offer.stops == 0
                                ? AppColors.success.withValues(alpha: 0.25)
                                : AppColors.warning.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            offer.stops == 0
                                ? 'Non-stop'
                                : '${offer.stops} stop${offer.stops > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: offer.stops == 0
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoutePoint(
                      code: slice.destination.iataCode,
                      city: slice.destination.cityName,
                      align: CrossAxisAlignment.end),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Journey Timeline ──────────────────────────────────────────────────────

  Widget _buildFlightTimeline(FlightOffer offer, bool isDark) {
    final slice = offer.outbound;
    return _Section(
      title: 'Journey Timeline',
      isDark: isDark,
      child: Column(
        children: [
          for (int i = 0; i < slice.segments.length; i++) ...[
            _SegmentTimelineItem(
              segment: slice.segments[i],
              isFirst: i == 0,
              isLast: i == slice.segments.length - 1,
              isDark: isDark,
            ),
            // Layover between segments
            if (i < slice.segments.length - 1)
              _LayoverRow(
                arr: slice.segments[i].arrivingAt,
                dep: slice.segments[i + 1].departingAt,
                isDark: isDark,
              ),
          ],
          // Final arrival row
          _ArrivalRow(
            segment: slice.segments.last,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Info Grid ─────────────────────────────────────────────────────────────

  Widget _buildInfoGrid(FlightOffer offer, bool isDark) {
    final seg = offer.outbound.segments.first;
    final items = <Map<String, dynamic>>[
      {
        'icon': Icons.flight_rounded,
        'label': 'Flight No.',
        'value': seg.flightNumber != null
            ? '${seg.marketingCarrier?.iataCode ?? ''}${seg.flightNumber}'
            : '—',
      },
      {
        'icon': Icons.airline_seat_recline_extra_rounded,
        'label': 'Segments',
        'value':
        '${offer.outbound.segments.length} segment${offer.outbound.segments.length > 1 ? 's' : ''}',
      },
      {
        'icon': Icons.access_time_rounded,
        'label': 'Duration',
        'value': _formatDuration(offer.outbound.duration),
      },
      {
        'icon': Icons.connecting_airports_rounded,
        'label': 'Stops',
        'value': offer.stops == 0
            ? 'Non-stop'
            : '${offer.stops} stop${offer.stops > 1 ? 's' : ''}',
      },
    ];

    if (seg.originTerminal != null) {
      items.add({
        'icon': Icons.door_sliding_rounded,
        'label': 'Terminal (Dep)',
        'value': seg.originTerminal!,
      });
    }
    if (seg.destinationTerminal != null) {
      items.add({
        'icon': Icons.door_sliding_outlined,
        'label': 'Terminal (Arr)',
        'value': seg.destinationTerminal!,
      });
    }

    return _Section(
      title: 'Flight Info',
      isDark: isDark,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Icon(items[i]['icon'] as IconData,
                  color: AppColors.primaryStart, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      items[i]['value'] as String,
                      style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Price Breakdown ───────────────────────────────────────────────────────

  Widget _buildPriceBreakdown(FlightOffer offer, bool isDark) {
    final pricing = offer.pricing;
    return _Section(
      title: 'Price Breakdown',
      isDark: isDark,
      child: Column(
        children: [
          _PriceRow(
              label: 'Base fare',
              amount: pricing.baseAmount,
              currency: pricing.totalCurrency,
              isDark: isDark),
          _PriceRow(
              label: 'Taxes & fees',
              amount: pricing.taxAmount,
              currency: pricing.totalCurrency,
              isDark: isDark),
          if (pricing.totalEmissionsKg != null)
            _Co2Row(kg: pricing.totalEmissionsKg!, isDark: isDark),
          Divider(
            height: 20,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Row(
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: AppSizes.fontMD,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient.createShader(b),
                child: Text(
                  '${pricing.totalCurrency} ${pricing.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Airline & Flight Info ────────────────────────────────────────────────

  Widget _buildAirlineSection(FlightOffer offer, bool isDark) {
    final segments = offer.outbound.segments;

    return _Section(
      title: 'Airline & Flight Info',
      isDark: isDark,
      child: Column(
        children: [
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0) ...[
              Divider(
                height: 24,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Text('Segment ${i + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _AirlineSegmentCard(segment: segments[i], isDark: isDark),
          ],
        ],
      ),
    );
  }

  // ── Cabin & Amenities ─────────────────────────────────────────────────────

  Widget _buildCabinAmenities(FlightOffer offer, bool isDark) {
    // Pull the first passenger's cabin from the first segment
    final seg = offer.outbound.segments.first;
    final pax = seg.passengers.isNotEmpty ? seg.passengers.first : null;
    final cabin = pax?.cabin;
    final amenities = cabin?.amenities;
    final fareBrand = offer.outbound.fareBrandName;

    final rows = <_AmenityItem>[];

    // Fare brand / cabin class
    if (fareBrand != null && fareBrand.isNotEmpty) {
      rows.add(_AmenityItem(
        icon: Icons.label_rounded,
        label: 'Fare Brand',
        value: fareBrand,
        positive: true,
      ));
    }
    if (cabin != null) {
      rows.add(_AmenityItem(
        icon: Icons.airline_seat_recline_extra_rounded,
        label: 'Cabin Class',
        value: cabin.marketingName ?? cabin.name ?? '—',
        positive: true,
      ));
    }

    // Wi-Fi
    final wifi = amenities?.wifi;
    if (wifi != null) {
      final available = wifi['available'] == true;
      final cost = wifi['cost'] as String?;
      rows.add(_AmenityItem(
        icon: Icons.wifi_rounded,
        label: 'Wi-Fi',
        value: available
            ? (cost == 'free'
            ? 'Free'
            : cost == 'paid'
            ? 'Paid'
            : 'Available')
            : 'Not available',
        positive: available,
      ));
    }

    // Seat
    final seat = amenities?.seat;
    if (seat != null) {
      final pitch = seat['pitch'] as String?;
      final legroom = seat['legroom'] as String?;
      final type = seat['type'] as String?;
      final detail = [
        if (type != null && type.isNotEmpty) type,
        if (pitch != null && pitch.isNotEmpty) 'Pitch: ${pitch}"',
        if (legroom != null && legroom != 'n/a' && legroom.isNotEmpty)
          'Legroom: $legroom',
      ].join(' · ');
      rows.add(_AmenityItem(
        icon: Icons.event_seat_rounded,
        label: 'Seat',
        value: detail.isNotEmpty ? detail : 'Standard',
        positive: true,
      ));
    }

    // Power
    final power = amenities?.power;
    if (power != null) {
      final available = power['available'] == true;
      rows.add(_AmenityItem(
        icon: Icons.power_rounded,
        label: 'Power',
        value: available ? 'Available' : 'Not available',
        positive: available,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Cabin & Amenities',
      isDark: isDark,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.5,
        ),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final item = rows[i];
          final color = item.positive
              ? AppColors.primaryStart
              : AppColors.darkTextSecondary;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          )),
                      Text(item.value,
                          style: TextStyle(
                            fontSize: AppSizes.fontSM,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Baggage ───────────────────────────────────────────────────────────────

  Widget _buildBaggage(FlightOffer offer, bool isDark) {
    final seg = offer.outbound.segments.first;
    final pax = seg.passengers.isNotEmpty ? seg.passengers.first : null;
    final baggages = pax?.baggages ?? [];
    final extraBagService =
    offer.availableServices.where((s) => s.type == 'baggage').toList();

    if (baggages.isEmpty && extraBagService.isEmpty)
      return const SizedBox.shrink();

    return _Section(
      title: 'Baggage',
      isDark: isDark,
      child: Column(
        children: [
          // Included baggage
          if (baggages.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 14),
                const SizedBox(width: 6),
                Text('Included baggage',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            ...baggages.map((b) {
              final type = b['type'] as String? ?? '';
              final qty = b['quantity'];
              IconData icon;
              String label;
              if (type == 'checked') {
                icon = Icons.luggage_rounded;
                label = '$qty × Checked bag';
              } else if (type == 'carry_on') {
                icon = Icons.backpack_rounded;
                label = '$qty × Carry-on bag';
              } else {
                icon = Icons.work_outline_rounded;
                label = '$qty × ${type.replaceAll('_', ' ')}';
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(label,
                        style: TextStyle(
                          fontSize: AppSizes.fontSM,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        )),
                  ],
                ),
              );
            }),
          ],

          // Extra baggage add-on
          if (extraBagService.isNotEmpty) ...[
            if (baggages.isNotEmpty)
              Divider(
                height: 20,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            Row(
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primaryStart, size: 14),
                const SizedBox(width: 6),
                Text('Available add-ons',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            ...extraBagService.map((svc) {
              final amount = svc.totalAmount ?? '—';
              final currency = svc.totalCurrency ?? '';
              final maxQty = svc.maximumQuantity ?? 1;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primaryStart.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.luggage_rounded,
                        color: AppColors.primaryStart, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Extra Checked Bag',
                              style: TextStyle(
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              )),
                          Text('Max qty: $maxQty  ·  Select during booking',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              )),
                        ],
                      ),
                    ),
                    Text('$currency $amount',
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryStart,
                        )),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Payment Requirements ──────────────────────────────────────────────────

  Widget _buildPaymentInfo(FlightOffer offer, bool isDark) {
    final pr = offer.paymentRequirements;
    if (pr == null) return const SizedBox.shrink();

    final instant = pr.requiresInstantPayment ?? false;
    final guaranteeExpiry = pr.priceGuaranteeExpiresAt;
    final payBy = pr.paymentRequiredBy;

    return _Section(
      title: 'Payment Requirements',
      isDark: isDark,
      child: Column(
        children: [
          _PolicyRow(
            icon: Icons.bolt_rounded,
            label: 'Instant Payment',
            value: instant
                ? 'Required — pay immediately to secure'
                : 'Not required at this stage',
            positive: !instant,
            isDark: isDark,
          ),
          if (guaranteeExpiry != null) ...[
            const SizedBox(height: 10),
            _PolicyRow(
              icon: Icons.verified_outlined,
              label: 'Price Guarantee Until',
              value: _formatExpiry(guaranteeExpiry),
              positive: true,
              isDark: isDark,
            ),
          ],
          if (payBy != null) ...[
            const SizedBox(height: 10),
            _PolicyRow(
              icon: Icons.payment_rounded,
              label: 'Payment Required By',
              value: _formatExpiry(payBy),
              positive: false,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ── Policies ──────────────────────────────────────────────────────────────

  Widget _buildPolicies(FlightOffer offer, bool isDark) {
    final cond = offer.conditions;
    final isRefundable = cond?.refundable ?? false;
    final isChangeable = cond?.changeable ?? false;
    final refundPenalty = cond?.refundPenaltyAmount;
    final changePenalty = cond?.changePenaltyAmount;

    return _Section(
      title: 'Policies',
      isDark: isDark,
      child: Column(
        children: [
          _PolicyRow(
            icon: Icons.replay_rounded,
            label: 'Cancellation',
            value: isRefundable
                ? refundPenalty != null
                ? 'Refundable · Penalty: $refundPenalty'
                : 'Free cancellation'
                : 'Non-refundable',
            positive: isRefundable,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _PolicyRow(
            icon: Icons.edit_calendar_rounded,
            label: 'Date Change',
            value: isChangeable
                ? changePenalty != null
                ? 'Changeable · Fee: $changePenalty'
                : 'Date change allowed'
                : 'Not changeable',
            positive: isChangeable,
            isDark: isDark,
          ),
          if (offer.expiresAt != null) ...[
            const SizedBox(height: 10),
            _PolicyRow(
              icon: Icons.timer_outlined,
              label: 'Offer Expires',
              value: _formatExpiry(offer.expiresAt!),
              positive: false,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  // ── See Seat Map button ───────────────────────────────────────────────────

  Widget _buildSeatMapButton(
      BuildContext context, FlightOffer offer, bool isDark) {
    return OutlinedButton.icon(
      onPressed: () {
        final slice = offer.outbound;
        final flightInfo =
            '${slice.origin.iataCode} → ${slice.destination.iataCode}'
            ' · ${_formatDate(slice.departureAt)}';
        Navigator.of(context).pushNamed(
          AppRoutes.seatMap,
          arguments: {
            'offerId': offer.offerId,
            'flightInfo': flightInfo,
          },
        );
      },
      icon: const Icon(Icons.event_seat_rounded),
      label: const Text('See Seat Map'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: AppColors.primaryStart,
        side: BorderSide(color: AppColors.primaryStart, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Book Button ───────────────────────────────────────────────────────────

  Widget _buildBookButton(
      BuildContext context, FlightOffer offer, bool isDark) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total price',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: Text(
                '${offer.currency} ${offer.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: AppSizes.fontXXL,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: GradientButton(
            text: 'Book Now',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _showBookingConfirm(context, offer, isDark),
          ),
        ),
      ],
    );
  }

  void _showBookingConfirm(
      BuildContext context, FlightOffer offer, bool isDark) {
    final slice = offer.outbound;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
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
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flight_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Confirm Booking',
              style: TextStyle(
                fontSize: AppSizes.fontXXL,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${slice.origin.iataCode} → ${slice.destination.iataCode}  ·  ${offer.airline}',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ConfirmItem(
                      label: 'Departure',
                      value: _formatTime(slice.departureAt),
                      isDark: isDark),
                  _ConfirmItem(
                      label: 'Arrival',
                      value: _formatTime(slice.arrivalAt),
                      isDark: isDark),
                  _ConfirmItem(
                    label: 'Total',
                    value:
                    '${offer.currency} ${offer.totalAmount.toStringAsFixed(0)}',
                    isDark: isDark,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Confirm & Pay',
              icon: Icons.lock_rounded,
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('Booking confirmed! 🎉',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return iso;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
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
      return '${months[dt.month]} ${dt.day}';
    } catch (_) {
      return iso;
    }
  }

  String _formatExpiry(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
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
      return '${months[dt.month]} ${dt.day} at $h:$m';
    } catch (_) {
      return iso;
    }
  }

  String _formatDuration(String iso) {
    // "PT7H45M" → "7h 45m"
    try {
      final d = Duration(
        hours:
        int.tryParse(RegExp(r'(\d+)H').firstMatch(iso)?.group(1) ?? '0') ??
            0,
        minutes:
        int.tryParse(RegExp(r'(\d+)M').firstMatch(iso)?.group(1) ?? '0') ??
            0,
      );
      final h = d.inHours;
      final m = d.inMinutes.remainder(60);
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } catch (_) {
      return iso;
    }
  }
}

// ── Loading banner ─────────────────────────────────────────────────────────

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: AppColors.primaryStart.withValues(alpha: 0.08),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Loading full offer details…',
            style: TextStyle(
                fontSize: AppSizes.fontSM, color: AppColors.primaryStart),
          ),
        ],
      ),
    );
  }
}

// ── Segment timeline row ──────────────────────────────────────────────────

class _SegmentTimelineItem extends StatelessWidget {
  final FlightSegment segment;
  final bool isFirst;
  final bool isLast;
  final bool isDark;

  const _SegmentTimelineItem({
    required this.segment,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
  });

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.primaryStart.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatTime(segment.departingAt),
                    style: TextStyle(
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${segment.origin.iataCode} · ${segment.origin.cityName}',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (segment.originTerminal != null)
                    Text(
                      'Terminal ${segment.originTerminal}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Flight info badge
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primaryStart.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flight_rounded,
                            color: AppColors.primaryStart, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          [
                            if (segment.marketingCarrier != null)
                              '${segment.marketingCarrier!.iataCode}${segment.flightNumber ?? ''}',
                            if (segment.duration.isNotEmpty)
                              _fmtDur(segment.duration),
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryStart,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDur(String iso) {
    try {
      final h =
          int.tryParse(RegExp(r'(\d+)H').firstMatch(iso)?.group(1) ?? '0') ?? 0;
      final m =
          int.tryParse(RegExp(r'(\d+)M').firstMatch(iso)?.group(1) ?? '0') ?? 0;
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } catch (_) {
      return iso;
    }
  }
}

// ── Arrival row (last segment) ─────────────────────────────────────────────

class _ArrivalRow extends StatelessWidget {
  final FlightSegment segment;
  final bool isDark;

  const _ArrivalRow({required this.segment, required this.isDark});

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(segment.arrivingAt),
                style: TextStyle(
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                '${segment.destination.iataCode} · ${segment.destination.cityName}',
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              if (segment.destinationTerminal != null)
                Text(
                  'Terminal ${segment.destinationTerminal}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryStart,
                  ),
                ),
              Text(
                'Arrival',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Layover row ────────────────────────────────────────────────────────────

class _LayoverRow extends StatelessWidget {
  final String arr;
  final String dep;
  final bool isDark;

  const _LayoverRow(
      {required this.arr, required this.dep, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Duration layover = Duration.zero;
    try {
      layover = DateTime.parse(dep).difference(DateTime.parse(arr));
    } catch (_) {}
    final h = layover.inHours;
    final m = layover.inMinutes.remainder(60);
    final label = h > 0 ? '${h}h ${m}m layover' : '${m}m layover';

    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, color: AppColors.warning, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

class _RoutePoint extends StatelessWidget {
  final String code;
  final String city;
  final CrossAxisAlignment align;
  const _RoutePoint(
      {required this.code, required this.city, required this.align});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppSizes.fontDisplay,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            )),
        Text(city,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: AppSizes.fontSM,
            )),
      ],
    );
  }
}

class _WhiteDashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset((x + 4).clamp(0, size.width), size.height / 2), paint);
      x += 8;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _Section(
      {required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? null
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final bool isDark;

  const _PriceRow(
      {required this.label,
        required this.amount,
        required this.currency,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              )),
          const Spacer(),
          Text('$currency ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              )),
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool positive, isDark;

  const _PolicyRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: positive
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: positive ? AppColors.success : AppColors.warning,
              size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  )),
              Text(value,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmItem extends StatelessWidget {
  final String label, value;
  final bool isDark, highlight;

  const _ConfirmItem({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            )),
        const SizedBox(height: 4),
        highlight
            ? ShaderMask(
          shaderCallback: (b) =>
              AppColors.primaryGradient.createShader(b),
          child: Text(value,
              style: const TextStyle(
                fontSize: AppSizes.fontLG,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )),
        )
            : Text(value,
            style: TextStyle(
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            )),
      ],
    );
  }
}

// ── Amenity item data class ────────────────────────────────────────────────

class _AmenityItem {
  final IconData icon;
  final String label;
  final String value;
  final bool positive;
  const _AmenityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.positive,
  });
}

// ── CO₂ row ────────────────────────────────────────────────────────────────

class _Co2Row extends StatelessWidget {
  final String kg;
  final bool isDark;
  const _Co2Row({required this.kg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.eco_rounded, color: AppColors.success, size: 15),
          const SizedBox(width: 6),
          Text(
            'CO₂ emissions',
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            '~$kg kg',
            style: const TextStyle(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Airline segment card (used in Airline & Flight Info section) ───────────

class _AirlineSegmentCard extends StatelessWidget {
  final FlightSegment segment;
  final bool isDark;
  const _AirlineSegmentCard({required this.segment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mc = segment.marketingCarrier;
    final oc = segment.operatingCarrier;
    final isDifferentOperator =
        mc != null && oc != null && mc.iataCode != oc.iataCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Marketing carrier ─────────────────────────────────────────────
        if (mc != null)
          _CarrierRow(
            carrier: mc,
            label: isDifferentOperator ? 'Marketing Carrier' : 'Airline',
            flightNumber: segment.flightNumber,
            isDark: isDark,
          ),

        // ── Operating carrier (only when different) ───────────────────────
        if (isDifferentOperator && oc != null) ...[
          const SizedBox(height: 10),
          _CarrierRow(
            carrier: oc,
            label: 'Operated by',
            flightNumber: null,
            isDark: isDark,
            isSecondary: true,
          ),
        ],

        const SizedBox(height: 14),

        // ── Route row ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Origin
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(segment.origin.iataCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            )),
                        Text(segment.origin.cityName,
                            style: TextStyle(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                        if ((segment.origin.airportName ?? '').isNotEmpty)
                          Text(segment.origin.airportName!,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        if (segment.originTerminal != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              AppColors.primaryStart.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Terminal ${segment.originTerminal}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryStart,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Arrow + duration
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Icon(Icons.flight_rounded,
                            color: AppColors.primaryStart, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          _fmtDur(segment.duration),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryStart,
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
                        Text(segment.destination.iataCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            )),
                        Text(segment.destination.cityName,
                            style: TextStyle(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                        if ((segment.destination.airportName ?? '').isNotEmpty)
                          Text(segment.destination.airportName!,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        if (segment.destinationTerminal != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              AppColors.primaryStart.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Terminal ${segment.destinationTerminal}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryStart,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Conditions of carriage link ───────────────────────────
              if ((mc?.conditionsOfCarriageUrl ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // TODO: launch url — add url_launcher package
                    // launchUrl(Uri.parse(mc!.conditionsOfCarriageUrl!));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          size: 13, color: AppColors.primaryStart),
                      const SizedBox(width: 5),
                      Text(
                        'Conditions of Carriage',
                        style: TextStyle(
                          fontSize: AppSizes.fontSM,
                          color: AppColors.primaryStart,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryStart,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _fmtDur(String iso) {
    try {
      final h =
          int.tryParse(RegExp(r'(\d+)H').firstMatch(iso)?.group(1) ?? '0') ?? 0;
      final m =
          int.tryParse(RegExp(r'(\d+)M').firstMatch(iso)?.group(1) ?? '0') ?? 0;
      if (h == 0) return '${m}m';
      if (m == 0) return '${h}h';
      return '${h}h ${m}m';
    } catch (_) {
      return iso;
    }
  }
}

// ── Carrier row (logo + name + flight number badge) ───────────────────────

class _CarrierRow extends StatelessWidget {
  final dynamic carrier; // AirlineInfo / carrier object
  final String label;
  final String? flightNumber;
  final bool isDark;
  final bool isSecondary;

  const _CarrierRow({
    required this.carrier,
    required this.label,
    required this.flightNumber,
    required this.isDark,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final logoUrl = carrier.logoUrl as String? ?? '';
    final name = carrier.name as String? ?? '';
    final iata = carrier.iataCode as String? ?? '';

    return Row(
      children: [
        // Logo
        Container(
          width: isSecondary ? 40 : 48,
          height: isSecondary ? 40 : 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: isDark
                ? null
                : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: _AirlineLogo(
            logoUrl: logoUrl,
            size: isSecondary ? 20 : 24,
            fallbackIcon: Icons.airlines_rounded,
          ),
        ),
        const SizedBox(width: 12),
        // Name + label
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
              const SizedBox(height: 1),
              Text(name,
                  style: TextStyle(
                    fontSize: isSecondary ? AppSizes.fontSM : AppSizes.fontMD,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  )),
              if (iata.isNotEmpty)
                Text(iata,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    )),
            ],
          ),
        ),
        // Flight number badge
        if (flightNumber != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.primaryStart.withValues(alpha: 0.2)),
            ),
            child: Text(
              '$iata$flightNumber',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryStart,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

// ── SVG-aware airline logo widget ────────────────────────────────────────────

class _AirlineLogo extends StatelessWidget {
  final String logoUrl;
  final double size;
  final IconData fallbackIcon;

  const _AirlineLogo({
    required this.logoUrl,
    required this.size,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isEmpty) {
      return Icon(fallbackIcon, color: AppColors.primaryStart, size: size);
    }
    final isSvg = logoUrl.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return SvgPicture.network(
        logoUrl,
        key: ValueKey(logoUrl),
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.primaryStart,
            ),
          ),
        ),
      );
    }
    return Image.network(
      logoUrl,
      key: ValueKey(logoUrl),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(fallbackIcon, color: AppColors.primaryStart, size: size),
    );
  }
}