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
import '../providers/auth_provider.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/social_login_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.agreeTermsError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();

    // Format phone: add +91 if not already international
    String phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    final success = await auth.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: phone,
    );

    if (!mounted) return;

    if (success) {
      _showVerificationDialog(_emailController.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  void _showVerificationDialog(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Text(
                'Verify Your Email',
                style: Theme.of(ctx).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'We\'ve sent a verification link to\n$email\n\nPlease check your inbox and click the link to activate your account.',
                style: TextStyle(
                  fontSize: AppSizes.fontMD,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingXL),
              GradientButton(
                text: 'Go to Login',
                height: AppSizes.buttonHeightSM,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthProvider>();
    final padding = Responsive.adaptivePadding(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.paddingMD),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CustomBackButton(),
                    _ThemeToggle(controller: themeController, isDark: isDark),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingXL),
                Center(
                  child: AuthHeader(
                    title: AppStrings.createAccount,
                    subtitle: AppStrings.signupSubtitle,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // First Name
                CustomTextField(
                  label: 'First Name',
                  hint: 'John',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return AppStrings.fieldRequired;
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMD),

                // Last Name
                CustomTextField(
                  label: 'Last Name',
                  hint: 'Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return AppStrings.fieldRequired;
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
                  hint: '9876543210',
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
                  hint: AppStrings.confirmPassword,
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v != _passwordController.text)
                      return AppStrings.passwordsNoMatch;
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingLG),

                // Terms
                _TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.paddingXL),

                GradientButton(
                  text: AppStrings.createAccount,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _onSignup,
                ),

                const SizedBox(height: AppSizes.paddingXL),
                const AuthDivider(text: AppStrings.orSignUpWith),
                const SizedBox(height: AppSizes.paddingLG),
                SocialLoginButton(onPressed: () {}),
                const SizedBox(height: AppSizes.paddingXL),
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
  const _TermsCheckbox(
      {required this.value, required this.onChanged, required this.isDark});

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
                        : AppColors.lightTextSecondary),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(AppStrings.termsConditions,
                    style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryStart)),
              ),
            ],
          ),
        ),
      ],
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
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 18,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
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
        Text('$text ',
            style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)),
        GestureDetector(
          onTap: onTap,
          child: const Text('Login',
              style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryStart)),
        ),
      ],
    );
  }
}
