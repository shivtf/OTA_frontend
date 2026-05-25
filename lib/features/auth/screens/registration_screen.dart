// lib/features/auth/screens/registration_screen.dart
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
import '../../widgets/auth_header.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor:
        isDark ? AppColors.darkCard : AppColors.lightCard,
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
                      color: AppColors.primaryStart.withValues(alpha:0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Text(
                'Registration Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Text(
                'Your account has been created successfully. Welcome to Wanderly!',
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
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
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

                // Header
                Center(
                  child: AuthHeader(
                    title: AppStrings.createAccount,
                    subtitle: AppStrings.registerSubtitle,
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Progress indicator
                _buildProgressIndicator(isDark),

                const SizedBox(height: AppSizes.paddingXL),

                // Section label
                _SectionLabel(
                    label: 'Personal Information', isDark: isDark),

                const SizedBox(height: AppSizes.paddingMD),

                // Full Name
                CustomTextField(
                  label: 'Full Name *',
                  hint: AppStrings.fullName,
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppStrings.fieldRequired;
                    }
                    if (v.trim().split(' ').length < 2) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // Email
                CustomTextField(
                  label: 'Email Address *',
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
                  label: 'Phone Number *',
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

                const SizedBox(height: AppSizes.paddingXL),

                _SectionLabel(label: 'Security', isDark: isDark),

                const SizedBox(height: AppSizes.paddingMD),

                // Password
                CustomTextField(
                  label: 'Password *',
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

                const SizedBox(height: AppSizes.paddingSM),

                // Password strength indicator
                _PasswordStrength(controller: _passwordController),

                const SizedBox(height: AppSizes.paddingMD),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password *',
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

                const SizedBox(height: AppSizes.paddingXXL),

                // Submit button
                GradientButton(
                  text: AppStrings.completeRegistration,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _onSubmit,
                  icon: Icons.arrow_forward_rounded,
                ),

                const SizedBox(height: AppSizes.paddingXL),

                // Back to login
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                        AppRoutes.login, (_) => false),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back to Login',
                          style: TextStyle(
                            fontSize: AppSizes.fontSM,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildProgressIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMD,
        vertical: AppSizes.paddingMD,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : AppColors.primaryStart.withValues(alpha:0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.primaryStart.withValues(alpha:0.15),
        ),
      ),
      child: Row(
        children: [
          _StepDot(number: '1', label: 'Sign Up', isDone: true),
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          _StepDot(number: '2', label: 'Register', isActive: true),
          Expanded(
            child: Container(
              height: 2,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          _StepDot(number: '3', label: 'Done'),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String number;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StepDot({
    required this.number,
    required this.label,
    this.isDone = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlighted = isDone || isActive;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isHighlighted ? AppColors.primaryGradient : null,
            color: isHighlighted
                ? null
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : Text(
              number,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontXS,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isHighlighted
                ? AppColors.primaryStart
                : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _PasswordStrength extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordStrength({required this.controller});

  @override
  State<_PasswordStrength> createState() => _PasswordStrengthState();
}

class _PasswordStrengthState extends State<_PasswordStrength> {
  int _strength = 0;
  String _label = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_evaluate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_evaluate);
    super.dispose();
  }

  void _evaluate() {
    final v = widget.controller.text;
    int score = 0;
    if (v.length >= 8) score++;
    if (v.contains(RegExp(r'[A-Z]'))) score++;
    if (v.contains(RegExp(r'[0-9]'))) score++;
    if (v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;

    setState(() {
      _strength = score;
      _label = ['', 'Weak', 'Fair', 'Good', 'Strong'][score];
    });
  }

  Color get _color {
    switch (_strength) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return const Color(0xFF4CAF50);
      case 4:
        return AppColors.success;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_strength == 0) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  color: i < _strength
                      ? _color
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $_label',
          style: TextStyle(
            fontSize: AppSizes.fontXS,
            color: _color,
            fontWeight: FontWeight.w500,
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