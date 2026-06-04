// lib/features/flights/change_request/widgets/change_flight_button.dart
//
// A button widget that triggers the change-request flow.
// It ONLY renders when the booking status is "CONFIRMED".
// Drop this into any booking detail screen.
//
// Usage:
//   ChangeFlightButton(
//     bookingId: booking.id,
//     bookingStatus: booking.status, // e.g. "CONFIRMED", "PENDING", "CANCELLED"
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/constants/app_colors.dart';
import '../../../../../../core/constants/app_sizes.dart';
import '../providers/flight_change_provider.dart';
import '../screens/flight_change_screen.dart';

class ChangeFlightButton extends StatelessWidget {
  /// The booking's UUID (used in API calls).
  final String bookingId;

  /// The booking status string as returned by the API.
  /// Only "CONFIRMED" status renders this button; all others render nothing.
  final String bookingStatus;

  /// Optional: compact style (used inside cards / list rows).
  final bool compact;

  const ChangeFlightButton({
    super.key,
    required this.bookingId,
    required this.bookingStatus,
    this.compact = false,
  });

  static const _confirmedStatus = 'CONFIRMED';

  @override
  Widget build(BuildContext context) {
    // Gate: only CONFIRMED bookings can be changed
    if (bookingStatus.toUpperCase() != _confirmedStatus) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return _CompactButton(
        bookingId: bookingId,
        onTap: () => _openChangeFlow(context),
      );
    }

    return _FullButton(
      onTap: () => _openChangeFlow(context),
    );
  }

  Future<void> _openChangeFlow(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => FlightChangeProvider(),
          child: FlightChangeScreen(bookingId: bookingId),
        ),
        transitionsBuilder: (_, anim, __, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return SlideTransition(position: slide, child: child);
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );

    // result == true means a change was confirmed; caller can refresh UI
    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Flight changed successfully!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          margin: const EdgeInsets.all(AppSizes.paddingMD),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-width button variant
// ─────────────────────────────────────────────────────────────────────────────

class _FullButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FullButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.buttonHeight,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: AppColors.primaryStart,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          foregroundColor: AppColors.primaryStart,
        ),
        icon: const Icon(Icons.swap_horiz_rounded, size: AppSizes.iconSM),
        label: Text(
          'Change Flight',
          style: GoogleFonts.nunito(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact chip variant (e.g. inside a booking card)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactButton extends StatelessWidget {
  final String bookingId;
  final VoidCallback onTap;

  const _CompactButton({
    required this.bookingId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: AppSizes.paddingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusCircle),
          border: Border.all(
            color: AppColors.primaryStart.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              size: 14,
              color: AppColors.primaryStart,
            ),
            const SizedBox(width: 4),
            Text(
              'Change',
              style: GoogleFonts.nunito(
                fontSize: AppSizes.fontXS,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryStart,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
