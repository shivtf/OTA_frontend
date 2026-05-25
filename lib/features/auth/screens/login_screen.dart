// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_divider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);

    // Navigate to home (phase 2)
    // Navigator.of(context).pushNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = context.watch<ThemeController>();
    final padding = Responsive.adaptivePadding(context);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.paddingMD),

                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomBackButton(),
                    _ThemeToggle(controller: themeController, isDark: isDark),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Header: logo + title
                Center(
                  child: AuthHeader(
                    title: AppStrings.welcomeBack,
                    subtitle: AppStrings.loginSubtitle,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXXL),

                // Email field
                CustomTextField(
                  label: 'Email or Phone',
                  hint: AppStrings.emailOrPhone,
                  prefixIcon: Icons.alternate_email_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Password field
                CustomTextField(
                  label: 'Password',
                  hint: AppStrings.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (v.length < 8) return AppStrings.passwordTooShort;
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      AppStrings.forgotPassword,
                      style: const TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Login button
                GradientButton(
                  text: AppStrings.login,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _onLogin,
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Divider
                const AuthDivider(text: AppStrings.orContinueWith),

                const SizedBox(height: AppSizes.paddingLG),

                // Social buttons
                SocialLoginButton(
                  type: SocialType.google,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSizes.paddingMD),
                SocialLoginButton(
                  type: SocialType.apple,
                  onPressed: () {},
                ),

                const SizedBox(height: AppSizes.paddingXXL),

                // Bottom: sign up link
                Center(
                  child: _BottomAuthLink(
                    text: AppStrings.noAccount,
                    linkText: AppStrings.signUp,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.signup),
                  ),
                ),

                const SizedBox(height: AppSizes.paddingLG),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final ThemeController controller;
  final bool isDark;

  const _ThemeToggle({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.toggleTheme,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}

class _BottomAuthLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const _BottomAuthLink({
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$text ',
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkText,
            style: const TextStyle(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryStart,
            ),
          ),
        ),
      ],
    );
  }
}