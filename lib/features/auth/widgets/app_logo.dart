// lib/features/auth/widgets/app_logo.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';

enum LogoSize { small, medium, large }

class AppLogo extends StatelessWidget {
  final LogoSize size;
  final bool showName;
  final bool darkBackground;

  const AppLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showName = true,
    this.darkBackground = false,
  });

  double get _iconSize {
    switch (size) {
      case LogoSize.small:
        return 36;
      case LogoSize.medium:
        return AppSizes.logoSize;
      case LogoSize.large:
        return AppSizes.logoSizeLG;
    }
  }

  double get _nameFontSize {
    switch (size) {
      case LogoSize.small:
        return 16;
      case LogoSize.medium:
        return 20;
      case LogoSize.large:
        return 26;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = darkBackground
        ? Colors.white
        : Theme.of(context).textTheme.displayMedium?.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _iconSize,
          height: _iconSize,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(_iconSize * 0.3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryStart.withValues(alpha:0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(
            Icons.flight,
            color: Colors.white,
            size: _iconSize * 0.55,
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 8),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: _nameFontSize,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}