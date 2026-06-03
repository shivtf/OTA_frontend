// lib/features/payment/widgets/card_from_widget.dart
//
// FIXES APPLIED (do not revert):
//
//   FIX 2 — Card number: spaces between digit groups are NOT counted toward
//            the 16-digit limit. Previously the formatter treated each inserted
//            space as a character, so the last 3 digits were swallowed.
//            Solution: _CardNumberFormatter strips all non-digits first, clamps
//            to 16, then re-inserts spaces — cursor always lands at the end.
//
//   FIX 3 — CVV: hard-capped at 3 digits via LengthLimitingTextInputFormatter.
//            The validator also rejects anything shorter than 3 digits.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget + state (GlobalKey<CardFormWidgetState> lets PaymentScreen
// call .validate() before processing payment)
// ─────────────────────────────────────────────────────────────────────────────

class CardFormWidget extends StatefulWidget {
  final GlobalKey<CardFormWidgetState> formKey;
  final bool isDark;

  const CardFormWidget({
    required this.formKey,
    required this.isDark,
  }) : super(key: formKey);

  @override
  CardFormWidgetState createState() => CardFormWidgetState();
}

class CardFormWidgetState extends State<CardFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _cvvVisible = false;

  // Called by PaymentScreen via GlobalKey
  bool validate() => _formKey.currentState?.validate() ?? false;

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // ── Raw digit count helper (spaces excluded) ────────────────────────────
  String get _rawDigits => _numberController.text.replaceAll(' ', '');

  // ── Card preview number (groups of 4, padded to 16) ────────────────────
  String get _previewNumber {
    final d = _rawDigits.padRight(16, '•');
    return '${d.substring(0, 4)}  ${d.substring(4, 8)}  '
        '${d.substring(8, 12)}  ${d.substring(12, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card preview ──────────────────────────────────────────────
          _CardPreview(
            number: _previewNumber,
            holder: _holderController.text.isEmpty
                ? 'YOUR NAME'
                : _holderController.text.toUpperCase(),
            expiry: _expiryController.text.isEmpty
                ? 'MM/YY'
                : _expiryController.text,
          ),
          const SizedBox(height: 20),

          // ── Cardholder name ───────────────────────────────────────────
          _label('Cardholder Name', isDark),
          const SizedBox(height: 6),
          _buildField(
            controller: _holderController,
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
            keyboardType: TextInputType.name,
            onChanged: (_) => setState(() {}),
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),

          // ── Card number — FIX 2 ───────────────────────────────────────
          _label('Card Number', isDark),
          const SizedBox(height: 6),
          _buildField(
            controller: _numberController,
            hint: '0000  0000  0000  0000',
            icon: Icons.credit_card_rounded,
            isDark: isDark,
            keyboardType: TextInputType.number,
            // FIX 2: formatter strips spaces before counting digits,
            // so all 16 digits are always captured correctly.
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final digits = (v ?? '').replaceAll(' ', '');
              if (digits.isEmpty) return 'Card number is required';
              if (digits.length < 16) return 'Enter all 16 digits';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // ── Expiry + CVV row ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expiry
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Expiry', isDark),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _expiryController,
                      hint: 'MM/YY',
                      icon: Icons.calendar_month_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [_ExpiryFormatter()],
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(v)) {
                          return 'Use MM/YY';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // CVV — FIX 3
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('CVV', isDark),
                    const SizedBox(height: 6),
                    _buildField(
                      controller: _cvvController,
                      hint: '•••',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      obscureText: !_cvvVisible,
                      keyboardType: TextInputType.number,
                      // FIX 3: hard limit of 3 digits — cannot type a 4th digit
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      suffixIcon: IconButton(
                        icon: Icon(
                          _cvvVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _cvvVisible = !_cvvVisible),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length != 3) return 'Must be 3 digits';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Shared field builder ────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        fontSize: AppSizes.fontMD,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryMid),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primaryMid, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
    text,
    style: TextStyle(
      fontSize: AppSizes.fontSM,
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card preview widget
// ─────────────────────────────────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  final String number;
  final String holder;
  final String expiry;

  const _CardPreview({
    required this.number,
    required this.holder,
    required this.expiry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 185,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.settings, color: Colors.white54, size: 22),
              Text(
                'WANDERLY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                  Text(holder,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('EXPIRES',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 9, letterSpacing: 1)),
                  Text(expiry,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX 2 — Card Number Formatter
//
// Algorithm:
//   1. Strip ALL non-digit characters (including previously inserted spaces).
//   2. Clamp to 16 digits.
//   3. Re-insert a double space every 4 digits.
//   4. Place cursor at end.
//
// This means spaces are purely cosmetic and never count toward the digit limit.
// ─────────────────────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Step 1 & 2: digits only, max 16
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digits.length > 16 ? digits.substring(0, 16) : digits;

    // Step 3: group into blocks of 4
    final buffer = StringBuffer();
    for (int i = 0; i < clamped.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(clamped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expiry Formatter  MM/YY
// ─────────────────────────────────────────────────────────────────────────────

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clamped = digits.length > 4 ? digits.substring(0, 4) : digits;

    final buffer = StringBuffer();
    for (int i = 0; i < clamped.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(clamped[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
