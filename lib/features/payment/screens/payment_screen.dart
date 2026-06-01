// lib/features/payment/screens/payment_screen.dart
//
// Production-ready Payment Screen for Wanderly OTA.
//
// ╔══════════════════════════════════════════════════════════════════╗
// ║  This file is 100% payment-provider-agnostic.                   ║
// ║  Switching from Stripe → Duffel requires ONLY:                   ║
// ║                                                                  ║
// ║    AppConfig.paymentGateway = PaymentGateway.duffel;             ║
// ║                                                                  ║
// ║  No UI changes. No business logic changes. No screen rewrite.   ║
// ╚══════════════════════════════════════════════════════════════════╝
//
// Displays:
//   • Booking Summary   — flight info, passenger details
//   • Price Breakdown   — base, taxes, fees, total
//   • Payment Methods   — saved cards, new card, provider sheet
//   • Payment Status    — loading / success / failure / retry
//   • Confirm & Pay     — single CTA button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../../core/services/flight_service.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../models/payment_result.dart';
import '../widgets/booking_summary_card.dart';
import '../widgets/card_from_widget.dart';
import '../widgets/payment_status_overlay.dart';
import '../widgets/saved_card_title.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  // ── Payment method selection ─────────────────────────────────────────────
  // 0 = saved cards  |  1 = new card  |  2 = provider sheet
  int _selectedMethod = 0;
  String? _selectedCardId;

  // ── UI state ─────────────────────────────────────────────────────────────
  late AnimationController _entranceAnim;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  final _cardFormKey = GlobalKey<CardFormWidgetState>();

  // ── Fallback booking (used only if no route arguments provided) ──────────
  static const BookingItem _demoBooking = BookingItem(
    type: BookingType.flight,
    title: 'Emirates  DEL → DXB',
    subtitle: 'Jun 15, 2025  ·  1 Adult  ·  Economy',
    detail1Label: 'Departure',
    detail1Value: '08:30 AM',
    detail2Label: 'Arrival',
    detail2Value: '11:15 AM',
    basePrice: 542.00,
    taxAmount: 65.04,
    // serviceFee: 15.00,
    emoji: '✈️',
    bookingId: 'demo-booking-001',
    currency: 'USD',
    passengers: [
      PassengerSummary(name: 'John Traveler', type: 'adult'),
    ],
  );

  final List<_PaymentMethodTab> _tabs = const [
    _PaymentMethodTab(icon: Icons.credit_card_rounded, label: 'Saved'),
    _PaymentMethodTab(icon: Icons.add_card_rounded, label: 'New Card'),
    _PaymentMethodTab(icon: Icons.payment_rounded, label: 'Pay Sheet'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCardId = dummySavedCards.first.id;

    // Entrance animation
    _entranceAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceAnim, curve: Curves.easeOut));

    // Initialise the payment controller (idempotent)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentController>().initialize();
      _entranceAnim.forward();
    });
  }

  @override
  void dispose() {
    _entranceAnim.dispose();
    super.dispose();
  }

  BookingItem _booking(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    // Direct BookingItem — hotel/car flows already build this themselves
    if (args is BookingItem) return args;

    // Map from PassengerFormScreen:
    //   { 'booking': FlightBooking, 'offer': FlightOffer, 'passengers': List<PassengerInput> }
    if (args is Map) {
      try {
        final dynamic rawBooking = args['booking'];
        final dynamic rawOffer = args['offer'];
        final dynamic rawPassengers =
            args['passengers']; // List<PassengerInput>

        if (rawOffer == null) return _demoBooking;

        final FlightOffer offer = rawOffer as FlightOffer;
        final FlightBooking? booking = rawBooking as FlightBooking?;

        // ── Pricing: prefer the confirmed booking price (post-API),
        //    fall back to the offer price if booking is missing.
        final pricing = booking?.pricing ?? offer.pricing;

        // ── Passenger display names from the real form input
        List<PassengerSummary> passengers = const [];
        if (rawPassengers is List && rawPassengers.isNotEmpty) {
          passengers = rawPassengers.asMap().entries.map((e) {
            final dynamic p = e.value;
            final String first = (p.firstName as String?)?.trim() ?? '';
            final String last = (p.lastName as String?)?.trim() ?? '';
            final String name = (first.isNotEmpty || last.isNotEmpty)
                ? '$first $last'.trim()
                : 'Passenger ${e.key + 1}';
            final String type = (p.type as String?) ?? 'adult';
            return PassengerSummary(name: name, type: type);
          }).toList();
        } else {
          // Fallback: derive from offer passenger types (no names)
          passengers = offer.passengers.asMap().entries.map((e) {
            final type = e.value.type;
            final label = type == 'adult'
                ? 'Adult ${e.key + 1}'
                : type == 'child'
                    ? 'Child ${e.key + 1}'
                    : 'Infant ${e.key + 1}';
            return PassengerSummary(name: label, type: type);
          }).toList();
        }

        // ── Time helpers
        String fmtTime(String iso) {
          try {
            final dt = DateTime.parse(iso).toLocal();
            final h = dt.hour.toString().padLeft(2, '0');
            final m = dt.minute.toString().padLeft(2, '0');
            final ampm = dt.hour < 12 ? 'AM' : 'PM';
            final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
            return '$h12:${m.padLeft(2, '0')} $ampm';
          } catch (_) {
            return iso;
          }
        }

        String fmtDate(String iso) {
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
            return '${months[dt.month]} ${dt.day}, ${dt.year}';
          } catch (_) {
            return iso;
          }
        }

        final slice = offer.outbound;
        final depTime = slice.segments.isNotEmpty
            ? fmtTime(slice.segments.first.departingAt)
            : '—';
        final arrTime = slice.segments.isNotEmpty
            ? fmtTime(slice.segments.last.arrivingAt)
            : '—';
        final depDate = slice.segments.isNotEmpty
            ? fmtDate(slice.segments.first.departingAt)
            : '';

        final paxCount = passengers.length;
        final paxLabel = paxCount == 1 ? '1 Adult' : '$paxCount Adults';

        return BookingItem.fromFlightBooking(
          bookingId: booking?.bookingId ?? '',
          baseAmount: pricing.baseAmount,
          taxAmount: pricing.taxAmount,
          // serviceFee: 15.00,
          currency: pricing.totalCurrency,
          flightTitle:
              '${offer.airline}  ${slice.origin.iataCode} → ${slice.destination.iataCode}',
          flightSubtitle: '$depDate  ·  $paxLabel  ·  ${offer.cabinClass}',
          departureTime: depTime,
          arrivalTime: arrTime,
          duffelOfferId: offer.offerId,
          passengers: passengers,
        );
      } catch (e) {
        // Casting failed — show demo so screen isn't blank
        return _demoBooking;
      }
    }

    return _demoBooking;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();
    final ctrl = context.watch<PaymentController>();
    final booking = _booking(context);
    final screenState = ctrl.screenState;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main scrollable content ────────────────────────────────
            Column(
              children: [
                _buildHeader(context, isDark, tc, ctrl),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking summary card
                            BookingSummaryCard(
                              booking: booking,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 24),

                            // Security badge (provider-aware label)
                            _buildSecurityBadge(ctrl, isDark),
                            const SizedBox(height: 20),

                            // Payment method tabs
                            _buildMethodTabs(isDark),
                            const SizedBox(height: 20),

                            // Payment method content
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.04, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_selectedMethod),
                                child: _buildMethodContent(
                                    isDark, ctrl.providerName),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Confirm & Pay button
                            _buildPayButton(context, booking, ctrl, isDark),
                            const SizedBox(height: 14),

                            // Security footer note
                            _buildSecurityFooter(isDark),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Status overlays (sit above the content) ────────────────
            if (screenState == PaymentScreenState.processing)
              PaymentProcessingOverlay(providerName: ctrl.providerName),

            if (screenState == PaymentScreenState.success &&
                ctrl.lastResult != null)
              _FullOverlay(
                child: PaymentSuccessState(
                  result: ctrl.lastResult!,
                  onContinue: () =>
                      _navigateToSuccess(context, booking, ctrl.lastResult!),
                ),
              ),

            if (screenState == PaymentScreenState.failure &&
                ctrl.lastResult != null)
              _FullOverlay(
                child: PaymentFailureState(
                  result: ctrl.lastResult!,
                  retryCount: ctrl.retryCount,
                  maxRetries: 3,
                  onRetry: ctrl.canRetry
                      ? () => _doRetry(context, booking, ctrl)
                      : null,
                  onBack: () {
                    ctrl.reset();
                    Navigator.of(context).pop();
                  },
                ),
              ),

            if (screenState == PaymentScreenState.cancelled)
              _FullOverlay(
                child: PaymentCancelledState(
                  onTryAgain: () => ctrl.reset(),
                  onBack: () {
                    ctrl.reset();
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark, ThemeController tc,
      PaymentController ctrl) {
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          const CustomBackButton(useLightStyle: true),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Review and confirm your booking',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppSizes.fontSM,
                  ),
                ),
              ],
            ),
          ),
          // Theme toggle
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
    );
  }

  // ── Security badge ──────────────────────────────────────────────────────

  Widget _buildSecurityBadge(PaymentController ctrl, bool isDark) {
    final provider = ctrl.providerName;
    final label = provider == 'duffel'
        ? 'Secured by Duffel  ·  PCI DSS compliant  ·  256-bit SSL'
        : 'Secured by Stripe  ·  256-bit SSL encryption  ·  PCI DSS compliant';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontXS,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Method tabs ─────────────────────────────────────────────────────────

  Widget _buildMethodTabs(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _selectedMethod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMethod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: isActive ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                AppColors.primaryStart.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _tabs[i].icon,
                      size: 14,
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Method content ──────────────────────────────────────────────────────

  Widget _buildMethodContent(bool isDark, String providerName) {
    switch (_selectedMethod) {
      case 0:
        return _buildSavedCards(isDark);
      case 1:
        return _buildNewCardForm(isDark);
      case 2:
        return _buildProviderSheet(isDark, providerName);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSavedCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Your Saved Cards', isDark),
        const SizedBox(height: 12),
        ...dummySavedCards.map(
          (card) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SavedCardTile(
              card: card,
              isSelected: _selectedCardId == card.id,
              isDark: isDark,
              onTap: () => setState(() => _selectedCardId = card.id),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _selectedMethod = 1),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryStart, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primaryStart, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Add a new card',
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryStart,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewCardForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Enter Card Details', isDark),
        const SizedBox(height: 12),
        CardFormWidget(formKey: _cardFormKey, isDark: isDark),
      ],
    );
  }

  /// Provider-aware payment sheet panel.
  /// The text adapts to Stripe vs Duffel, but the layout is identical.
  Widget _buildProviderSheet(bool isDark, String providerName) {
    final isDuffel = providerName == 'duffel';

    final title = isDuffel ? 'Duffel Secure Payment' : 'Stripe Payment Sheet';
    final description = isDuffel
        ? 'Tap "Confirm & Pay" to complete your booking directly through Duffel\'s secure payment system.'
        : 'Tap "Confirm & Pay" to open the Stripe-hosted payment sheet. Supports cards, Google Pay, and more.';
    final methods = isDuffel
        ? ['Visa', 'Mastercard', 'Amex']
        : ['Visa', 'Mastercard', 'Google Pay', 'Amex'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.payment_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
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
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: methods
                .map(
                  (m) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryStart.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      m,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Pay button ───────────────────────────────────────────────────────────

  Widget _buildPayButton(BuildContext context, BookingItem booking,
      PaymentController ctrl, bool isDark) {
    final isProcessing = ctrl.isProcessing;

    return GestureDetector(
      onTap: isProcessing ? null : () => _handlePayment(context, booking, ctrl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          gradient: isProcessing ? null : AppColors.primaryGradient,
          color: isProcessing
              ? (isDark ? AppColors.darkCard : AppColors.lightInputBg)
              : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: isProcessing
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                ],
        ),
        child: Center(
          child: isProcessing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.primaryStart,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Confirm & Pay  ${_formatTotal(booking)}',
                      style: const TextStyle(
                        fontSize: AppSizes.fontLG,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Security footer ──────────────────────────────────────────────────────

  Widget _buildSecurityFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield_rounded,
          size: 13,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        const SizedBox(width: 5),
        Text(
          'Your payment info is never stored on our servers',
          style: TextStyle(
            fontSize: AppSizes.fontXS,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }

  // ── Payment logic ─────────────────────────────────────────────────────────

  Future<void> _handlePayment(
    BuildContext context,
    BookingItem booking,
    PaymentController ctrl,
  ) async {
    // Validate new-card form if that tab is active
    if (_selectedMethod == 1) {
      if (_cardFormKey.currentState == null ||
          !_cardFormKey.currentState!.validate()) {
        _showSnackbar(context, 'Please fill in all card details correctly.',
            isError: true);
        return;
      }
    }

    await ctrl.processPayment(booking: booking);
    // The PaymentController notifies listeners → overlay drives UI.
    // Navigation to success screen is handled inside the overlay widget.
  }

  Future<void> _doRetry(
    BuildContext context,
    BookingItem booking,
    PaymentController ctrl,
  ) async {
    await ctrl.retry(booking: booking);
  }

  void _navigateToSuccess(
      BuildContext context, BookingItem booking, PaymentResult result) {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.paymentSuccess,
      arguments: {
        'booking': booking,
        'result': result,
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.fontMD,
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      );

  String _formatTotal(BookingItem b) {
    final symbol = b.currency.toUpperCase() == 'USD'
        ? '\$'
        : b.currency.toUpperCase() == 'EUR'
            ? '€'
            : b.currency.toUpperCase() == 'GBP'
                ? '£'
                : '${b.currency.toUpperCase()} ';
    return '$symbol${b.total.toStringAsFixed(2)}';
  }

  void _showSnackbar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.info_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.primaryStart,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── Full-screen overlay container ─────────────────────────────────────────────

class _FullOverlay extends StatelessWidget {
  final Widget child;
  const _FullOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: (isDark ? AppColors.darkBackground : AppColors.lightBackground),
      child: SafeArea(child: child),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _PaymentMethodTab {
  final IconData icon;
  final String label;
  const _PaymentMethodTab({required this.icon, required this.label});
}
