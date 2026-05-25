// lib/features/auth/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = _isFocused
        ? AppColors.primaryStart
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.textInputAction,
          focusNode: _focusNode,
          onEditingComplete: widget.onEditingComplete,
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.prefixIcon, size: 20, color: iconColor),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: iconColor,
              ),
              onPressed: () {
                setState(() => _obscureText = !_obscureText);
              },
            )
                : null,
          ),
        ),
      ],
    );
  }
}