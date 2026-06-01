// lib/features/flights/screens/passenger_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/flight_service.dart';
import '../../../shared/widgets/custom_back_button.dart';
import '../../auth/widgets/gradient_button.dart';
import '../providers/flight_booking_provider.dart';

class PassengerFormScreen extends StatefulWidget {
  const PassengerFormScreen({super.key});

  @override
  State<PassengerFormScreen> createState() => _PassengerFormScreenState();
}

class _PassengerFormScreenState extends State<PassengerFormScreen>
    with SingleTickerProviderStateMixin {
  // One GlobalKey per passenger form
  late List<GlobalKey<FormState>> _formKeys;

  // One set of controllers per passenger
  late List<_PassengerControllers> _controllers;

  // Per-passenger dropdown state
  late List<String> _titles;
  late List<String> _genders;
  late List<String> _passengerTypes;

  bool _isSubmitting = false;
  int _currentPassengerIndex = 0; // which card is expanded / being filled

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Passed via route arguments
  FlightOffer? _offer;

  // Derived from offer.passengers list (set in didChangeDependencies)
  List<OfferPassenger> _offerPassengers = [];

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is FlightOffer && _offer == null) {
      _offer = arg;
      _offerPassengers = arg.passengers;

      // Fallback: if the offer has no passengers list, default to 1 adult
      if (_offerPassengers.isEmpty) {
        _offerPassengers = [
          OfferPassenger(id: 'pax_0', type: 'adult'),
        ];
      }

      _initPassengerState(_offerPassengers.length);
    }
  }

  void _initPassengerState(int count) {
    _formKeys = List.generate(count, (_) => GlobalKey<FormState>());
    _controllers = List.generate(count, (_) => _PassengerControllers());
    _titles = List.generate(count, (_) => 'mr');
    _genders = List.generate(count, (_) => 'male');
    _passengerTypes = List.generate(
      count,
          (i) => _offerPassengers[i].type,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validate ALL passenger forms
    bool allValid = true;
    for (int i = 0; i < _formKeys.length; i++) {
      if (!(_formKeys[i].currentState?.validate() ?? false)) {
        allValid = false;
        // Jump to the first invalid passenger tab
        setState(() => _currentPassengerIndex = i);
      }
    }
    if (!allValid) return;
    if (_offer == null) return;

    setState(() => _isSubmitting = true);

    final passengers = List.generate(_controllers.length, (i) {
      final ctrl = _controllers[i];
      return PassengerInput(
        type: _passengerTypes[i],
        title: _titles[i],
        firstName: ctrl.firstName.text.trim(),
        lastName: ctrl.lastName.text.trim(),
        dateOfBirth: ctrl.dob.text.trim(),
        gender: _genders[i] == 'male' ? 'MALE' : 'FEMALE',
        email: ctrl.email.text.trim(),
        phone: ctrl.phone.text.trim(),
        passportNumber: ctrl.passport.text.trim().isEmpty
            ? null
            : ctrl.passport.text.trim(),
        issuingCountry: ctrl.nationality.text.trim().isEmpty
            ? null
            : ctrl.nationality.text.trim().toUpperCase(),
        passportExpiryDate: ctrl.passportExpiry.text.trim().isEmpty
            ? null
            : ctrl.passportExpiry.text.trim(),
      );
    });

    try {
      final provider = FlightBookingProvider();
      provider.selectOffer(_offer!);
      final success = await provider.initBooking(
        passengers: passengers,
        tripType: 'ONE_WAY',
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success && provider.currentBooking != null) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.payment,
          arguments: {
            'booking': provider.currentBooking,
            'offer': _offer,
          },
        );
      } else {
        _showErrorSnack(provider.error ?? 'Booking initialization failed.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnack('An unexpected error occurred. Please try again.');
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, isDark, textPrimary, textSecondary),

            if (_offer != null)
              _buildFlightSummaryPill(
                  _offer!, isDark, textPrimary, textSecondary),

            // Passenger tab selector (only shown when >1 passenger)
            if (_offerPassengers.length > 1)
              _buildPassengerTabBar(isDark, textPrimary, textSecondary),

            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: _offerPassengers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _buildPassengerForm(_currentPassengerIndex, isDark,
                      textPrimary, textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Passenger Tab Bar ──────────────────────────────────────────────────────

  Widget _buildPassengerTabBar(
      bool isDark, Color textPrimary, Color textSecondary) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: List.generate(_offerPassengers.length, (i) {
          final isSelected = i == _currentPassengerIndex;
          final pax = _offerPassengers[i];
          final label = _passengerLabel(pax.type, i);

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentPassengerIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(
                      _passengerIcon(pax.type),
                      size: 16,
                      color: isSelected ? Colors.white : textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _passengerLabel(String type, int index) {
    final typeLabel = type == 'adult'
        ? 'Adult'
        : type == 'child'
        ? 'Child'
        : 'Infant';
    return '${index + 1}. $typeLabel';
  }

  IconData _passengerIcon(String type) {
    switch (type) {
      case 'child':
        return Icons.child_care_rounded;
      case 'infant_without_seat':
        return Icons.baby_changing_station_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ── Single Passenger Form ──────────────────────────────────────────────────

  Widget _buildPassengerForm(
      int index, bool isDark, Color textPrimary, Color textSecondary) {
    final ctrl = _controllers[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKeys[index],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header showing which passenger we're filling
            if (_offerPassengers.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PassengerProgressHeader(
                  current: index + 1,
                  total: _offerPassengers.length,
                  type: _offerPassengers[index].type,
                  isDark: isDark,
                ),
              ),

            _SectionHeader(
              icon: Icons.person_rounded,
              title: 'Personal Information',
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildPersonalSection(index, isDark),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.contact_mail_rounded,
              title: 'Contact Information',
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildContactSection(index, isDark),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.document_scanner_rounded,
              title: 'Travel Document',
              subtitle: 'Optional',
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _buildDocumentSection(index, isDark),
            const SizedBox(height: 32),

            // Navigation between passengers OR final submit
            if (_offerPassengers.length > 1)
              _buildNavigationButtons(index, isDark)
            else
              _buildSubmitButton(),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Your data is encrypted and secure',
                style: TextStyle(
                  fontSize: AppSizes.fontXS,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(int index, bool isDark) {
    final isLast = index == _offerPassengers.length - 1;

    return Column(
      children: [
        if (!isLast)
          GradientButton(
            text: 'Next Passenger',
            icon: Icons.arrow_forward_rounded,
            isLoading: false,
            onPressed: () {
              if (_formKeys[index].currentState?.validate() ?? false) {
                setState(() => _currentPassengerIndex = index + 1);
              }
            },
          )
        else
          _buildSubmitButton(),
        if (index > 0) ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => setState(() => _currentPassengerIndex = index - 1),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Previous Passenger'),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GradientButton(
      text: 'Initialize Booking',
      icon: Icons.rocket_launch_rounded,
      isLoading: _isSubmitting,
      onPressed: _isSubmitting ? null : _submit,
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, bool isDark, Color textPrimary,
      Color textSecondary) {
    final total = _offerPassengers.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
      child: Row(
        children: [
          const CustomBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger Details',
                  style: TextStyle(
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  total > 1
                      ? '$total passengers · fill each tab'
                      : 'Fill in the details to initialize your booking',
                  style: TextStyle(
                    fontSize: AppSizes.fontXS,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Step 1 of 2',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Flight Summary Pill ────────────────────────────────────────────────────

  Widget _buildFlightSummaryPill(
      FlightOffer offer, bool isDark, Color textPrimary, Color textSecondary) {
    final slice = offer.outbound;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
            const Icon(Icons.flight_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slice.origin.iataCode}  →  ${slice.destination.iataCode}',
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '${offer.airline}  ·  ${offer.cabinClass}',
                  style: TextStyle(
                      fontSize: AppSizes.fontXS, color: textSecondary),
                ),
              ],
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: Text(
              '${offer.currency} ${offer.totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: AppSizes.fontLG,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Builders ───────────────────────────────────────────────────────

  Widget _buildPersonalSection(int i, bool isDark) {
    final ctrl = _controllers[i];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DropdownField(
                label: 'Title',
                value: _titles[i],
                items: const ['mr', 'ms', 'mrs', 'dr'],
                displayLabels: const {
                  'mr': 'Mr',
                  'ms': 'Ms',
                  'mrs': 'Mrs',
                  'dr': 'Dr'
                },
                isDark: isDark,
                onChanged: (v) => setState(() => _titles[i] = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: 'Passenger Type',
                value: _passengerTypes[i],
                items: const ['adult', 'child', 'infant_without_seat'],
                displayLabels: const {
                  'adult': 'Adult',
                  'child': 'Child',
                  'infant_without_seat': 'Infant',
                },
                isDark: isDark,
                onChanged: (v) => setState(() => _passengerTypes[i] = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InputField(
                controller: ctrl.firstName,
                label: 'First Name',
                hint: 'John',
                icon: Icons.badge_rounded,
                isDark: isDark,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InputField(
                controller: ctrl.lastName,
                label: 'Last Name',
                hint: 'Doe',
                icon: Icons.badge_outlined,
                isDark: isDark,
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DropdownField(
          label: 'Gender',
          value: _genders[i],
          items: const ['male', 'female'],
          displayLabels: const {'male': 'Male', 'female': 'Female'},
          isDark: isDark,
          onChanged: (v) => setState(() => _genders[i] = v!),
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: ctrl.dob,
          label: 'Date of Birth',
          hint: 'YYYY-MM-DD',
          icon: Icons.cake_rounded,
          isDark: isDark,
          keyboardType: TextInputType.datetime,
          onTap: () => _pickDate(context, ctrl.dob, firstDate: DateTime(1900)),
          readOnly: true,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection(int i, bool isDark) {
    final ctrl = _controllers[i];
    return Column(
      children: [
        _InputField(
          controller: ctrl.email,
          label: 'Email Address',
          hint: 'john.doe@example.com',
          icon: Icons.email_rounded,
          isDark: isDark,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (!v.contains('@') || !v.contains('.')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _InputField(
          controller: ctrl.phone,
          label: 'Phone Number',
          hint: '+919876543210',
          icon: Icons.phone_rounded,
          isDark: isDark,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            if (v.trim().length < 8) return 'Enter a valid phone number';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDocumentSection(int i, bool isDark) {
    final ctrl = _controllers[i];
    return Column(
      children: [
        _InputField(
          controller: ctrl.passport,
          label: 'Passport Number',
          hint: 'P1234567',
          icon: Icons.document_scanner_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InputField(
                controller: ctrl.nationality,
                label: 'Nationality (ISO)',
                hint: 'IN',
                icon: Icons.flag_rounded,
                isDark: isDark,
                maxLength: 2,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  LengthLimitingTextInputFormatter(2),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InputField(
                controller: ctrl.passportExpiry,
                label: 'Passport Expiry',
                hint: 'YYYY-MM-DD',
                icon: Icons.event_rounded,
                isDark: isDark,
                readOnly: true,
                onTap: () => _pickDate(
                  context,
                  ctrl.passportExpiry,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2060),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Date Picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate(
      BuildContext context,
      TextEditingController ctrl, {
        DateTime? firstDate,
        DateTime? lastDate,
      }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryStart,
            brightness: Theme.of(ctx).brightness,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
}

// ── Passenger Controllers ─────────────────────────────────────────────────────

/// Holds all TextEditingControllers for one passenger.
class _PassengerControllers {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final dob = TextEditingController();
  final passport = TextEditingController();
  final passportExpiry = TextEditingController();
  final nationality = TextEditingController(text: 'IN');

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    phone.dispose();
    dob.dispose();
    passport.dispose();
    passportExpiry.dispose();
    nationality.dispose();
  }
}

// ── Progress Header ────────────────────────────────────────────────────────────

class _PassengerProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final String type;
  final bool isDark;

  const _PassengerProgressHeader({
    required this.current,
    required this.total,
    required this.type,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = type == 'adult'
        ? 'Adult'
        : type == 'child'
        ? 'Child'
        : 'Infant';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Passenger $current of $total  ·  $typeLabel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          // Dot progress
          Row(
            children: List.generate(total, (i) {
              return Container(
                margin: const EdgeInsets.only(left: 4),
                width: i + 1 == current ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i + 1 <= current
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryStart.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryStart),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.fontMD,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        color: textPrimary,
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryStart),
        labelStyle: TextStyle(color: textSecondary, fontSize: AppSizes.fontSM),
        hintStyle: TextStyle(
            color: textSecondary.withValues(alpha: 0.5),
            fontSize: AppSizes.fontSM),
        filled: true,
        fillColor: inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.primaryStart, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 10, color: AppColors.error),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String> displayLabels;
  final bool isDark;
  final void Function(String?)? onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.displayLabels,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
    isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      icon: const Icon(Icons.expand_more_rounded,
          color: AppColors.darkTextSecondary, size: 20),
      style: TextStyle(
        color: textPrimary,
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSecondary, fontSize: AppSizes.fontSM),
        filled: true,
        fillColor: inputBg,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.primaryStart, width: 1.5),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
        value: item,
        child: Text(displayLabels[item] ?? item),
      ))
          .toList(),
    );
  }
}