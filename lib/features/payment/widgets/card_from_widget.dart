// lib/features/payment/widgets/card_form_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CardFormWidget extends StatefulWidget {
  final GlobalKey<CardFormWidgetState> formKey;
  final bool isDark;

  const CardFormWidget({
    super.key,
    required this.formKey,
    required this.isDark,
  });

  @override
  State<CardFormWidget> createState() => CardFormWidgetState();
}

class CardFormWidgetState extends State<CardFormWidget> {
  final _cardNumberController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = false;
  bool _cvvVisible = false;

  String get cardNumber => _cardNumberController.text.replaceAll(' ', '');
  String get cardholder => _cardholderController.text;
  String get expiry => _expiryController.text;
  String get cvv => _cvvController.text;
  bool get saveCard => _saveCard;

  bool validate() {
    return cardNumber.length == 16 &&
        cardholder.trim().isNotEmpty &&
        expiry.length == 5 &&
        cvv.length >= 3;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: widget.isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live card preview
          _CardPreview(
            number: _cardNumberController.text,
            holder: _cardholderController.text,
            expiry: _expiryController.text,
          ),
          const SizedBox(height: 20),

          // Cardholder name
          _CardField(
            label: 'Cardholder Name',
            hint: 'John Doe',
            controller: _cardholderController,
            icon: Icons.person_outline_rounded,
            isDark: widget.isDark,
            inputType: TextInputType.name,
            capitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Card number
          _CardField(
            label: 'Card Number',
            hint: '1234  5678  9012  3456',
            controller: _cardNumberController,
            icon: Icons.credit_card_rounded,
            isDark: widget.isDark,
            inputType: TextInputType.number,
            maxLength: 19,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Expiry + CVV row
          Row(
            children: [
              Expanded(
                child: _CardField(
                  label: 'Expiry',
                  hint: 'MM/YY',
                  controller: _expiryController,
                  icon: Icons.calendar_today_rounded,
                  isDark: widget.isDark,
                  inputType: TextInputType.number,
                  maxLength: 5,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CardField(
                  label: 'CVV',
                  hint: '•••',
                  controller: _cvvController,
                  icon: Icons.lock_outline_rounded,
                  isDark: widget.isDark,
                  inputType: TextInputType.number,
                  maxLength: 4,
                  obscure: !_cvvVisible,
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _cvvVisible = !_cvvVisible),
                    child: Icon(
                      _cvvVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 16,
                      color: widget.isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Save card toggle
          GestureDetector(
            onTap: () => setState(() => _saveCard = !_saveCard),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient:
                    _saveCard ? AppColors.primaryGradient : null,
                    color: _saveCard
                        ? null
                        : (widget.isDark
                        ? AppColors.darkInputBg
                        : AppColors.lightInputBg),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _saveCard
                          ? AppColors.primaryStart
                          : (widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                    ),
                  ),
                  child: _saveCard
                      ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  'Save card for future payments',
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card preview widget ───────────────────────────────────────────────────────

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
    final displayNumber = number.isEmpty
        ? '••••  ••••  ••••  ••••'
        : number.padRight(19, '•');

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background circles
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -20,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: chip + brand
                Row(children: [
                  // Chip icon
                  Container(
                    width: 36, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.memory_rounded,
                        color: Colors.white, size: 16),
                  ),
                  const Spacer(),
                  const Text('WANDERLY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      )),
                ]),

                const Spacer(),

                // Card number
                Text(
                  displayNumber.length > 19
                      ? displayNumber.substring(0, 19)
                      : displayNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                  ),
                ),

                const SizedBox(height: 14),

                // Holder + expiry
                Row(children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CARD HOLDER',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              letterSpacing: 1,
                            )),
                        Text(
                          holder.isEmpty ? 'YOUR NAME' : holder.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ]),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('EXPIRES',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 9,
                              letterSpacing: 1,
                            )),
                        Text(
                          expiry.isEmpty ? 'MM/YY' : expiry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable card input field ─────────────────────────────────────────────────

class _CardField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final bool isDark;
  final TextInputType inputType;
  final int? maxLength;
  final List<TextInputFormatter>? formatters;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final Widget? suffixIcon;
  final TextCapitalization capitalization;

  const _CardField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.isDark,
    required this.inputType,
    required this.onChanged,
    this.maxLength,
    this.formatters,
    this.obscure = false,
    this.suffixIcon,
    this.capitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontXS,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryStart),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: inputType,
                  maxLength: maxLength,
                  inputFormatters: formatters,
                  textCapitalization: capitalization,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    filled: false,
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (suffixIcon != null) suffixIcon!,
            ],
          ),
        ),
      ],
    );
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('  ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll('/', '');
    if (digits.length <= 2) {
      return newVal.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    final str = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
