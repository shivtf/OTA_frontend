// lib/features/flights/change_request/screens/flight_change_screen.dart
//
// Entry point for the change-request flow. Receives bookingId as an argument.
// Internally routes between Step 1 (form), Step 2 (offers), Step 3 (success).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../providers/flight_change_provider.dart';
import 'change_form_screen.dart';
import 'change_offers_screen.dart';
import 'change_success_screen.dart';

class FlightChangeScreen extends StatefulWidget {
  final String bookingId;

  const FlightChangeScreen({super.key, required this.bookingId});

  @override
  State<FlightChangeScreen> createState() => _FlightChangeScreenState();
}

class _FlightChangeScreenState extends State<FlightChangeScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off slice-id fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FlightChangeProvider>().init(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FlightChangeProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context, provider),
          body: _buildBody(context, provider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, FlightChangeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title;
    switch (provider.step) {
      case ChangeStep.form:
        title = 'Change Flight';
      case ChangeStep.offers:
        title = 'Available Options';
      case ChangeStep.confirming:
        title = 'Confirming Change';
      case ChangeStep.success:
        title = 'Change Confirmed';
      case ChangeStep.error:
        title = 'Change Flight';
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: provider.step == ChangeStep.success
          ? null
          : IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary,
          size: AppSizes.iconSM,
        ),
        onPressed: () {
          if (provider.step == ChangeStep.offers) {
            provider.goBackToForm();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      // Step indicator pill
      bottom: provider.step == ChangeStep.form ||
          provider.step == ChangeStep.offers
          ? PreferredSize(
        preferredSize: const Size.fromHeight(32),
        child: _StepIndicator(
          currentStep: provider.step == ChangeStep.form ? 1 : 2,
        ),
      )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, FlightChangeProvider provider) {
    // Initial loading (fetching slice_id)
    if (provider.isLoading && provider.step == ChangeStep.form &&
        provider.sliceId == null) {
      return const _LoadingBody(message: 'Loading booking details…');
    }

    switch (provider.step) {
      case ChangeStep.form:
        return ChangeFormScreen(provider: provider);

      case ChangeStep.offers:
        return ChangeOffersScreen(provider: provider);

      case ChangeStep.confirming:
        return const _LoadingBody(
          message: 'Submitting your change to the airline…\nThis may take a few seconds.',
        );

      case ChangeStep.success:
        return ChangeSuccessScreen(
          provider: provider,
          onDone: () => Navigator.of(context).pop(true),
        );

      case ChangeStep.error:
        return _ErrorBody(
          message: provider.errorMessage ?? 'Something went wrong.',
          onRetry: () => provider.init(widget.bookingId),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step indicator
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep; // 1 or 2

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingSM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepDot(number: 1, label: 'Search', isActive: currentStep == 1, isDone: currentStep > 1),
          _StepLine(isActive: currentStep >= 2),
          _StepDot(number: 2, label: 'Pick Offer', isActive: currentStep == 2, isDone: false),
          _StepLine(isActive: false),
          _StepDot(number: 3, label: 'Confirm', isActive: false, isDone: false),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color textColor;

    if (isDone) {
      bg = AppColors.success;
      textColor = Colors.white;
    } else if (isActive) {
      bg = AppColors.primaryStart;
      textColor = Colors.white;
    } else {
      bg = isDark ? AppColors.darkBorder : AppColors.lightBorder;
      textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                : Text(
              '$number',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontXS,
            color: isActive || isDone
                ? AppColors.primaryStart
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryStart
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets used inline
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  final String message;
  const _LoadingBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primaryStart),
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryStart,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSizes.paddingLG),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingSM),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXL),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
