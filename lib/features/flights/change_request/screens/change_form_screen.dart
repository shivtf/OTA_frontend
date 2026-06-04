// lib/features/flights/change_request/screens/change_form_screen.dart
//
// Step 1 of the change flow — the user enters new flight details.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../providers/flight_change_provider.dart';

class ChangeFormScreen extends StatelessWidget {
  final FlightChangeProvider provider;

  const ChangeFormScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          _InfoBanner(isDark: isDark),
          const SizedBox(height: AppSizes.paddingLG),

          // Form card
          _FormCard(isDark: isDark, provider: provider),
          const SizedBox(height: AppSizes.paddingLG),

          // Error message
          if (provider.errorMessage != null) ...[
            _ErrorBanner(message: provider.errorMessage!),
            const SizedBox(height: AppSizes.paddingMD),
          ],

          // Submit button
          _SubmitButton(provider: provider),
          const SizedBox(height: AppSizes.paddingXL),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: AppColors.primaryStart.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryStart,
            size: AppSizes.iconSM,
          ),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Text(
              'You can only change confirmed bookings. Enter the new flight details below and we\'ll find available options for you.',
              style: GoogleFonts.nunito(
                fontSize: AppSizes.fontSM,
                color: AppColors.primaryStart,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatefulWidget {
  final bool isDark;
  final FlightChangeProvider provider;

  const _FormCard({required this.isDark, required this.provider});

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  late final TextEditingController _originCtrl;
  late final TextEditingController _destinationCtrl;

  static const _cabinOptions = [
    ('economy', 'Economy'),
    ('premium_economy', 'Premium Economy'),
    ('business', 'Business'),
    ('first', 'First'),
  ];

  @override
  void initState() {
    super.initState();
    _originCtrl =
        TextEditingController(text: widget.provider.origin);
    _destinationCtrl =
        TextEditingController(text: widget.provider.destination);
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final provider = widget.provider;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                    BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.flight_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSM),
                Text(
                  'New Flight Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingLG),

            // Origin
            _label(context, 'From (IATA code)'),
            const SizedBox(height: AppSizes.paddingXS),
            _AirportField(
              controller: _originCtrl,
              hint: 'e.g. LHR',
              icon: Icons.flight_takeoff_rounded,
              onChanged: (v) => provider.origin = v.toUpperCase(),
            ),
            const SizedBox(height: AppSizes.paddingMD),

            // Destination
            _label(context, 'To (IATA code)'),
            const SizedBox(height: AppSizes.paddingXS),
            _AirportField(
              controller: _destinationCtrl,
              hint: 'e.g. JFK',
              icon: Icons.flight_land_rounded,
              onChanged: (v) => provider.destination = v.toUpperCase(),
            ),
            const SizedBox(height: AppSizes.paddingMD),

            // Departure date
            _label(context, 'New Departure Date'),
            const SizedBox(height: AppSizes.paddingXS),
            _DatePickerField(
              isDark: isDark,
              selectedDate: provider.departureDate,
              onDateSelected: (d) {
                provider.departureDate = d;
                // Trigger rebuild — provider is a ChangeNotifier but we call
                // setState here since this is a StatefulWidget child
                (context as Element).markNeedsBuild();
              },
            ),
            const SizedBox(height: AppSizes.paddingMD),

            // Cabin class
            _label(context, 'Cabin Class'),
            const SizedBox(height: AppSizes.paddingXS),
            _CabinSelector(
              isDark: isDark,
              options: _cabinOptions,
              selected: provider.cabinClass,
              onSelected: (v) {
                provider.cabinClass = v;
                (context as Element).markNeedsBuild();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final isDark = widget.isDark;
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w600,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _AirportField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _AirportField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.characters,
      maxLength: 3,
      style: GoogleFonts.nunito(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, size: AppSizes.iconSM, color: AppColors.primaryStart),
        filled: true,
        fillColor:
        isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          borderSide:
          const BorderSide(color: AppColors.primaryStart, width: 2),
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final bool isDark;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerField({
    required this.isDark,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate:
          selectedDate ?? now.add(const Duration(days: 1)),
          firstDate: now.add(const Duration(days: 1)),
          lastDate: now.add(const Duration(days: 365)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primaryStart,
                brightness: isDark ? Brightness.dark : Brightness.light,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        height: AppSizes.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: AppSizes.iconSM,
              color: AppColors.primaryStart,
            ),
            const SizedBox(width: AppSizes.paddingSM),
            Text(
              hasDate
                  ? '${selectedDate!.day.toString().padLeft(2, '0')} / '
                  '${selectedDate!.month.toString().padLeft(2, '0')} / '
                  '${selectedDate!.year}'
                  : 'Select departure date',
              style: GoogleFonts.nunito(
                fontSize: AppSizes.fontMD,
                color: hasDate
                    ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary)
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
                fontWeight:
                hasDate ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CabinSelector extends StatelessWidget {
  final bool isDark;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CabinSelector({
    required this.isDark,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingSM,
      runSpacing: AppSizes.paddingSM,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
              vertical: AppSizes.paddingSM,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.darkCard : AppColors.lightBackground),
              borderRadius:
              BorderRadius.circular(AppSizes.radiusCircle),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: AppSizes.fontSM,
                fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: AppSizes.iconSM),
          const SizedBox(width: AppSizes.paddingSM),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                  fontSize: AppSizes.fontSM,
                  color: AppColors.error,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final FlightChangeProvider provider;
  const _SubmitButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.buttonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: provider.isLoading ? null : provider.submitChangeRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
        icon: provider.isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Icon(Icons.search_rounded),
        label: Text(
          provider.isLoading ? 'Searching…' : 'Search Available Flights',
          style: GoogleFonts.nunito(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
