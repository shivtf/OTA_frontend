// lib/features/auth/screens/reset_password_screen.dart
//
// Opened via deep link: otaapp://auth/reset-password?token=<TOKEN>
//
// AppRoutes passes the token as a route argument:
//   Navigator.pushNamed(context, AppRoutes.resetPassword,
//     arguments: {'token': token});
//
// On success → navigates back to login (all previous routes cleared).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../../../core/utils/reset_password_token_cache.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _confirmFocusNode = FocusNode();

  String? _token;
  bool _tokenError = false;

  // Password strength
  int _strengthScore = 0; // 0-4

  // Animated success check
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // Token is extracted in didChangeDependencies (args not available in initState)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final argToken = args?['token'] as String?;

      if (argToken != null && argToken.isNotEmpty) {
        _token = argToken;
      } else {
        // Arguments were lost (cold start / navigator rebuild) — read from cache
        ResetPasswordTokenCache.read().then((cached) {
          if (!mounted) return;
          if (cached != null && cached.isNotEmpty) {
            setState(() => _token = cached);
          } else {
            setState(() => _tokenError = true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _confirmFocusNode.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ── Password strength ───────────────────────────────────────────
  void _onPasswordChanged(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (value.contains(RegExp(r'[A-Z]'))) score++;
    if (value.contains(RegExp(r'[0-9]'))) score++;
    if (value.contains(RegExp(r'[^A-Za-z0-9]'))) score++;
    setState(() => _strengthScore = score);
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.accentGold;
      case 4:
        return AppColors.success;
      default:
        return Colors.transparent;
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  // ── Submit ──────────────────────────────────────────────────────
  Future<void> _onReset() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.resetPassword(
      token: _token!,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (ok) {
      await ResetPasswordTokenCache.clear();
      await _successController.forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to reset password. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated check
              ScaleTransition(
                scale: _successScale,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStart.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),
              Text(
                'Password Reset!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                'Your password has been updated. All other active sessions have been signed out for your security.',
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
                text: 'Back to Login',
                icon: Icons.login_rounded,
                onPressed: () {
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

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final padding = Responsive.adaptivePadding(context);

    if (_tokenError) {
      return _InvalidTokenView(isDark: isDark);
    }

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
                const CustomBackButton(),
                const SizedBox(height: AppSizes.paddingXL),

                Center(
                  child: AuthHeader(
                    title: 'Set New Password',
                    subtitle:
                        'Your new password must be different from your previous one.',
                  ),
                ),

                const SizedBox(height: AppSizes.paddingXXL),

                // ── New password ──────────────────────────────────
                CustomTextField(
                  label: 'New Password',
                  hint: 'At least 8 characters',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _newPasswordController,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () =>
                      FocusScope.of(context).requestFocus(_confirmFocusNode),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required.';
                    if (v.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }
                    if (!v.contains(RegExp(r'[A-Z]'))) {
                      return 'Must contain at least one uppercase letter.';
                    }
                    if (!v.contains(RegExp(r'[0-9]'))) {
                      return 'Must contain at least one number.';
                    }
                    if (!v.contains(RegExp(r'[^A-Za-z0-9]'))) {
                      return 'Must contain at least one special character.';
                    }
                    return null;
                  },
                ),

                // Strength indicator
                if (_newPasswordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _StrengthBar(
                    score: _strengthScore,
                    color: _strengthColor,
                    label: _strengthLabel,
                    isDark: isDark,
                    onChanged: _onPasswordChanged,
                    controller: _newPasswordController,
                  ),
                ] else ...[
                  // Keep listener active
                  _PasswordListener(
                    controller: _newPasswordController,
                    onChanged: _onPasswordChanged,
                  ),
                ],

                const SizedBox(height: AppSizes.paddingMD),

                // ── Confirm password ──────────────────────────────
                CustomTextField(
                  label: 'Confirm New Password',
                  hint: 'Re-enter your new password',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _confirmPasswordController,
                  focusNode: _confirmFocusNode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onReset(),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password.';
                    }
                    if (v != _newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.paddingMD),

                // ── Password rules hint ───────────────────────────
                _PasswordRules(
                  password: _newPasswordController.text,
                  isDark: isDark,
                ),

                const SizedBox(height: AppSizes.paddingXL),

                GradientButton(
                  text: 'Reset Password',
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _onReset,
                  icon: Icons.lock_reset_rounded,
                ),

                const SizedBox(height: AppSizes.paddingXXL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Strength bar ──────────────────────────────────────────────────────────────

class _StrengthBar extends StatefulWidget {
  final int score;
  final Color color;
  final String label;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const _StrengthBar({
    required this.score,
    required this.color,
    required this.label,
    required this.isDark,
    required this.onChanged,
    required this.controller,
  });

  @override
  State<_StrengthBar> createState() => _StrengthBarState();
}

class _StrengthBarState extends State<_StrengthBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    widget.onChanged(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = i < widget.score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled
                      ? widget.color
                      : (widget.isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (widget.label.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Password strength: ${widget.label}',
            style: TextStyle(
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Invisible listener widget (keeps listener active when bar is hidden) ──────

class _PasswordListener extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _PasswordListener({required this.controller, required this.onChanged});

  @override
  State<_PasswordListener> createState() => _PasswordListenerState();
}

class _PasswordListenerState extends State<_PasswordListener> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => widget.onChanged(widget.controller.text);

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Password rules checklist ──────────────────────────────────────────────────

class _PasswordRules extends StatelessWidget {
  final String password;
  final bool isDark;

  const _PasswordRules({required this.password, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rules = [
      _Rule('At least 8 characters', password.length >= 8),
      _Rule('One uppercase letter', password.contains(RegExp(r'[A-Z]'))),
      _Rule('One number', password.contains(RegExp(r'[0-9]'))),
      _Rule(
          'One special character', password.contains(RegExp(r'[^A-Za-z0-9]'))),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: TextStyle(
              fontSize: AppSizes.fontXS,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map((r) => _RuleRow(rule: r, isDark: isDark)),
        ],
      ),
    );
  }
}

class _Rule {
  final String text;
  final bool passed;
  const _Rule(this.text, this.passed);
}

class _RuleRow extends StatelessWidget {
  final _Rule rule;
  final bool isDark;
  const _RuleRow({required this.rule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              rule.passed
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(rule.passed),
              size: 15,
              color: rule.passed
                  ? AppColors.success
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rule.text,
            style: TextStyle(
              fontSize: AppSizes.fontXS,
              color: rule.passed
                  ? AppColors.success
                  : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
              fontWeight: rule.passed ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invalid / expired token fallback view ─────────────────────────────────────

class _InvalidTokenView extends StatelessWidget {
  final bool isDark;
  const _InvalidTokenView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.link_off_rounded,
                  size: 38,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXL),
              Text(
                'Invalid or Expired Link',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingMD),
              Text(
                'This password reset link is invalid or has expired (links expire after 30 minutes). Please request a new one.',
                style: TextStyle(
                  fontSize: AppSizes.fontMD,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingXXL),
              GradientButton(
                text: 'Request New Link',
                icon: Icons.refresh_rounded,
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.forgotPassword,
                    (route) => route.settings.name == AppRoutes.login,
                  );
                },
              ),
              const SizedBox(height: AppSizes.paddingLG),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (_) => false,
                ),
                child: Text(
                  'Back to Login',
                  style: TextStyle(
                    fontSize: AppSizes.fontSM,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
