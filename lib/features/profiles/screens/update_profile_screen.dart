// lib/features/profiles/screens/update_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:country_picker/country_picker.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _phone;
  late TextEditingController _passportNumber;

  Country? _selectedCountry;
  DateTime? _dateOfBirth;

  bool _saving = false;
  bool _passportEditable = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    // Passport is stored encrypted on the backend — never pre-fill with the
    // cipher text. Leave blank; only send if the user types a new value.
    _passportNumber = TextEditingController();

    // Pre-select country from stored ISO code using country_picker
    if (user?.nationality != null && user!.nationality!.isNotEmpty) {
      final code = user.nationality!.toUpperCase();
      try {
        _selectedCountry = CountryParser.parseCountryCode(code);
      } catch (_) {}
    }

    // Pre-fill DOB
    if (user?.dateOfBirth != null && user!.dateOfBirth!.isNotEmpty) {
      try {
        _dateOfBirth = DateTime.parse(user.dateOfBirth!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _passportNumber.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 1),
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryStart,
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: AppColors.primaryStart,
              onPrimary: Colors.white,
              surface: isDark ? AppColors.darkCard : AppColors.lightCard,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  // ── Country picker ───────────────────────────────────────────────
  void _showCountryPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(
        isDark: isDark,
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_selectedCountry != null) 'nationality': _selectedCountry!.countryCode,
      if (_passportNumber.text.trim().isNotEmpty)
        'passportNumber': _passportNumber.text.trim(),
      if (_dateOfBirth != null)
        'dateOfBirth':
        '${_dateOfBirth!.year.toString().padLeft(4, '0')}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
    };

    final ok = await context.read<AuthProvider>().updateProfile(body);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Profile updated!',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
      Navigator.of(context).pop();
    } else {
      final err = context.read<AuthProvider>().error ?? 'Update failed.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Passport edit warning ────────────────────────────────────────
  Future<void> _showPassportEditWarning() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Change Passport Details?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontLG,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'You are about to edit your passport information. Please make sure the new details are accurate before saving.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  height: 1.5,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _passportEditable = true;
        _passportNumber.clear();
      });
    }
  }

  String _formatDob(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().user;

    final initials = user != null
        ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
                  : AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Update Profile',
                          style: TextStyle(
                            fontSize: AppSizes.fontXL,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Info
                    const _SectionLabel(label: 'PERSONAL INFO', isDark: false),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _firstName,
                      label: 'First Name',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _lastName,
                      label: 'Last Name',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _Field(
                      controller: _phone,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      textCapitalization: TextCapitalization.none,
                    ),

                    const SizedBox(height: 24),

                    // Travel Details
                    const _SectionLabel(label: 'TRAVEL DETAILS', isDark: false),
                    const SizedBox(height: 12),

                    // Nationality — uses country_picker
                    _TapField(
                      label: 'Nationality',
                      icon: Icons.flag_outlined,
                      value: _selectedCountry != null
                          ? '${_selectedCountry!.flagEmoji}  ${_selectedCountry!.name}'
                          : null,
                      placeholder: 'Select country',
                      isDark: isDark,
                      onTap: _showCountryPicker,
                    ),
                    const SizedBox(height: 12),

                    // Date of birth
                    _TapField(
                      label: 'Date of Birth',
                      icon: Icons.cake_outlined,
                      value:
                      _dateOfBirth != null ? _formatDob(_dateOfBirth!) : null,
                      placeholder: 'Select date',
                      isDark: isDark,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),

                    _PassportField(
                      controller: _passportNumber,
                      isDark: isDark,
                      isEditable: _passportEditable,
                      onEditTap: _showPassportEditWarning,
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryStart.withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _saving
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white),
                          )
                              : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: AppSizes.fontMD,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Country Picker Bottom Sheet ───────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final bool isDark;
  final Country? selected;
  final ValueChanged<Country> onSelect;

  const _CountryPickerSheet({
    required this.isDark,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _search = TextEditingController();

  // All countries provided by the country_picker package
  late List<Country> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = CountryService().getAll();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _search.text.toLowerCase().trim();
    final all = CountryService().getAll();
    setState(() {
      _filtered = q.isEmpty
          ? all
          : all
          .where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flag_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Nationality',
                      style: TextStyle(
                        fontSize: AppSizes.fontLG,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.primaryStart, size: 20),
                    suffixIcon: _search.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _search.clear();
                        FocusScope.of(context).unfocus();
                      },
                      child: Icon(Icons.close_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          size: 18),
                    )
                        : null,
                    filled: true,
                    fillColor:
                    isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primaryStart, width: 1.5),
                    ),
                  ),
                ),
              ),

              Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1),

              // List
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 40,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                      const SizedBox(height: 10),
                      Text('No countries found',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          )),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final c = _filtered[i];
                    final isSelected =
                        widget.selected?.countryCode == c.countryCode;
                    return GestureDetector(
                      onTap: () => widget.onSelect(c),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryStart
                              .withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Text(c.flagEmoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: AppSizes.fontMD,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryStart
                                      : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                                ),
                              ),
                            ),
                            Text(
                              c.countryCode,
                              style: TextStyle(
                                fontSize: AppSizes.fontXS,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primaryStart
                                    : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle_rounded,
                                  color: AppColors.primaryStart,
                                  size: 18),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: AppSizes.fontSM,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryStart,
        letterSpacing: 0.3,
      ),
    );
  }
}

/// Tap-to-open field (date picker / country picker)
class _TapField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final String placeholder;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TapField({
    required this.label,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final textColor = hasValue
        ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryStart, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Passport field — locked by default, unlocked after warning confirmation
class _PassportField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isEditable;
  final VoidCallback onEditTap;

  const _PassportField({
    required this.controller,
    required this.isDark,
    required this.isEditable,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
    final labelColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field row
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isEditable
                ? fillColor
                : (isDark
                ? AppColors.darkInputBg.withValues(alpha: 0.6)
                : AppColors.lightInputBg.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isEditable ? AppColors.primaryStart : borderColor,
              width: isEditable ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.credit_card_outlined,
                  color: isEditable
                      ? AppColors.primaryStart
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: isEditable
                    ? TextFormField(
                  controller: controller,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Passport Number',
                    hintText: 'Enter new passport number',
                    counterText: '',
                    border: InputBorder.none,
                    labelStyle:
                    TextStyle(color: labelColor, fontSize: AppSizes.fontSM),
                    hintStyle: TextStyle(
                      color: labelColor.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                )
                    : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passport Number',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '••••••••••••••••',
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pencil / lock icon button
              GestureDetector(
                onTap: isEditable ? null : onEditTap,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isEditable
                      ? Icon(
                    Icons.lock_open_rounded,
                    key: const ValueKey('unlocked'),
                    color: AppColors.primaryStart,
                    size: 18,
                  )
                      : Icon(
                    Icons.edit_outlined,
                    key: const ValueKey('locked'),
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Hint text below when editable
        if (isEditable)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 6),
            child: Text(
              'Enter the full passport number exactly as printed.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}


class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLength,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: TextStyle(
        fontSize: AppSizes.fontMD,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AppColors.primaryStart, size: 18),
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontSize: AppSizes.fontSM,
        ),
        hintStyle: TextStyle(
          color: (isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary)
              .withValues(alpha: 0.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primaryStart, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}