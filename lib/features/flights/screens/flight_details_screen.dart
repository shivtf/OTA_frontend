// lib/features/flights/screens/flight_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../auth/widgets/gradient_button.dart';
import '../models/flight_model.dart';

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = ModalRoute.of(context)!.settings.arguments as FlightModel?
        ?? FlightData.search(from: 'DEL', to: 'DXB').first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

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
                  child: _buildHeader(context, flight, isDark, tc)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFlightTimeline(flight, isDark),
                      const SizedBox(height: 20),
                      _buildInfoGrid(flight, isDark),
                      const SizedBox(height: 20),
                      _buildAmenitiesSection(flight, isDark),
                      const SizedBox(height: 20),
                      _buildPriceBreakdown(flight, isDark),
                      const SizedBox(height: 20),
                      _buildPolicies(flight, isDark),
                      const SizedBox(height: 32),
                      _buildBookButton(context, flight, isDark),
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

  Widget _buildHeader(BuildContext context, FlightModel flight, bool isDark,
      ThemeController tc) {
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
                  CustomBackButton(useLightStyle: true),
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
                            ? Colors.white.withValues(alpha:0.3)
                            : Colors.white.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color:
                        _isFavorited ? AppColors.accent : Colors.white,
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
                        color: Colors.white.withValues(alpha:0.15),
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

              // Big route display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _RoutePoint(
                      code: flight.from, city: flight.fromCity, align: CrossAxisAlignment.start),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          flight.duration,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.8),
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
                              child: CustomPaint(
                                  painter: _WhiteDashPainter()),
                            ),
                            const Icon(Icons.flight_rounded,
                                color: Colors.white, size: 20),
                            Expanded(
                              child: CustomPaint(
                                  painter: _WhiteDashPainter()),
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
                            color: flight.stops == 0
                                ? AppColors.success.withValues(alpha:0.25)
                                : AppColors.warning.withValues(alpha:0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            flight.stops == 0 ? 'Non-stop' : '${flight.stops} stop',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: flight.stops == 0
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoutePoint(
                      code: flight.to, city: flight.toCity, align: CrossAxisAlignment.end),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlightTimeline(FlightModel flight, bool isDark) {
    return _Section(
      title: 'Journey Timeline',
      isDark: isDark,
      child: Column(
        children: [
          _TimelineItem(
            time: flight.departure,
            code: flight.from,
            city: flight.fromCity,
            label: 'Departure',
            isFirst: true,
            isDark: isDark,
          ),
          if (flight.stops > 0)
            _TimelineItem(
              time: '12:00',
              code: 'DOH',
              city: 'Doha',
              label: 'Transit · 1h 30m layover',
              isFirst: false,
              isDark: isDark,
              isTransit: true,
            ),
          _TimelineItem(
            time: flight.arrival,
            code: flight.to,
            city: flight.toCity,
            label: 'Arrival',
            isFirst: false,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(FlightModel flight, bool isDark) {
    final items = [
      {'icon': Icons.airplanemode_active_rounded, 'label': 'Aircraft', 'value': flight.aircraft},
      {'icon': Icons.airline_seat_recline_extra_rounded, 'label': 'Cabin', 'value': flight.cabin},
      {'icon': Icons.event_seat_rounded, 'label': 'Seats Left', 'value': '${flight.seatsLeft} available'},
      {'icon': Icons.star_rounded, 'label': 'Rating', 'value': '${flight.rating} / 5.0'},
    ];

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

  Widget _buildAmenitiesSection(FlightModel flight, bool isDark) {
    return _Section(
      title: 'Amenities',
      isDark: isDark,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: flight.amenities.map((a) {
          IconData icon;
          if (a.contains('Meal')) icon = Icons.restaurant_rounded;
          else if (a.contains('Wi-Fi')) icon = Icons.wifi_rounded;
          else if (a.contains('Entertainment')) icon = Icons.tv_rounded;
          else if (a.contains('USB')) icon = Icons.usb_rounded;
          else if (a.contains('Baggage')) icon = Icons.luggage_rounded;
          else if (a.contains('Blanket')) icon = Icons.airline_seat_flat_rounded;
          else icon = Icons.check_circle_rounded;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withValues(alpha:0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.primaryStart.withValues(alpha:0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primaryStart, size: 15),
                const SizedBox(width: 6),
                Text(
                  a,
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceBreakdown(FlightModel flight, bool isDark) {
    final base = flight.price;
    final tax = (base * 0.12).roundToDouble();
    final fee = 15.0;
    final total = base + tax + fee;

    return _Section(
      title: 'Price Breakdown',
      isDark: isDark,
      child: Column(
        children: [
          _PriceRow(label: 'Base fare (1 adult)', amount: base, isDark: isDark),
          _PriceRow(label: 'Taxes & fees (12%)', amount: tax, isDark: isDark),
          _PriceRow(label: 'Service fee', amount: fee, isDark: isDark),
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
                  '\$${total.toInt()}',
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

  Widget _buildPolicies(FlightModel flight, bool isDark) {
    return _Section(
      title: 'Policies',
      isDark: isDark,
      child: Column(
        children: [
          _PolicyRow(
            icon: Icons.replay_rounded,
            label: 'Cancellation',
            value: flight.isRefundable
                ? 'Free cancellation up to 24h before'
                : 'Non-refundable',
            positive: flight.isRefundable,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _PolicyRow(
            icon: Icons.edit_calendar_rounded,
            label: 'Date Change',
            value: 'Fee applies (min \$50)',
            positive: false,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _PolicyRow(
            icon: Icons.luggage_rounded,
            label: 'Baggage',
            value: '1 cabin bag + 1 checked (included)',
            positive: true,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, FlightModel flight, bool isDark) {
    return Column(
      children: [
        Row(
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
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: Text(
                    '\$${(flight.price * 1.12 + 15).toInt()}',
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
                onPressed: () => _showBookingConfirm(context, flight, isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showBookingConfirm(
      BuildContext context, FlightModel flight, bool isDark) {
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
                color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${flight.from} → ${flight.to}  ·  ${flight.airline}',
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
                color: isDark
                    ? AppColors.darkInputBg
                    : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ConfirmItem(label: 'Departure', value: flight.departure, isDark: isDark),
                  _ConfirmItem(label: 'Arrival', value: flight.arrival, isDark: isDark),
                  _ConfirmItem(
                    label: 'Total',
                    value: '\$${(flight.price * 1.12 + 15).toInt()}',
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
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

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
              color: Colors.white.withValues(alpha:0.75),
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
      ..color = Colors.white.withValues(alpha:0.5)
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
            color: Colors.black.withValues(alpha:0.04),
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

class _TimelineItem extends StatelessWidget {
  final String time, code, city, label;
  final bool isFirst, isDark;
  final bool isTransit;

  const _TimelineItem({
    required this.time,
    required this.code,
    required this.city,
    required this.label,
    required this.isFirst,
    required this.isDark,
    this.isTransit = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot + line
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    gradient: isTransit ? null : AppColors.primaryGradient,
                    color: isTransit ? AppColors.warning : null,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!isFirst || isTransit)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.primaryStart.withValues(alpha:0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style: TextStyle(
                        fontSize: AppSizes.fontLG,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      )),
                  Text('$code · $city',
                      style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                  Text(label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isTransit
                            ? AppColors.warning
                            : AppColors.primaryStart,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDark;

  const _PriceRow(
      {required this.label, required this.amount, required this.isDark});

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
          Text('\$${amount.toInt()}',
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
                ? AppColors.success.withValues(alpha:0.1)
                : AppColors.warning.withValues(alpha:0.1),
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