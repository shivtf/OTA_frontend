// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../widgets/auth_divider.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/social_login_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignup() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.agreeTermsError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushNamed(AppRoutes.registration);
    }
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
                    _ThemeToggleSmall(
                        controller: themeController, isDark: isDark),
                  ],
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Header
                Center(
                  child: AuthHeader(
                    title: AppStrings.createAccount,
                    subtitle: AppStrings.signupSubtitle,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Full Name
                CustomTextField(
                  label: 'Full Name',
                  hint: AppStrings.fullName,
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Email
                CustomTextField(
                  label: 'Email Address',
                  hint: AppStrings.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(v)) {
                      return AppStrings.invalidEmail;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Phone
                CustomTextField(
                  label: 'Phone Number',
                  hint: AppStrings.phoneNumber,
                  prefixIcon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v.length < 10) return AppStrings.invalidPhone;
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Password
                CustomTextField(
                  label: 'Password',
                  hint: AppStrings.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v.length < 8) return AppStrings.passwordTooShort;
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: AppStrings.confirmedPassword,
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v != _passwordController.text) {
                      return AppStrings.passwordsNoMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingLG),

                // Terms & Conditions
                _TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  isDark: isDark,
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Create Account button
                GradientButton(
                  text: AppStrings.createAccount,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _onSignup,
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Divider
                const AuthDivider(text: AppStrings.orSignUpWith),

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

                const SizedBox(height: AppSizes.paddingXL),

                // Bottom link
                Center(
                  child: _BottomAuthLink(
                    text: AppStrings.alreadyAccount,
                    linkText: AppStrings.loginLink,
                    onTap: () => Navigator.of(context).pop(),
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

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool isDark;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: Wrap(
            children: [
              Text(
                AppStrings.agreeTerms,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  AppStrings.termsConditions,
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryStart,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeToggleSmall extends StatelessWidget {
  final ThemeController controller;
  final bool isDark;
  const _ThemeToggleSmall({required this.controller, required this.isDark});

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
  const _BottomAuthLink(
      {required this.text, required this.linkText, required this.onTap});

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
          child: const Text(
            'Login',
            style: TextStyle(
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