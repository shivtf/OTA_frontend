// lib/features/payment/widgets/payment_status_overlay.dart
//
// Full-screen overlay states for the payment flow:
//   • Processing  — animated spinner with provider name
//   • Success     — animated checkmark with booking reference
//   • Failure     — error card with retry option
//   • Cancelled   — soft dismissal state

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/payment_result.dart';

class PaymentProcessingOverlay extends StatefulWidget {
  final String providerName;

  const PaymentProcessingOverlay({
    super.key,
    required this.providerName,
  });

  @override
  State<PaymentProcessingOverlay> createState() =>
      _PaymentProcessingOverlayState();
}

class _PaymentProcessingOverlayState extends State<PaymentProcessingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  final List<String> _steps = [
    'Securing connection...',
    'Verifying booking...',
    'Processing payment...',
    'Confirming booking...',
  ];
  int _stepIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Cycle through steps
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return false;
      setState(() {
        _stepIndex = (_stepIndex + 1) % _steps.length;
      });
      return mounted;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
          .withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated glow ring
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Processing Payment',
              style: TextStyle(
                fontSize: AppSizes.fontXL,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_stepIndex],
                key: ValueKey(_stepIndex),
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryStart.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 13, color: AppColors.primaryStart),
                  const SizedBox(width: 6),
                  Text(
                    'Secured via ${widget.providerName[0].toUpperCase()}${widget.providerName.substring(1)}',
                    style: const TextStyle(
                      fontSize: AppSizes.fontXS,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success State ─────────────────────────────────────────────────────────────

class PaymentSuccessState extends StatefulWidget {
  final PaymentResult result;
  final VoidCallback onContinue;

  const PaymentSuccessState({
    super.key,
    required this.result,
    required this.onContinue,
  });

  @override
  State<PaymentSuccessState> createState() => _PaymentSuccessStateState();
}

class _PaymentSuccessStateState extends State<PaymentSuccessState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ref = widget.result.bookingReference ?? 'N/A';

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 52,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: AppSizes.fontXXL,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Your booking is confirmed. You\'re all set to fly!',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Booking reference chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  Text(
                    'Booking Reference',
                    style: TextStyle(
                      fontSize: AppSizes.fontXS,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    ref,
                    style: const TextStyle(
                      fontSize: AppSizes.fontLG,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryStart,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _GradientButton(
              label: 'View My Booking',
              icon: Icons.confirmation_number_rounded,
              onTap: widget.onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Failure State ─────────────────────────────────────────────────────────────

class PaymentFailureState extends StatelessWidget {
  final PaymentResult result;
  final VoidCallback? onRetry;
  final VoidCallback onBack;
  final int retryCount;
  final int maxRetries;

  const PaymentFailureState({
    super.key,
    required this.result,
    this.onRetry,
    required this.onBack,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canRetry = onRetry != null && retryCount < maxRetries;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_rounded,
              color: AppColors.error,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Failed',
            style: TextStyle(
              fontSize: AppSizes.fontXXL,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.errorMessage ??
                'Something went wrong. Please try again.',
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (result.errorCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Error: ${result.errorCode}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          if (canRetry) ...[
            const SizedBox(height: 8),
            Text(
              'Attempt ${retryCount + 1} of $maxRetries',
              style: TextStyle(
                fontSize: AppSizes.fontXS,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 32),
          if (canRetry)
            _GradientButton(
              label: 'Retry Payment',
              icon: Icons.refresh_rounded,
              onTap: onRetry!,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Go Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              side: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancelled State ───────────────────────────────────────────────────────────

class PaymentCancelledState extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onBack;

  const PaymentCancelledState({
    super.key,
    required this.onTryAgain,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.cancel_rounded,
              color: AppColors.warning,
              size: 52,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Cancelled',
            style: TextStyle(
              fontSize: AppSizes.fontXXL,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No charge was made. You can try again whenever you\'re ready.',
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _GradientButton(
            label: 'Try Again',
            icon: Icons.payment_rounded,
            onTap: onTryAgain,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: Text(
              'Go Back',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared gradient button ────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontMD,
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
}
