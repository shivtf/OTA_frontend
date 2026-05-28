// lib/features/payment/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../models/payment_model.dart';
import '../models/stripe_service.dart';
import '../widgets/card_from_widget.dart';
import '../widgets/order_summary_card.dart';
import '../widgets/saved_card_title.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  // Payment method selection
  int _selectedMethod = 0; // 0=saved, 1=new card, 2=stripe sheet
  String? _selectedCardId;
  PaymentStatus _status = PaymentStatus.idle;

  // Tab animation
  late AnimationController _tabAnim;

  // Card form key
  final _cardFormKey = GlobalKey<CardFormWidgetState>();

  // Dummy booking (in real app, passed via route arguments)
  final BookingItem _booking = const BookingItem(
    type: BookingType.flight,
    title: 'Emirates  DEL → DXB',
    subtitle: 'Jun 15, 2025  ·  1 Adult  ·  Economy',
    detail1Label: 'Departure',
    detail1Value: '08:30 AM',
    detail2Label: 'Arrival',
    detail2Value: '11:15 AM',
    basePrice: 542.00,
    taxAmount: 65.04,
    serviceFee: 15.00,
    emoji: '✈️',
  );

  final List<Map<String, dynamic>> _paymentMethods = [
    {'icon': Icons.credit_card_rounded, 'label': 'Saved Cards'},
    {'icon': Icons.add_card_rounded, 'label': 'New Card'},
    {'icon': Icons.payment_rounded, 'label': 'Stripe Pay'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCardId = dummySavedCards.first.id;
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _tabAnim.forward();
  }

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  // Use route arguments if passed
  BookingItem _getBooking(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is BookingItem) return args;
    return _booking;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();
    final booking = _getBooking(context);

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark, tc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order summary
                    OrderSummaryCard(booking: booking, isDark: isDark),
                    const SizedBox(height: 24),

                    // Secure payment badge
                    _buildSecureBadge(isDark),
                    const SizedBox(height: 20),

                    // Payment method tabs
                    _buildMethodTabs(isDark),
                    const SizedBox(height: 20),

                    // Payment method content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_selectedMethod),
                        child: _buildMethodContent(isDark),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Pay button
                    _buildPayButton(context, booking, isDark),

                    const SizedBox(height: 16),

                    // Security note
                    _buildSecurityNote(isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isDark, ThemeController tc) {
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
                Text('Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppSizes.fontXXL,
                      fontWeight: FontWeight.w800,
                    )),
                Text('Complete your payment securely',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppSizes.fontSM,
                    )),
              ],
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
    );
  }

  Widget _buildSecureBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppColors.success.withValues(alpha:0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Secured by Stripe  ·  256-bit SSL encryption  ·  PCI DSS compliant',
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
        children: List.generate(_paymentMethods.length, (i) {
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
                      color: AppColors.primaryStart.withValues(alpha:0.3),
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
                      _paymentMethods[i]['icon'] as IconData,
                      size: 15,
                      color: isActive
                          ? Colors.white
                          : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _paymentMethods[i]['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
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

  Widget _buildMethodContent(bool isDark) {
    switch (_selectedMethod) {
      case 0:
        return _buildSavedCards(isDark);
      case 1:
        return _buildNewCardForm(isDark);
      case 2:
        return _buildStripeSheet(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSavedCards(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Saved Cards',
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...dummySavedCards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SavedCardTile(
            card: card,
            isSelected: _selectedCardId == card.id,
            isDark: isDark,
            onTap: () => setState(() => _selectedCardId = card.id),
          ),
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _selectedMethod = 1),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.primaryStart, width: 1.5),
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
        Text(
          'Enter Card Details',
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        CardFormWidget(
          formKey: _cardFormKey,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStripeSheet(bool isDark) {
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
                  color: AppColors.primaryStart.withValues(alpha:0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: const Icon(Icons.payment_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Stripe Payment Sheet',
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
            'Tap "Pay Now" below to open the Stripe-hosted payment sheet. Supports cards, Google Pay, and more.',
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
          // Supported methods chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: ['Visa', 'Mastercard', 'Google Pay', 'Amex']
                .map((m) => Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryStart.withValues(alpha:0.2)),
              ),
              child: Text(m,
                  style: const TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryStart,
                  )),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(
      BuildContext context, BookingItem booking, bool isDark) {
    final isProcessing = _status == PaymentStatus.processing;

    return GestureDetector(
      onTap: isProcessing ? null : () => _handlePayment(context, booking),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          gradient:
          isProcessing ? null : AppColors.primaryGradient,
          color: isProcessing
              ? (isDark ? AppColors.darkCard : AppColors.lightInputBg)
              : null,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: isProcessing
              ? null
              : [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha:0.45),
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
                'Processing payment...',
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
                'Pay  \$${booking.total.toStringAsFixed(2)}',
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

  Widget _buildSecurityNote(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_rounded,
            size: 13,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
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
      BuildContext context, BookingItem booking) async {
    // Validate new card form if selected
    if (_selectedMethod == 1) {
      if (_cardFormKey.currentState == null ||
          !_cardFormKey.currentState!.validate()) {
        _showError(context, 'Please fill in all card details correctly.');
        return;
      }
    }

    setState(() => _status = PaymentStatus.processing);

    bool success = false;

    if (_selectedMethod == 2) {
      // Stripe payment sheet flow
      success = await StripeService.instance.processPayment(
        amount: booking.total,
        currency: 'usd',
        customerEmail: 'traveler@wanderly.app',
        description: booking.title,
      );
    } else {
      // Simulate card payment processing
      await Future.delayed(const Duration(milliseconds: 2200));
      success = true; // always succeed in demo
    }

    if (!mounted) return;

    setState(() => _status =
    success ? PaymentStatus.success : PaymentStatus.failed);

    if (success) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.paymentSuccess,
        arguments: booking,
      );
    } else {
      setState(() => _status = PaymentStatus.idle);
      _showError(context, 'Payment failed. Please try again.');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
