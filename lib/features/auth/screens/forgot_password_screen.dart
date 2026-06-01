// lib/features/auth/screens/forgot_password_screen.dart
//
// Screen 1 of the password reset flow.
// User enters their email → POST /auth/forgot-password → shows confirmation.
// The backend sends a deep-link email: otaapp://auth/reset-password?token=...
// which opens ResetPasswordScreen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _emailSent = false;

  // Slide-up animation for the success state
  late final AnimationController _successController;
  late final Animation<double> _successFade;
  late final Animation<Offset> _successSlide;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successFade = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOut,
    );
    _successSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.forgotPassword(_emailController.text.trim());

    if (!mounted) return;

    if (ok) {
      setState(() => _emailSent = true);
      _successController.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send reset email. Try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final padding = Responsive.adaptivePadding(context);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _emailSent
              ? _EmailSentView(
                  email: _emailController.text.trim(),
                  isDark: isDark,
                  slideAnim: _successSlide,
                  fadeAnim: _successFade,
                  onResend: _onSend,
                  isLoading: auth.isLoading,
                )
              : _EnterEmailView(
                  formKey: _formKey,
                  emailController: _emailController,
                  isDark: isDark,
                  isLoading: auth.isLoading,
                  onSend: _onSend,
                ),
        ),
      ),
    );
  }
}

// ── Enter email view ──────────────────────────────────────────────────────────

class _EnterEmailView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSend;

  const _EnterEmailView({
    required this.formKey,
    required this.emailController,
    required this.isDark,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.paddingMD),
          const CustomBackButton(),
          const SizedBox(height: AppSizes.paddingXL),
          Center(
            child: AuthHeader(
              title: 'Forgot Password?',
              subtitle:
                  'No worries! Enter your email and we\'ll send you a reset link.',
            ),
          ),
          const SizedBox(height: AppSizes.paddingXXL),

          // Email field
          CustomTextField(
            label: 'Email address',
            hint: 'Enter your registered email',
            prefixIcon: Icons.alternate_email_rounded,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSend(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$').hasMatch(v.trim())) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),

          const SizedBox(height: AppSizes.paddingXL),

          GradientButton(
            text: 'Send Reset Link',
            isLoading: isLoading,
            onPressed: isLoading ? null : onSend,
            icon: Icons.send_rounded,
          ),

          const SizedBox(height: AppSizes.paddingXXL),

          // Back to login
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.paddingLG),
        ],
      ),
    );
  }
}

// ── Email sent confirmation view ──────────────────────────────────────────────

class _EmailSentView extends StatelessWidget {
  final String email;
  final bool isDark;
  final Animation<Offset> slideAnim;
  final Animation<double> fadeAnim;
  final VoidCallback onResend;
  final bool isLoading;

  const _EmailSentView({
    required this.email,
    required this.isDark,
    required this.slideAnim,
    required this.fadeAnim,
    required this.onResend,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppSizes.paddingXXL),

            // Success icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                size: 42,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSizes.paddingXL),

            Text(
              'Check Your Email',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.paddingMD),

            Text(
              'We\'ve sent a password reset link to',
              style: TextStyle(
                fontSize: AppSizes.fontMD,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.paddingSM),

            // Email pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alternate_email_rounded,
                    size: 16,
                    color: AppColors.primaryStart,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingMD),

            Text(
              'The link expires in 30 minutes.\nCheck your spam folder if you don\'t see it.',
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.paddingXXL),

            // Resend button (ghost style)
            GestureDetector(
              onTap: isLoading ? null : onResend,
              child: Container(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primaryStart,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppColors.primaryStart,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Resend Email',
                              style: TextStyle(
                                fontSize: AppSizes.fontMD,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryStart,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingLG),

            // Back to login
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingLG),
          ],
        ),
      ),
    );
  }
}
