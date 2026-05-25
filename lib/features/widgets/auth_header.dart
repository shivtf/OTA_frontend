// lib/features/auth/widgets/auth_header.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'app_logo.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        const AppLogo(size: LogoSize.medium),
        const SizedBox(height: AppSizes.paddingXL),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.paddingSM),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            color: textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}