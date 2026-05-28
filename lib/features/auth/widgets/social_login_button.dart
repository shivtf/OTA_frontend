// lib/features/auth/widgets/social_login_button.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'dart:math' as math;

class SocialLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textColor =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: AppSizes.buttonHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: _GoogleIcon()),
            const SizedBox(width: 10),
            Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 26),
      painter: _GooglePainter(),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.18;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width * 0.34,
    );

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // RED
    canvas.drawArc(
      rect,
      -45 * math.pi / 180,
      90 * math.pi / 180,
      false,
      arcPaint(const Color(0xFFEA4335)),
    );

    // YELLOW
    canvas.drawArc(
      rect,
      45 * math.pi / 180,
      90 * math.pi / 180,
      false,
      arcPaint(const Color(0xFFFBBC05)),
    );

    // GREEN
    canvas.drawArc(
      rect,
      135 * math.pi / 180,
      90 * math.pi / 180,
      false,
      arcPaint(const Color(0xFF34A853)),
    );

    // BLUE
    canvas.drawArc(
      rect,
      225 * math.pi / 180,
      135 * math.pi / 180,
      false,
      arcPaint(const Color(0xFF4285F4)),
    );

    // Capital G horizontal line
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final centerY = size.height / 2;

    // Start slightly INSIDE circle
    // End BEFORE touching edge
    canvas.drawLine(
      Offset(size.width * 0.56, centerY),
      Offset(size.width * 0.76, centerY),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}