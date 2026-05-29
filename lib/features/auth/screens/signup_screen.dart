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
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/api_client.dart';
import 'package:country_picker/country_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Country code → nationality map (ISO 3166-1 alpha-2).
// Add / remove entries as your backend requires.
// ─────────────────────────────────────────────────────────────────────────────

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Existing controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── NEW: fields required by /auth/register ────────────────────────────────
  final _dobController = TextEditingController(); // YYYY-MM-DD
  final _passportController = TextEditingController();
  Country _selectedCountry = CountryParser.parseCountryCode('US');
  // ─────────────────────────────────────────────────────────────────────────

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  // ── Date-picker helper ────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 1, now.month, now.day),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _dobController.text = formatted;
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
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

    // Format phone: add +91 prefix for bare Indian numbers
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
      // ── NEW fields ──────────────────────────────────
      dateOfBirth: _dobController.text.trim(),
      nationality: _selectedCountry.countryCode,
      passportNumber: _passportController.text.trim().isEmpty
          ? null
          : _passportController.text.trim(),
      // ────────────────────────────────────────────────
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

  // ── Verification dialog (shown immediately after successful register) ─────
  void _showVerificationDialog(String email) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool _resending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Icon(Icons.mark_email_unread_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: AppSizes.paddingLG),
                Text('Check Your Email',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSizes.paddingSM),
                Text(
                  'We\'ve sent a verification link to\n$email\n\nOpen Gmail and tap the link — it will open directly in the app.',
                  style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // ✅ Open Gmail button
                GradientButton(
                  text: 'Open Gmail',
                  height: AppSizes.buttonHeightSM,
                  onPressed: () async {
                    final gmailUri = Uri.parse('googlegmail://');
                    if (await canLaunchUrl(gmailUri)) {
                      await launchUrl(gmailUri);
                    } else {
                      await launchUrl(Uri.parse('https://mail.google.com'),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const SizedBox(height: AppSizes.paddingSM),

                // ✅ Resend button
                TextButton(
                  onPressed: _resending
                      ? null
                      : () async {
                          setDialogState(() => _resending = true);
                          try {
                            await ApiClient.instance.post(
                                '/auth/resend-verification', {'email': email});
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('✅ Verification email resent!')),
                              );
                            }
                          } catch (_) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Failed to resend. Please try again.')),
                              );
                            }
                          }
                          setDialogState(() => _resending = false);
                        },
                  child: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Resend verification email'),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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

                // ── Section: Personal Info ──────────────────────────────
                _SectionLabel(label: 'Personal Information', isDark: isDark),
                const SizedBox(height: AppSizes.paddingMD),

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

                // Date of Birth — NEW
                GestureDetector(
                  onTap: _pickDob,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Date of Birth',
                      hint: 'YYYY-MM-DD',
                      prefixIcon: Icons.cake_outlined,
                      controller: _dobController,
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return AppStrings.fieldRequired;
                        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v))
                          return 'Use format YYYY-MM-DD';
                        return null;
                      },
                    ),
                  ),
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
                const SizedBox(height: AppSizes.paddingXL),

                // ── Section: Travel Documents ───────────────────────────
                _SectionLabel(label: 'Travel Details', isDark: isDark),
                const SizedBox(height: AppSizes.paddingMD),

                // Nationality — NEW (dropdown)
                _NationalityDropdown(
                  value: _selectedCountry,
                  isDark: isDark,
                  onChanged: (country) =>
                      setState(() => _selectedCountry = country),
                ),
                const SizedBox(height: AppSizes.paddingMD),

                // Passport Number — NEW (optional)
                CustomTextField(
                  label: 'Passport Number (Optional)',
                  hint: 'P2630567',
                  prefixIcon: Icons.badge_outlined,
                  controller: _passportController,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                  // no validator — field is optional
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // ── Section: Security ───────────────────────────────────
                _SectionLabel(label: 'Security', isDark: isDark),
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
                    if (!RegExp(
                            r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%^&*])')
                        .hasMatch(v)) {
                      return 'Must contain upper, lower, number & symbol';
                    }
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

// ─────────────────────────────────────────────────────────────────────────────
// Nationality Dropdown
// ─────────────────────────────────────────────────────────────────────────────
class _NationalityDropdown extends StatelessWidget {
  final Country value;
  final bool isDark;
  final ValueChanged<Country> onChanged;

  const _NationalityDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nationality',
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: false,
              countryListTheme: CountryListThemeData(
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                textStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontSize: AppSizes.fontMD,
                ),
                searchTextStyle: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                inputDecoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightInputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              onSelect: onChanged,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  value.flagEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.name,
                    style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label (matches register_screen.dart style)
// ─────────────────────────────────────────────────────────────────────────────
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
            color:
                isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input formatter: force uppercase (passport numbers)
// ─────────────────────────────────────────────────────────────────────────────
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared private widgets (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────
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
                child: const Text(
                  AppStrings.termsConditions,
                  style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryStart),
                ),
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
          child: const Text(
            'Login',
            style: TextStyle(
                fontSize: AppSizes.fontSM,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryStart),
          ),
        ),
      ],
    );
  }
}
