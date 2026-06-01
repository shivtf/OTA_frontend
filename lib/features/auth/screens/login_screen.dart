// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_sizes.dart';
// import '../../../core/constants/app_strings.dart';
// import '../../../core/routes/app_routes.dart';
// import '../../../core/theme/theme_controller.dart';
// import '../../../core/utils/responsive.dart';
// import '../../../shared/widgets/custom_back_button.dart';
// import '../providers/auth_provider.dart';
// import '../widgets/auth_divider.dart';
// import '../widgets/auth_header.dart';
// import '../widgets/custom_text_field.dart';
// import '../widgets/gradient_button.dart';
// import '../widgets/social_login_button.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onLogin() async {
//     if (_formKey.currentState?.validate() != true) return;
//
//     final auth = context.read<AuthProvider>();
//     auth.clearError();
//
//     final success = await auth.login(
//       _emailController.text.trim(),
//       _passwordController.text,
//     );
//
//     if (!mounted) return;
//
//     if (success) {
//       Navigator.of(context).pushNamedAndRemoveUntil(
//         AppRoutes.home,
//         (_) => false,
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(auth.error ?? 'Login failed. Please try again.'),
//           backgroundColor: AppColors.error,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
//           ),
//         ),
//       );
//     }
//   }
//
//   Future<void> _onForgotPassword() async {
//     final email = _emailController.text.trim();
//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Enter your email first'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//     final auth = context.read<AuthProvider>();
//     final ok = await auth.forgotPassword(email);
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           ok
//               ? 'Password reset email sent to $email'
//               : (auth.error ?? 'Failed to send reset email'),
//         ),
//         backgroundColor: ok ? AppColors.success : AppColors.error,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final themeController = context.watch<ThemeController>();
//     final auth = context.watch<AuthProvider>();
//     final padding = Responsive.adaptivePadding(context);
//
//     return Scaffold(
//       backgroundColor:
//           isDark ? AppColors.darkBackground : AppColors.lightBackground,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(horizontal: padding),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: AppSizes.paddingMD),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const CustomBackButton(),
//                     _ThemeToggle(controller: themeController, isDark: isDark),
//                   ],
//                 ),
//                 const SizedBox(height: AppSizes.paddingXL),
//                 Center(
//                   child: AuthHeader(
//                     title: AppStrings.welcomeBack,
//                     subtitle: AppStrings.loginSubtitle,
//                   ),
//                 ),
//                 const SizedBox(height: AppSizes.paddingXXL),
//                 CustomTextField(
//                   label: 'Email',
//                   hint: AppStrings.emailOrPhone,
//                   prefixIcon: Icons.alternate_email_rounded,
//                   controller: _emailController,
//                   keyboardType: TextInputType.emailAddress,
//                   textInputAction: TextInputAction.next,
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return AppStrings.fieldRequired;
//                     if (!v.contains('@')) return AppStrings.invalidEmail;
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: AppSizes.paddingMD),
//                 CustomTextField(
//                   label: 'Password',
//                   hint: AppStrings.password,
//                   prefixIcon: Icons.lock_outline_rounded,
//                   isPassword: true,
//                   controller: _passwordController,
//                   textInputAction: TextInputAction.done,
//                   onSubmitted: (_) => _onLogin(),
//                   validator: (v) {
//                     if (v == null || v.isEmpty) return AppStrings.fieldRequired;
//                     if (v.length < 6) return AppStrings.passwordTooShort;
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: AppSizes.paddingMD),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: GestureDetector(
//                     onTap: _onForgotPassword,
//                     child: const Text(
//                       AppStrings.forgotPassword,
//                       style: TextStyle(
//                         fontSize: AppSizes.fontSM,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.primaryStart,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: AppSizes.paddingXL),
//                 GradientButton(
//                   text: AppStrings.login,
//                   isLoading: auth.isLoading,
//                   onPressed: auth.isLoading ? null : _onLogin,
//                 ),
//                 const SizedBox(height: AppSizes.paddingXL),
//                 const AuthDivider(text: AppStrings.orContinueWith),
//                 const SizedBox(height: AppSizes.paddingLG),
//                 SocialLoginButton(onPressed: () {}),
//                 const SizedBox(height: AppSizes.paddingXXL),
//                 Center(
//                   child: _BottomAuthLink(
//                     text: AppStrings.noAccount,
//                     linkText: AppStrings.signUp,
//                     onTap: () =>
//                         Navigator.of(context).pushNamed(AppRoutes.signup),
//                   ),
//                 ),
//                 const SizedBox(height: AppSizes.paddingLG),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _ThemeToggle extends StatelessWidget {
//   final ThemeController controller;
//   final bool isDark;
//   const _ThemeToggle({required this.controller, required this.isDark});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: controller.toggleTheme,
//       child: Container(
//         width: 40,
//         height: 40,
//         decoration: BoxDecoration(
//           color: isDark ? AppColors.darkCard : AppColors.lightInputBg,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//           ),
//         ),
//         child: Icon(
//           isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
//           size: 18,
//           color: isDark
//               ? AppColors.darkTextSecondary
//               : AppColors.lightTextSecondary,
//         ),
//       ),
//     );
//   }
// }
//
// class _BottomAuthLink extends StatelessWidget {
//   final String text;
//   final String linkText;
//   final VoidCallback onTap;
//   const _BottomAuthLink({
//     required this.text,
//     required this.linkText,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           '$text ',
//           style: TextStyle(
//             fontSize: AppSizes.fontSM,
//             color: isDark
//                 ? AppColors.darkTextSecondary
//                 : AppColors.lightTextSecondary,
//           ),
//         ),
//         GestureDetector(
//           onTap: onTap,
//           child: const Text(
//             'Sign Up',
//             style: TextStyle(
//               fontSize: AppSizes.fontSM,
//               fontWeight: FontWeight.w700,
//               color: AppColors.primaryStart,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/responsive.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_header.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/gradient_button.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (_formKey.currentState?.validate() != true) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
            (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Password reset email sent to $email'
              : (auth.error ?? 'Failed to send reset email'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: _ThemeToggle(controller: themeController, isDark: isDark),
                ),
                const SizedBox(height: AppSizes.paddingXL),
                Center(
                  child: AuthHeader(
                    title: AppStrings.welcomeBack,
                    subtitle: AppStrings.loginSubtitle,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXXL),
                CustomTextField(
                  label: 'Email',
                  hint: AppStrings.emailOrPhone,
                  prefixIcon: Icons.alternate_email_rounded,
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
                  label: 'Password',
                  hint: AppStrings.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: _passwordController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onLogin(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                    if (v.length < 6) return AppStrings.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.paddingMD),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _onForgotPassword,
                    child: const Text(
                      AppStrings.forgotPassword,
                      style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingXL),
                GradientButton(
                  text: AppStrings.login,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : _onLogin,
                ),
                const SizedBox(height: AppSizes.paddingXL),
                const AuthDivider(text: AppStrings.orContinueWith),
                const SizedBox(height: AppSizes.paddingLG),
                SocialLoginButton(onPressed: () {}),
                const SizedBox(height: AppSizes.paddingXXL),
                Center(
                  child: _BottomAuthLink(
                    text: AppStrings.noAccount,
                    linkText: AppStrings.signUp,
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.signup),
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

class _BottomAuthLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;
  const _BottomAuthLink({
    required this.text,
    required this.linkText,
    required this.onTap,
  });

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
            'Sign Up',
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