import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../../../core/services/flight_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController(); // YYYY-MM-DD
  final _passportController = TextEditingController();
  final _passportExpiryController = TextEditingController();

  String _title = 'mr';
  String _gender = 'm';
  String _passengerType = 'adult';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passportController.dispose();
    _passportExpiryController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() != true) return;

    String phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !phone.startsWith('+')) {
      phone = '+91$phone';
    }

    final passenger = PassengerInput(
      type: _passengerType,
      title: _title,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      gender: _gender,
      email: _emailController.text.trim(),
      phone: phone,
      passportNumber: _passportController.text.trim().isEmpty
          ? null
          : _passportController.text.trim(),
      passportExpiryDate: _passportExpiryController.text.trim().isEmpty
          ? null
          : _passportExpiryController.text.trim(),
    );

    Navigator.of(context).pop(passenger);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final passengerIndex = (args?['passengerIndex'] as int?) ?? 0;
    final passengerCount = (args?['passengerCount'] as int?) ?? 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeController = context.watch<ThemeController>();
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
                    title: 'Passenger ${passengerIndex + 1} of $passengerCount',
                    subtitle: 'Enter passenger details for your booking',
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXL),

                // Title & Passenger type row
                Row(
                  children: [
                    Expanded(
                      child: _DropdownField(
                        label: 'Title',
                        value: _title,
                        items: const {
                          'mr': 'Mr',
                          'ms': 'Ms',
                          'mrs': 'Mrs',
                          'dr': 'Dr',
                        },
                        onChanged: (v) => setState(() => _title = v!),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DropdownField(
                        label: 'Type',
                        value: _passengerType,
                        items: const {
                          'adult': 'Adult',
                          'child': 'Child',
                          'infant_without_seat': 'Infant',
                        },
                        onChanged: (v) => setState(() => _passengerType = v!),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingMD),

                _SectionLabel(label: 'Personal Information', isDark: isDark),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'First Name *',
                  hint: 'John',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _firstNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.fieldRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Last Name *',
                  hint: 'Doe',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _lastNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.fieldRequired
                      : null,
                ),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Email *',
                  hint: 'john@example.com',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (!v.contains('@')) return AppStrings.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Phone *',
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

                // Gender
                _DropdownField(
                  label: 'Gender',
                  value: _gender,
                  items: const {'m': 'Male', 'f': 'Female'},
                  onChanged: (v) => setState(() => _gender = v!),
                  isDark: isDark,
                ),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Date of Birth *',
                  hint: 'YYYY-MM-DD',
                  prefixIcon: Icons.cake_outlined,
                  controller: _dobController,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                    if (!dateRegex.hasMatch(v)) return 'Use format YYYY-MM-DD';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingXL),

                _SectionLabel(
                    label: 'Travel Document (Optional)', isDark: isDark),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Passport Number',
                  hint: 'A1234567',
                  prefixIcon: Icons.badge_outlined,
                  controller: _passportController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.paddingMD),

                CustomTextField(
                  label: 'Passport Expiry',
                  hint: 'YYYY-MM-DD',
                  prefixIcon: Icons.event_outlined,
                  controller: _passportExpiryController,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSizes.paddingXXL),

                GradientButton(
                  text: passengerIndex + 1 < passengerCount
                      ? 'Next Passenger'
                      : 'Continue to Payment',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: AppSizes.paddingXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            )),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppColors.darkCard : Colors.white,
              items: items.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            )),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
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
        Text(label,
            style: TextStyle(
              fontSize: AppSizes.fontMD,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            )),
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
