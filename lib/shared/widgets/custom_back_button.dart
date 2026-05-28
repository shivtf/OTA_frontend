
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool useLightStyle;
  final Color? color;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.useLightStyle = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = useLightStyle
        ? Colors.white.withOpacity(0.2)
        : (isDark
        ? AppColors.darkCard
        : AppColors.lightInputBg);
    final iconColor = useLightStyle
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: useLightStyle
              ? Border.all(color: Colors.white.withOpacity(0.3))
              : Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }
}