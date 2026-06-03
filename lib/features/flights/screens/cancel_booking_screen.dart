// lib/features/flights/screens/cancel_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/flight_cancel_provider.dart';

// ── Predefined cancel reasons ─────────────────────────────────────────────────

const List<String> _kReasons = [
  'Flight schedule changed',
  'Change in travel plans',
  'Found a better fare',
  'Medical or emergency',
  'Other',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class CancelBookingScreen extends StatefulWidget {
  final String bookingId;
  final String bookingRef;
  final String flightInfo; // e.g. "DEL → DXB · 12 Jun"

  const CancelBookingScreen({
    super.key,
    required this.bookingId,
    required this.bookingRef,
    required this.flightInfo,
  });

  @override
  State<CancelBookingScreen> createState() => _CancelBookingScreenState();
}

class _CancelBookingScreenState extends State<CancelBookingScreen> {
  String? _selectedReason;
  final _otherController = TextEditingController();
  final _otherFocus = FocusNode();
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  String? get _effectiveReason {
    if (_selectedReason == null) return null;
    if (_selectedReason == 'Other') {
      final t = _otherController.text.trim();
      return t.isEmpty ? null : t;
    }
    return _selectedReason;
  }

  @override
  void dispose() {
    _otherController.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  // ── Confirm dialog ──────────────────────────────────────────────────────────
  Future<bool> _confirmDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
          dark ? AppColors.darkCard : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Cancel this flight?',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)),
          content: Text(
            'This action cannot be undone. Refund eligibility depends on the fare rules.',
            style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Go back',
                  style: TextStyle(color: AppColors.primaryStart)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    ) ??
        false;
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit(FlightCancelProvider provider) async {
    final reason = _effectiveReason;
    if (reason == null) return;

    final confirmed = await _confirmDialog();
    if (!confirmed || !mounted) return;

    final ok = await provider.cancelBooking(
      bookingId: widget.bookingId,
      reason: reason,
    );

    if (ok && mounted) {
      _showResultSheet(provider.result!);
    }
  }

  // ── Result bottom sheet ─────────────────────────────────────────────────────
  void _showResultSheet(CancelResult result) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultSheet(
        result: result,
        onDone: () {
          Navigator.of(context)
            ..pop() // close sheet
            ..pop(); // close cancel screen → back to booking detail
        },
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = isDark;

    return ChangeNotifierProvider(
      create: (_) => FlightCancelProvider(),
      child: Consumer<FlightCancelProvider>(
        builder: (ctx, provider, _) {
          return Scaffold(
            backgroundColor:
            dark ? AppColors.darkBackground : AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    size: 20),
                onPressed:
                provider.isLoading ? null : () => Navigator.pop(context),
              ),
              title: Text('Cancel Booking',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: AppSizes.fontLG,
                      color: dark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Booking info card ──────────────────────────────────────
                  _BookingInfoCard(
                    bookingRef: widget.bookingRef,
                    flightInfo: widget.flightInfo,
                    isDark: dark,
                  ),
                  const SizedBox(height: 28),

                  // ── Warning banner ─────────────────────────────────────────
                  _WarningBanner(isDark: dark),
                  const SizedBox(height: 28),

                  // ── Reason heading ─────────────────────────────────────────
                  Text('Reason for cancellation',
                      style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w800,
                          color: dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 4),
                  Text('Please select a reason to continue',
                      style: TextStyle(
                          fontSize: AppSizes.fontSM,
                          color: dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                  const SizedBox(height: 16),

                  // ── Reason tiles ───────────────────────────────────────────
                  ..._kReasons.map((reason) => _ReasonTile(
                    reason: reason,
                    selected: _selectedReason == reason,
                    isDark: dark,
                    onTap: provider.isLoading
                        ? null
                        : () {
                      setState(() => _selectedReason = reason);
                      if (reason != 'Other') {
                        _otherFocus.unfocus();
                      } else {
                        Future.delayed(
                            const Duration(milliseconds: 150),
                                () => _otherFocus.requestFocus());
                      }
                    },
                  )),

                  // ── "Other" text field ─────────────────────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _selectedReason == 'Other'
                        ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _OtherField(
                        controller: _otherController,
                        focusNode: _otherFocus,
                        isDark: dark,
                        enabled: !provider.isLoading,
                        onChanged: (_) => setState(() {}),
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // ── Error ──────────────────────────────────────────────────
                  if (provider.step == CancelStep.failed &&
                      provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ErrorBanner(
                          message: provider.error!, isDark: dark),
                    ),

                  // ── Cancel button ──────────────────────────────────────────
                  _CancelButton(
                    enabled: _effectiveReason != null && !provider.isLoading,
                    isLoading: provider.isLoading,
                    onTap: () => _submit(provider),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _BookingInfoCard extends StatelessWidget {
  final String bookingRef;
  final String flightInfo;
  final bool isDark;

  const _BookingInfoCard({
    required this.bookingRef,
    required this.flightInfo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🛫', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(flightInfo,
                    style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)),
                const SizedBox(height: 3),
                Text(bookingRef,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Cancelling',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final bool isDark;
  const _WarningBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Refund eligibility is based on your fare rules. Non-refundable tickets will not receive a refund.',
              style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String reason;
  final bool selected;
  final bool isDark;
  final VoidCallback? onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryStart.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryStart.withValues(alpha: 0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.primaryStart
                      : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
                  width: selected ? 0 : 1.5,
                ),
                color: selected ? AppColors.primaryStart : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(reason,
                  style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primaryStart
                          : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary))),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const _OtherField({
    required this.controller,
    required this.focusNode,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: 3,
      maxLength: 200,
      onChanged: onChanged,
      style: TextStyle(
          fontSize: AppSizes.fontSM,
          color: isDark
              ? AppColors.darkTextPrimary
              : AppColors.lightTextPrimary),
      decoration: InputDecoration(
        hintText: 'Describe your reason...',
        hintStyle: TextStyle(
            fontSize: AppSizes.fontSM,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
        filled: true,
        fillColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: AppColors.primaryStart, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorBanner({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _CancelButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(16),
              boxShadow: enabled
                  ? [
                BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
                  : [],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
                  : const Text('Cancel Booking',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Result bottom sheet ───────────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  final CancelResult result;
  final VoidCallback onDone;

  const _ResultSheet({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasRefund = result.refund.hasRefund;

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // pill
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: dark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),

          // icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 34),
          ),
          const SizedBox(height: 16),

          Text('Booking Cancelled',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary)),
          const SizedBox(height: 6),
          Text(result.bookingRef,
              style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  fontWeight: FontWeight.w600,
                  color: dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary)),
          const SizedBox(height: 24),

          // refund info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (hasRefund ? AppColors.success : AppColors.warning)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: (hasRefund
                      ? AppColors.success
                      : AppColors.warning)
                      .withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                        hasRefund
                            ? Icons.account_balance_wallet_outlined
                            : Icons.money_off_rounded,
                        color: hasRefund
                            ? AppColors.success
                            : AppColors.warning,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(
                        hasRefund
                            ? 'Refund: ${result.refund.currency} ${result.refund.amount.toStringAsFixed(2)}'
                            : 'No Refund',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: AppSizes.fontSM,
                            color: hasRefund
                                ? AppColors.success
                                : AppColors.warning)),
                  ],
                ),
                if (result.refund.instructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(result.refund.instructions,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: dark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // done button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryStart,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onDone,
              child: const Text('Done',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}