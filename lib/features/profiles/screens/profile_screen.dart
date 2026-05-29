// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final service = AuthService();
      final profile = await service.getMe();
      if (!mounted) return;
      context.read<AuthProvider>().setUser(profile);
    } catch (_) {}
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHeader(
                user: user,
                isDark: isDark,
                tc: tc,
                isRefreshing: _isRefreshing,
                onRefresh: _refresh,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (user != null) ...[
                      _PersonalInfoCard(user: user, isDark: isDark),
                      const SizedBox(height: 20),
                      _TravelDocCard(user: user, isDark: isDark),
                      const SizedBox(height: 20),
                    ] else if (_isRefreshing) ...[
                      _SkeletonCard(isDark: isDark),
                      const SizedBox(height: 20),
                    ],
                    _SettingsSection(isDark: isDark, tc: tc),
                    const SizedBox(height: 20),
                    _AccountSection(isDark: isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserProfile? user;
  final bool isDark;
  final ThemeController tc;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _ProfileHeader({
    required this.user,
    required this.isDark,
    required this.tc,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user != null
        ? '${user!.firstName.isNotEmpty ? user!.firstName[0] : ''}${user!.lastName.isNotEmpty ? user!.lastName[0] : ''}'
            .toUpperCase()
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF110B2E), Color(0xFF1E183D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
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
                  const Expanded(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppSizes.fontXL,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: isRefreshing ? null : onRefresh,
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isRefreshing
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 18),
                    ),
                  ),
                  GestureDetector(
                    onTap: tc.toggleTheme,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD166), Color(0xFFFF6B8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (user != null) ...[
                Text(
                  user!.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppSizes.fontXL,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user!.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: AppSizes.fontSM,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(
                        icon: Icons.verified_rounded,
                        label: 'Verified',
                        color: AppColors.success),
                    const SizedBox(width: 8),
                    _Badge(
                        icon: Icons.person_rounded,
                        label: 'Customer',
                        color: AppColors.accentGold),
                  ],
                ),
              ] else ...[
                // Skeleton placeholders
                Container(
                  height: 18,
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 13,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Personal Info Card ─────────────────────────────────────────────────────

class _PersonalInfoCard extends StatelessWidget {
  final UserProfile user;
  final bool isDark;
  const _PersonalInfoCard({required this.user, required this.isDark});

  String _dob() {
    if (user.dateOfBirth == null) return '';
    try {
      final dt = DateTime.parse(user.dateOfBirth!);
      const m = [
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
      return '${m[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return user.dateOfBirth!;
    }
  }

  String _nationality(String code) {
    const map = {
      'IN': '🇮🇳 India',
      'US': '🇺🇸 United States',
      'GB': '🇬🇧 United Kingdom',
      'AE': '🇦🇪 UAE',
      'SG': '🇸🇬 Singapore',
      'AU': '🇦🇺 Australia',
      'CA': '🇨🇦 Canada',
      'DE': '🇩🇪 Germany',
      'FR': '🇫🇷 France',
      'JP': '🇯🇵 Japan',
    };
    return map[code.toUpperCase()] ?? code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final dob = _dob();
    final nat = user.nationality?.isNotEmpty == true
        ? _nationality(user.nationality!)
        : null;

    return _SectionCard(
      isDark: isDark,
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Full Name',
              value: user.fullName,
              isDark: isDark),
          _Div(isDark: isDark),
          _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
              isDark: isDark,
              copyable: true),
          if (user.phone?.isNotEmpty == true) ...[
            _Div(isDark: isDark),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone!,
                isDark: isDark,
                copyable: true),
          ],
          if (dob.isNotEmpty) ...[
            _Div(isDark: isDark),
            _InfoRow(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: dob,
                isDark: isDark),
          ],
          if (nat != null) ...[
            _Div(isDark: isDark),
            _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Nationality',
                value: nat,
                isDark: isDark),
          ],
        ],
      ),
    );
  }
}

// ── Travel Documents ───────────────────────────────────────────────────────

class _TravelDocCard extends StatelessWidget {
  final UserProfile user;
  final bool isDark;
  const _TravelDocCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final has = user.passportNumber?.isNotEmpty == true;
    return _SectionCard(
      isDark: isDark,
      title: 'Travel Documents',
      icon: Icons.card_travel_rounded,
      child: has
          ? _InfoRow(
              icon: Icons.airplane_ticket_outlined,
              label: 'Passport Number',
              value: '•••• •••• ••••',
              isDark: isDark,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('On file',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No passport on file',
                            style: TextStyle(
                                fontSize: AppSizes.fontSM,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary)),
                        Text('Add your passport to speed up booking',
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Settings Section ───────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final bool isDark;
  final ThemeController tc;
  const _SettingsSection({required this.isDark, required this.tc});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      title: 'Preferences',
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          _ToggleRow(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            label: 'Dark Mode',
            value: isDark,
            isDark: isDark,
            onChanged: (_) => tc.toggleTheme(),
          ),
          _Div(isDark: isDark),
          _Tile(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              isDark: isDark,
              onTap: () {}),
          _Div(isDark: isDark),
          _Tile(
              icon: Icons.language_rounded,
              label: 'Language & Region',
              value: 'English',
              isDark: isDark,
              onTap: () {}),
          _Div(isDark: isDark),
          _Tile(
              icon: Icons.currency_exchange_rounded,
              label: 'Currency',
              value: 'USD',
              isDark: isDark,
              onTap: () {}),
        ],
      ),
    );
  }
}

// ── Account Section ────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  final bool isDark;
  const _AccountSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      isDark: isDark,
      title: 'Account',
      icon: Icons.manage_accounts_outlined,
      child: Column(
        children: [
          _Tile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              isDark: isDark,
              onTap: () {}),
          _Div(isDark: isDark),
          _Tile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              isDark: isDark,
              onTap: () {}),
          _Div(isDark: isDark),
          _Tile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              isDark: isDark,
              onTap: () {}),
          _Div(isDark: isDark),
          _LogoutTile(isDark: isDark),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool isDark;
  const _LogoutTile({required this.isDark});

  void _confirm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child:
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Sign Out?',
                style: TextStyle(
                    fontSize: AppSizes.fontXXL,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Text(
              'You\'ll need to sign in again to access your bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppSizes.fontSM,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                          const Size(double.infinity, AppSizes.buttonHeightSM),
                      side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login, (_) => false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize:
                          const Size(double.infinity, AppSizes.buttonHeightSM),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Sign Out',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirm(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Sign Out',
                  style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.error.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loader card ───────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  const _SkeletonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.darkCard : AppColors.lightCard;
    final shimmer = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(color: shimmer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 10,
                          width: 80,
                          color: shimmer,
                          margin: const EdgeInsets.only(bottom: 6)),
                      Container(height: 13, color: shimmer),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool copyable;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.copyable = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryStart, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: AppSizes.fontSM,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$label copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                  backgroundColor: AppColors.primaryStart,
                ));
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 16,
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

class _Div extends StatelessWidget {
  final bool isDark;
  const _Div({required this.isDark});

  @override
  Widget build(BuildContext context) => Divider(
      height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder);
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.primaryStart.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.primaryStart, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)),
          ),
          Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primaryStart),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isDark;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.primaryStart.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.primaryStart, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: AppSizes.fontMD,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)),
            ),
            if (value != null)
              Text(value!,
                  style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                size: 20),
          ],
        ),
      ),
    );
  }
}
