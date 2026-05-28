// lib/features/payment/screens/payment_success_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../models/payment_model.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late AnimationController _contentController;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _contentSlide;

  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Check animation
    _checkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    _checkOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _checkController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    // Confetti
    _confettiController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    // Content slide in
    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    // Generate confetti particles
    final rng = math.Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.6,
        color: [
          AppColors.primaryStart,
          AppColors.primaryEnd,
          AppColors.accentGold,
          AppColors.accent,
          const Color(0xFF34D399),
          Colors.white,
        ][rng.nextInt(6)],
        size: 4 + rng.nextDouble() * 8,
        rotation: rng.nextDouble() * math.pi * 2,
        isCircle: rng.nextBool(),
      ));
    }

    // Start sequence
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _checkController.forward();
        _confettiController.forward();
      }
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _generateBookingRef() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    return 'WDL-${List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join()}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booking =
    ModalRoute.of(context)?.settings.arguments as BookingItem?;
    final bookingRef = _generateBookingRef();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // ── Confetti layer ────────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) => CustomPaint(
                painter:
                _ConfettiPainter(_particles, _confettiController.value),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top spacing + close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                            AppRoutes.home, (_) => false),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightInputBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),

                        // ── Animated check circle ─────────────────────────
                        ScaleTransition(
                          scale: _checkScale,
                          child: FadeTransition(
                            opacity: _checkOpacity,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryStart
                                        .withOpacity(0.5),
                                    blurRadius: 32,
                                    spreadRadius: 4,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 52),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Success text ──────────────────────────────────
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _contentSlide.value),
                            child: Opacity(
                              opacity: _contentController.value,
                              child: child,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Payment Successful! 🎉',
                                style: TextStyle(
                                  fontSize: AppSizes.fontXXL,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your booking is confirmed.\nHave a wonderful journey!',
                                style: TextStyle(
                                  fontSize: AppSizes.fontMD,
                                  height: 1.5,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Booking reference card ────────────────────────
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (_, child) => Transform.translate(
                            offset:
                            Offset(0, _contentSlide.value * 1.4),
                            child: Opacity(
                              opacity: _contentController.value,
                              child: child,
                            ),
                          ),
                          child: _buildBookingRefCard(
                              isDark, bookingRef, booking),
                        ),

                        const SizedBox(height: 20),

                        // ── What's next section ───────────────────────────
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (_, child) => Transform.translate(
                            offset:
                            Offset(0, _contentSlide.value * 1.8),
                            child: Opacity(
                              opacity: _contentController.value,
                              child: child,
                            ),
                          ),
                          child: _buildWhatsNext(isDark),
                        ),

                        const SizedBox(height: 32),

                        // ── Action buttons ────────────────────────────────
                        AnimatedBuilder(
                          animation: _contentController,
                          builder: (_, child) => Opacity(
                            opacity: _contentController.value,
                            child: child,
                          ),
                          child: _buildActions(context, isDark),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingRefCard(
      bool isDark, String ref, BookingItem? booking) {
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
            color: AppColors.primaryStart.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryStart.withOpacity(0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLarge),
                topRight: Radius.circular(AppSizes.radiusLarge),
              ),
            ),
            child: Row(
              children: [
                Text(booking?.emoji ?? '✈️',
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking?.title ?? 'Your Booking',
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        booking?.subtitle ?? '',
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
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Booking reference
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                    BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Booking Reference',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: AppSizes.fontXS,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppSizes.fontXXL,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Details grid
                Row(
                  children: [
                    _RefDetail(
                        label: 'Date',
                        value: 'Jun 15, 2025',
                        isDark: isDark),
                    _VerticalDivider(isDark: isDark),
                    _RefDetail(
                        label: 'Amount',
                        value:
                        '\$${booking?.total.toStringAsFixed(2) ?? '0.00'}',
                        isDark: isDark,
                        highlight: true),
                    _VerticalDivider(isDark: isDark),
                    _RefDetail(
                        label: 'Status',
                        value: 'Confirmed',
                        isDark: isDark,
                        isStatus: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNext(bool isDark) {
    final steps = [
      {
        'icon': Icons.email_outlined,
        'title': 'Confirmation Email',
        'desc': 'Check your inbox for booking details and e-ticket',
      },
      {
        'icon': Icons.qr_code_rounded,
        'title': 'E-Ticket',
        'desc': 'Your boarding pass will be available 24h before departure',
      },
      {
        'icon': Icons.notifications_active_rounded,
        'title': 'Flight Updates',
        'desc': 'We\'ll notify you of any gate changes or delays',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
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
              "What's Next",
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ]),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                    Icon(s['icon'] as IconData, color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String,
                            style: TextStyle(
                              fontSize: AppSizes.fontSM,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            )),
                        Text(s['desc'] as String,
                            style: TextStyle(
                              fontSize: AppSizes.fontXS,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool isDark) {
    return Column(
      children: [
        // View booking CTA
        GestureDetector(
          onTap: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          child: Container(
            height: AppSizes.buttonHeight,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Back to Home',
                      style: TextStyle(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Share button
        GestureDetector(
          onTap: () {},
          child: Container(
            height: AppSizes.buttonHeight,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.share_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      size: 20),
                  const SizedBox(width: 8),
                  Text('Share Booking',
                      style: TextStyle(
                        fontSize: AppSizes.fontMD,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RefDetail extends StatelessWidget {
  final String label, value;
  final bool isDark, highlight, isStatus;
  const _RefDetail({
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
    this.isStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              )),
          const SizedBox(height: 3),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('✓ Confirmed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  )),
            )
          else if (highlight)
            ShaderMask(
              shaderCallback: (b) =>
                  AppColors.primaryGradient.createShader(b),
              child: Text(value,
                  style: const TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
            )
          else
            Text(value,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double delay;
  final Color color;
  final double size;
  final double rotation;
  final bool isCircle;
  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
    required this.rotation,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final y = t * size.height * 1.2;
      final x = p.x * size.width +
          math.sin(t * math.pi * 3 + p.rotation) * 30;
      final opacity = (1 - (t * 0.8)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + t * math.pi * 4);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
