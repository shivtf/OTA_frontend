// lib/features/auth/screens/email_verified_screen.dart
//
// This screen is opened via deep link:  otaapp://auth/verified?status=success
// or                                    otaapp://auth/verified?status=error&message=...
//
// Register the route in AppRoutes as:  static const String emailVerified = '/auth/email-verified';
// And pass args: {'status': 'success'} or {'status': 'error', 'message': '...'}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';

class EmailVerifiedScreen extends StatefulWidget {
  const EmailVerifiedScreen({super.key});

  @override
  State<EmailVerifiedScreen> createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends State<EmailVerifiedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _iconController;
  late final AnimationController _contentController;
  late final AnimationController _particleController;

  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _ringScale;
  late final Animation<double> _contentSlide;
  late final Animation<double> _contentFade;
  late final Animation<double> _btnSlide;

  bool _isSuccess = true;
  String _errorMessage = '';
  final List<_Particle> _particles = [];
  int _countdown = 5;
  bool _counting = false;

  @override
  void initState() {
    super.initState();

    // Background shimmer
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Icon bounce in
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );
    _iconOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _ringScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    // Content slide up
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _btnSlide = Tween<double>(begin: 60, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Confetti particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate particles
    final rng = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _Particle(
          x: rng.nextDouble(),
          speed: 0.3 + rng.nextDouble() * 0.7,
          size: 4.0 + rng.nextDouble() * 6.0,
          color: _particleColors[rng.nextInt(_particleColors.length)],
          angle: rng.nextDouble() * 2 * math.pi,
          rotationSpeed: (rng.nextDouble() - 0.5) * 6,
        ),
      );
    }

    // Sequence animations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _iconController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _contentController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_isSuccess) _particleController.forward();
    });
  }

  static const List<Color> _particleColors = [
    AppColors.primaryStart,
    AppColors.primaryEnd,
    AppColors.accentGold,
    AppColors.accent,
    Color(0xFF4CAF82),
    Color(0xFF29B6F6),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _isSuccess = (args['status'] as String?) == 'success';
      _errorMessage = args['message'] as String? ??
          'Verification failed. Please try again.';
    }
    if (_isSuccess && !_counting) {
      _counting = true;
      _startCountdown();
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown > 0) {
        _startCountdown();
      } else {
        _goToLogin();
      }
    });
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _iconController.dispose();
    _contentController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _iconController,
          _contentController,
          _particleController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Animated gradient background ──────────────────────────
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isSuccess
                        ? [
                            Color.lerp(
                              const Color(0xFF0D0B1A),
                              const Color(0xFF1A0D3E),
                              _bgController.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF1A0D3E),
                              const Color(0xFF2D1B6E),
                              _bgController.value,
                            )!,
                            Color.lerp(
                              const Color(0xFF4A1FA8),
                              const Color(0xFF6C3CE1),
                              _bgController.value,
                            )!,
                          ]
                        : [
                            const Color(0xFF0D0B1A),
                            const Color(0xFF1A0A1A),
                            const Color(0xFF3D1020),
                          ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // ── Confetti particles (success only) ─────────────────────
              if (_isSuccess)
                ..._particles.map((p) {
                  final progress = _particleController.value * p.speed;
                  if (progress <= 0) return const SizedBox.shrink();
                  final y = -0.1 + progress * 1.3;
                  final x = p.x + math.sin(p.angle + progress * 4) * 0.05;
                  final rotation = p.rotationSpeed * progress;
                  return Positioned(
                    left: x * size.width,
                    top: y * size.height,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Opacity(
                        opacity: (1.0 - progress * 0.8).clamp(0.0, 1.0),
                        child: Container(
                          width: p.size,
                          height: p.size,
                          decoration: BoxDecoration(
                            color: p.color,
                            borderRadius: BorderRadius.circular(p.size * 0.2),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              // ── Glowing orbs ──────────────────────────────────────────
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (_isSuccess ? AppColors.primaryStart : AppColors.error)
                            .withOpacity(0.15 + _bgController.value * 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (_isSuccess ? AppColors.primaryEnd : AppColors.accent)
                            .withOpacity(0.12 + _bgController.value * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main content ──────────────────────────────────────────
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // ── Animated icon ──────────────────────────────
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer ring pulse
                              Transform.scale(
                                scale: _ringScale.value,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (_isSuccess
                                              ? AppColors.primaryEnd
                                              : AppColors.error)
                                          .withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Middle ring
                              Transform.scale(
                                scale: _ringScale.value * 0.85,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (_isSuccess
                                            ? AppColors.primaryStart
                                            : AppColors.error)
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ),
                              // Icon circle
                              FadeTransition(
                                opacity: _iconOpacity,
                                child: ScaleTransition(
                                  scale: _iconScale,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: _isSuccess
                                            ? [
                                                AppColors.primaryStart,
                                                AppColors.primaryEnd,
                                              ]
                                            : [
                                                AppColors.error,
                                                const Color(0xFFFF8C8C),
                                              ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isSuccess
                                                  ? AppColors.primaryStart
                                                  : AppColors.error)
                                              .withOpacity(0.5),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isSuccess
                                          ? Icons.mark_email_read_rounded
                                          : Icons.error_outline_rounded,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Title & subtitle ───────────────────────────
                        Opacity(
                          opacity: _contentFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _contentSlide.value),
                            child: Column(
                              children: [
                                Text(
                                  _isSuccess
                                      ? '🎉 Email Verified!'
                                      : 'Verification Failed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSuccess
                                      ? 'Your account has been successfully\nverified. Welcome to Wanderly!'
                                      : _errorMessage,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_isSuccess) ...[
                                  const SizedBox(height: 24),
                                  // Verified badge chips
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildBadge(
                                        Icons.verified_user_rounded,
                                        'Verified',
                                      ),
                                      const SizedBox(width: 12),
                                      _buildBadge(
                                        Icons.security_rounded,
                                        'Secure',
                                      ),
                                      const SizedBox(width: 12),
                                      _buildBadge(
                                        Icons.flight_takeoff_rounded,
                                        'Ready',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── CTA button ─────────────────────────────────
                        Opacity(
                          opacity: _contentFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _btnSlide.value),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _goToLogin,
                                  child: Container(
                                    width: double.infinity,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryStart,
                                          AppColors.primaryEnd,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryStart
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.login_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isSuccess
                                              ? 'Continue to Login'
                                              : 'Back to Login',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isSuccess) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Redirecting in $_countdown seconds...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accentGold, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double speed;
  final double size;
  final Color color;
  final double angle;
  final double rotationSpeed;

  const _Particle({
    required this.x,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
    required this.rotationSpeed,
  });
}
