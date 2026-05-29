// // lib/features/home/screens/home_screen.dart
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/app_colors.dart';
// import '../../../core/constants/app_sizes.dart';
// import '../../../core/routes/app_routes.dart';
// import '../../../core/theme/theme_controller.dart';
// import '../../../features/flights/models/flight_model.dart';
// import '../../../shared/widgets/wanderly_nav_bar.dart';
// import '../widgets/deal_card.dart';
// import '../widgets/destination_card.dart';
// import '../widgets/home_search_bar.dart';
// import '../../home/widgets/quick_category_row.dart';
// import '../../profiles/screens/profile_screen.dart';
// import '../../profiles/screens/my_bookings_screen.dart';
// import '../../profiles/screens/update_profile_screen.dart';
// import '../../auth/providers/auth_provider.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _navIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final tc = context.watch<ThemeController>();
//
//     return Scaffold(
//       backgroundColor:
//           isDark ? AppColors.darkBackground : AppColors.lightBackground,
//       body: IndexedStack(
//         index: _navIndex,
//         children: [
//           _HomeTab(isDark: isDark, tc: tc),
//           _PlaceholderTab(
//               icon: Icons.flight_rounded, label: 'Flights', isDark: isDark),
//           _PlaceholderTab(
//               icon: Icons.hotel_rounded, label: 'Hotels', isDark: isDark),
//           _PlaceholderTab(
//               icon: Icons.directions_car_rounded,
//               label: 'Cars',
//               isDark: isDark),
//           const ProfileScreen(),
//         ],
//       ),
//       bottomNavigationBar: WanderlyNavBar(
//         currentIndex: _navIndex,
//         onTap: (i) {
//           if (i == 1) {
//             Navigator.of(context).pushNamed(AppRoutes.flightSearch);
//             return;
//           }
//           if (i == 2) {
//             Navigator.of(context).pushNamed(AppRoutes.hotelSearch);
//             return;
//           }
//           if (i == 3) {
//             Navigator.of(context).pushNamed(AppRoutes.carSearch);
//             return;
//           }
//           setState(() => _navIndex = i);
//         },
//       ),
//     );
//   }
// }
//
// // ─── Main Home Tab ────────────────────────────────────────────────────────────
// class _HomeTab extends StatelessWidget {
//   final bool isDark;
//   final ThemeController tc;
//   const _HomeTab({required this.isDark, required this.tc});
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomScrollView(
//       slivers: [
//         SliverToBoxAdapter(child: _HomeHeader(isDark: isDark, tc: tc)),
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
//             child: HomeSearchBar(isDark: isDark),
//           ),
//         ),
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
//             child: QuickCategoryRow(isDark: isDark),
//           ),
//         ),
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Popular Destinations',
//                   style: TextStyle(
//                     fontSize: AppSizes.fontLG,
//                     fontWeight: FontWeight.w700,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.lightTextPrimary,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () {},
//                   child: const Text(
//                     'See all',
//                     style: TextStyle(
//                       fontSize: AppSizes.fontSM,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryStart,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SliverToBoxAdapter(
//           child: SizedBox(
//             height: 200,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//               itemCount: FlightData.popularDestinations.length,
//               itemBuilder: (ctx, i) => DestinationCard(
//                 destination: FlightData.popularDestinations[i],
//                 isDark: isDark,
//               ),
//             ),
//           ),
//         ),
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Hot Deals ✈️',
//                   style: TextStyle(
//                     fontSize: AppSizes.fontLG,
//                     fontWeight: FontWeight.w700,
//                     color: isDark
//                         ? AppColors.darkTextPrimary
//                         : AppColors.lightTextPrimary,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () =>
//                       Navigator.of(context).pushNamed(AppRoutes.flightSearch),
//                   child: const Text(
//                     'See all',
//                     style: TextStyle(
//                       fontSize: AppSizes.fontSM,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.primaryStart,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (ctx, i) {
//               final flights = FlightData.search(from: '', to: '');
//               if (i >= flights.length) return null;
//               return Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
//                 child: DealCard(flight: flights[i], isDark: isDark),
//               );
//             },
//             childCount: 3,
//           ),
//         ),
//         const SliverToBoxAdapter(child: SizedBox(height: 24)),
//       ],
//     );
//   }
// }
//
// // ─── Header ───────────────────────────────────────────────────────────────────
// class _HomeHeader extends StatelessWidget {
//   final bool isDark;
//   final ThemeController tc;
//   const _HomeHeader({required this.isDark, required this.tc});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: isDark
//             ? const LinearGradient(
//                 colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               )
//             : const LinearGradient(
//                 colors: [Color(0xFF6C3CE1), Color(0xFF9B5CFF)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(32),
//           bottomRight: Radius.circular(32),
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           _greeting(),
//                           style: TextStyle(
//                             fontSize: AppSizes.fontSM,
//                             color: Colors.white.withValues(alpha: 0.7),
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         const Text(
//                           'Where to next? 🌍',
//                           style: TextStyle(
//                             fontSize: AppSizes.fontXXL,
//                             fontWeight: FontWeight.w800,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Theme toggle
//                   GestureDetector(
//                     onTap: tc.toggleTheme,
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       margin: const EdgeInsets.only(right: 10),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withValues(alpha: 0.15),
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                             color: Colors.white.withValues(alpha: 0.25)),
//                       ),
//                       child: Icon(
//                         isDark
//                             ? Icons.light_mode_rounded
//                             : Icons.dark_mode_rounded,
//                         color: Colors.white,
//                         size: 18,
//                       ),
//                     ),
//                   ),
//                   // Avatar with initials + dropdown
//                   _ProfileAvatarButton(isDark: isDark),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   _StatChip(
//                       icon: Icons.flight_takeoff_rounded, label: '12 Trips'),
//                   const SizedBox(width: 10),
//                   _StatChip(icon: Icons.star_rounded, label: '4.9 Rating'),
//                   const SizedBox(width: 10),
//                   _StatChip(
//                       icon: Icons.location_on_rounded, label: '8 Countries'),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _greeting() {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good morning, Traveler 👋';
//     if (h < 17) return 'Good afternoon, Traveler 👋';
//     return 'Good evening, Traveler 👋';
//   }
// }
//
// // ─── Profile Avatar Button with Dropdown ──────────────────────────────────────
// class _ProfileAvatarButton extends StatelessWidget {
//   final bool isDark;
//   const _ProfileAvatarButton({required this.isDark});
//
//   void _showMenu(BuildContext context) {
//     final user = context.read<AuthProvider>().user;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) => _ProfileMenuSheet(
//         isDark: isDark,
//         userName: user?.fullName ?? 'Traveler',
//         userEmail: user?.email ?? '',
//         initials: user != null
//             ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
//                 .toUpperCase()
//             : '?',
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final user = context.watch<AuthProvider>().user;
//     final initials = user != null
//         ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
//             .toUpperCase()
//         : '?';
//
//     return GestureDetector(
//       onTap: () => _showMenu(context),
//       child: Container(
//         width: 44,
//         height: 44,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           gradient: const LinearGradient(
//             colors: [Color(0xFFFFD166), Color(0xFFFF6B8A)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           border:
//               Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.2),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             initials,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.w900,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Profile Menu Bottom Sheet ────────────────────────────────────────────────
// class _ProfileMenuSheet extends StatelessWidget {
//   final bool isDark;
//   final String userName;
//   final String userEmail;
//   final String initials;
//
//   const _ProfileMenuSheet({
//     required this.isDark,
//     required this.userName,
//     required this.userEmail,
//     required this.initials,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.darkCard : AppColors.lightCard,
//         borderRadius: BorderRadius.circular(28),
//         border: Border.all(
//           color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
//             blurRadius: 32,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Drag handle
//           Container(
//             width: 36,
//             height: 4,
//             margin: const EdgeInsets.only(top: 12, bottom: 20),
//             decoration: BoxDecoration(
//               color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//
//           // User info header
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//             child: Row(
//               children: [
//                 Container(
//                   width: 52,
//                   height: 52,
//                   decoration: const BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFFFD166), Color(0xFFFF6B8A)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: Center(
//                     child: Text(
//                       initials,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 20,
//                         fontWeight: FontWeight.w900,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 14),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         userName,
//                         style: TextStyle(
//                           fontSize: AppSizes.fontMD,
//                           fontWeight: FontWeight.w800,
//                           color: isDark
//                               ? AppColors.darkTextPrimary
//                               : AppColors.lightTextPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         userEmail,
//                         style: TextStyle(
//                           fontSize: AppSizes.fontXS,
//                           color: isDark
//                               ? AppColors.darkTextSecondary
//                               : AppColors.lightTextSecondary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: AppColors.success.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                         color: AppColors.success.withValues(alpha: 0.3)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.verified_rounded,
//                           color: AppColors.success, size: 11),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Verified',
//                         style: TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.success,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Divider(
//             color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//             height: 1,
//             indent: 20,
//             endIndent: 20,
//           ),
//
//           const SizedBox(height: 8),
//
//           // Menu items
//           _MenuItem(
//             icon: Icons.person_outline_rounded,
//             label: 'View Profile',
//             isDark: isDark,
//             onTap: () {
//               Navigator.of(context).pop();
//               // Navigate to dedicated profile screen pushed as route
//               Navigator.of(context).push(
//                 PageRouteBuilder(
//                   pageBuilder: (_, __, ___) => const ProfileScreen(),
//                   transitionsBuilder: (_, anim, __, child) => SlideTransition(
//                     position: Tween<Offset>(
//                             begin: const Offset(1, 0), end: Offset.zero)
//                         .animate(CurvedAnimation(
//                             parent: anim, curve: Curves.easeOutCubic)),
//                     child: child,
//                   ),
//                   transitionDuration: const Duration(milliseconds: 320),
//                 ),
//               );
//             },
//           ),
//
//           _MenuItem(
//             icon: Icons.edit_outlined,
//             label: 'Update Profile',
//             isDark: isDark,
//             onTap: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).push(
//                 PageRouteBuilder(
//                   pageBuilder: (_, __, ___) => const UpdateProfileScreen(),
//                   transitionsBuilder: (_, anim, __, child) => SlideTransition(
//                     position: Tween<Offset>(
//                             begin: const Offset(1, 0), end: Offset.zero)
//                         .animate(CurvedAnimation(
//                             parent: anim, curve: Curves.easeOutCubic)),
//                     child: child,
//                   ),
//                   transitionDuration: const Duration(milliseconds: 320),
//                 ),
//               );
//             },
//           ),
//
//           _MenuItem(
//             icon: Icons.flight_takeoff_rounded,
//             label: 'My Bookings',
//             isDark: isDark,
//             onTap: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).push(
//                 PageRouteBuilder(
//                   pageBuilder: (_, __, ___) => const MyBookingsScreen(),
//                   transitionsBuilder: (_, anim, __, child) => SlideTransition(
//                     position: Tween<Offset>(
//                             begin: const Offset(1, 0), end: Offset.zero)
//                         .animate(CurvedAnimation(
//                             parent: anim, curve: Curves.easeOutCubic)),
//                     child: child,
//                   ),
//                   transitionDuration: const Duration(milliseconds: 320),
//                 ),
//               );
//             },
//           ),
//
//           _MenuItem(
//             icon: Icons.lock_outline_rounded,
//             label: 'Change Password',
//             isDark: isDark,
//             onTap: () {
//               Navigator.of(context).pop();
//               // Placeholder – dedicated screen to be implemented
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: const Text('Change Password coming soon!'),
//                   behavior: SnackBarBehavior.floating,
//                   backgroundColor: AppColors.primaryStart,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   margin: const EdgeInsets.all(16),
//                 ),
//               );
//             },
//           ),
//
//           const SizedBox(height: 8),
//           Divider(
//             color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//             height: 1,
//             indent: 20,
//             endIndent: 20,
//           ),
//           const SizedBox(height: 8),
//
//           // Logout
//           _MenuItem(
//             icon: Icons.logout_rounded,
//             label: 'Sign Out',
//             isDark: isDark,
//             isDestructive: true,
//             onTap: () => _confirmLogout(context, isDark),
//           ),
//
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
//
//   void _confirmLogout(BuildContext context, bool isDark) {
//     Navigator.of(context).pop(); // close menu
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
//       builder: (_) => Padding(
//         padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 36,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 24),
//               decoration: BoxDecoration(
//                   color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
//                   borderRadius: BorderRadius.circular(2)),
//             ),
//             Container(
//               width: 64,
//               height: 64,
//               decoration: BoxDecoration(
//                   color: AppColors.error.withValues(alpha: 0.1),
//                   shape: BoxShape.circle),
//               child:
//                   Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Sign Out?',
//               style: TextStyle(
//                 fontSize: AppSizes.fontXXL,
//                 fontWeight: FontWeight.w800,
//                 color: isDark
//                     ? AppColors.darkTextPrimary
//                     : AppColors.lightTextPrimary,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'You\'ll need to sign in again to access your bookings.',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: AppSizes.fontSM,
//                 color: isDark
//                     ? AppColors.darkTextSecondary
//                     : AppColors.lightTextSecondary,
//               ),
//             ),
//             const SizedBox(height: 28),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton(
//                     onPressed: () => Navigator.pop(context),
//                     style: OutlinedButton.styleFrom(
//                       minimumSize:
//                           const Size(double.infinity, AppSizes.buttonHeightSM),
//                       side: BorderSide(
//                           color: isDark
//                               ? AppColors.darkBorder
//                               : AppColors.lightBorder),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14)),
//                     ),
//                     child: Text(
//                       'Cancel',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w700,
//                         color: isDark
//                             ? AppColors.darkTextPrimary
//                             : AppColors.lightTextPrimary,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       Navigator.pop(context);
//                       await context.read<AuthProvider>().logout();
//                       if (context.mounted) {
//                         Navigator.of(context).pushNamedAndRemoveUntil(
//                             AppRoutes.login, (_) => false);
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: AppColors.error,
//                       minimumSize:
//                           const Size(double.infinity, AppSizes.buttonHeightSM),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14)),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       'Sign Out',
//                       style: TextStyle(
//                           fontWeight: FontWeight.w700, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _MenuItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isDark;
//   final bool isDestructive;
//   final VoidCallback onTap;
//
//   const _MenuItem({
//     required this.icon,
//     required this.label,
//     required this.isDark,
//     required this.onTap,
//     this.isDestructive = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final color = isDestructive
//         ? AppColors.error
//         : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
//     final iconBg = isDestructive
//         ? AppColors.error.withValues(alpha: 0.1)
//         : AppColors.primaryStart.withValues(alpha: 0.08);
//     final iconColor = isDestructive ? AppColors.error : AppColors.primaryStart;
//
//     return GestureDetector(
//       onTap: onTap,
//       behavior: HitTestBehavior.opaque,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: isDestructive
//                 ? AppColors.error.withValues(alpha: 0.04)
//                 : Colors.transparent,
//             borderRadius: BorderRadius.circular(14),
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: iconBg,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, color: iconColor, size: 18),
//               ),
//               const SizedBox(width: 14),
//               Expanded(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: AppSizes.fontMD,
//                     fontWeight: FontWeight.w600,
//                     color: color,
//                   ),
//                 ),
//               ),
//               Icon(
//                 Icons.chevron_right_rounded,
//                 color: isDestructive
//                     ? AppColors.error.withValues(alpha: 0.5)
//                     : (isDark
//                         ? AppColors.darkTextSecondary
//                         : AppColors.lightTextSecondary),
//                 size: 20,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // ─── Stat Chip ────────────────────────────────────────────────────────────────
// class _StatChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _StatChip({required this.icon, required this.label});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.15),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: Colors.white, size: 13),
//           const SizedBox(width: 5),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 11,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ─── Placeholder tabs ─────────────────────────────────────────────────────────
// class _PlaceholderTab extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool isDark;
//   const _PlaceholderTab(
//       {required this.icon, required this.label, required this.isDark});
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 72,
//             height: 72,
//             decoration: BoxDecoration(
//               gradient: AppColors.primaryGradient,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: Colors.white, size: 32),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             '$label\nComing Soon',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: AppSizes.fontLG,
//               fontWeight: FontWeight.w700,
//               color: isDark
//                   ? AppColors.darkTextPrimary
//                   : AppColors.lightTextPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'This feature is under construction.',
//             style: TextStyle(
//               fontSize: AppSizes.fontSM,
//               color: isDark
//                   ? AppColors.darkTextSecondary
//                   : AppColors.lightTextSecondary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/flights/models/flight_model.dart';
import '../../../shared/widgets/wanderly_nav_bar.dart';
import '../widgets/deal_card.dart';
import '../widgets/destination_card.dart';
import '../widgets/home_search_bar.dart';
import '../../home/widgets/quick_category_row.dart';
import '../../profiles/screens/profile_screen.dart';
import '../../profiles/screens/my_bookings_screen.dart';
import '../../profiles/screens/update_profile_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/change_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(isDark: isDark, tc: tc),
          _PlaceholderTab(
              icon: Icons.flight_rounded, label: 'Flights', isDark: isDark),
          _PlaceholderTab(
              icon: Icons.hotel_rounded, label: 'Hotels', isDark: isDark),
          _PlaceholderTab(
              icon: Icons.directions_car_rounded,
              label: 'Cars',
              isDark: isDark),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: WanderlyNavBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pushNamed(AppRoutes.flightSearch);
            return;
          }
          if (i == 2) {
            Navigator.of(context).pushNamed(AppRoutes.hotelSearch);
            return;
          }
          if (i == 3) {
            Navigator.of(context).pushNamed(AppRoutes.carSearch);
            return;
          }
          setState(() => _navIndex = i);
        },
      ),
    );
  }
}

// ─── Main Home Tab ────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final bool isDark;
  final ThemeController tc;
  const _HomeTab({required this.isDark, required this.tc});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HomeHeader(isDark: isDark, tc: tc)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: HomeSearchBar(isDark: isDark),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: QuickCategoryRow(isDark: isDark),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Destinations',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              itemCount: FlightData.popularDestinations.length,
              itemBuilder: (ctx, i) => DestinationCard(
                destination: FlightData.popularDestinations[i],
                isDark: isDark,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hot Deals ✈️',
                  style: TextStyle(
                    fontSize: AppSizes.fontLG,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.flightSearch),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontSize: AppSizes.fontSM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (ctx, i) {
              final flights = FlightData.search(from: '', to: '');
              if (i >= flights.length) return null;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: DealCard(flight: flights[i], isDark: isDark),
              );
            },
            childCount: 3,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final bool isDark;
  final ThemeController tc;
  const _HomeHeader({required this.isDark, required this.tc});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.firstName.isNotEmpty == true)
        ? user!.firstName
        : 'Traveler';

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
          colors: [Color(0xFF110B2E), Color(0xFF1A1635)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        )
            : const LinearGradient(
          colors: [Color(0xFF6C3CE1), Color(0xFF9B5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Single row: greeting + theme toggle + avatar ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      _greeting(firstName),
                      style: TextStyle(
                        fontSize: AppSizes.fontMD, // increased from fontSM
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Theme toggle — smaller (34×34)
                  GestureDetector(
                    onTap: tc.toggleTheme,
                    child: Container(
                      width: 34,
                      height: 34,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // Avatar — smaller (36×36)
                  _ProfileAvatarButton(isDark: isDark),
                ],
              ),
              const SizedBox(height: 6),
              // ── Where to next on its own line ──
              const Text(
                'Where to next? 🌍',
                style: TextStyle(
                  fontSize: AppSizes.fontXXL,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatChip(
                      icon: Icons.flight_takeoff_rounded, label: '12 Trips'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.star_rounded, label: '4.9 Rating'),
                  const SizedBox(width: 10),
                  _StatChip(
                      icon: Icons.location_on_rounded, label: '8 Countries'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting(String name) {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, $name 👋';
    if (h < 17) return 'Good afternoon, $name 👋';
    return 'Good evening, $name 👋';
  }
}

// ─── Profile Avatar Button with Dropdown ──────────────────────────────────────
class _ProfileAvatarButton extends StatelessWidget {
  final bool isDark;
  const _ProfileAvatarButton({required this.isDark});

  void _showMenu(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileMenuSheet(
        isDark: isDark,
        userName: user?.fullName ?? 'Traveler',
        userEmail: user?.email ?? '',
        initials: user != null
            ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
            .toUpperCase()
            : '?',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final initials = user != null
        ? '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'
        .toUpperCase()
        : '?';

    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD166), Color(0xFFFF6B8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
          Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Profile Menu Bottom Sheet ────────────────────────────────────────────────
class _ProfileMenuSheet extends StatelessWidget {
  final bool isDark;
  final String userName;
  final String userEmail;
  final String initials;

  const _ProfileMenuSheet({
    required this.isDark,
    required this.userName,
    required this.userEmail,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // User info header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD166), Color(0xFFFF6B8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: AppSizes.fontMD,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: TextStyle(
                          fontSize: AppSizes.fontXS,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.success, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),

          const SizedBox(height: 8),

          // Menu items
          _MenuItem(
            icon: Icons.person_outline_rounded,
            label: 'View Profile',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              // Navigate to dedicated profile screen pushed as route
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ProfileScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 320),
                ),
              );
            },
          ),

          _MenuItem(
            icon: Icons.edit_outlined,
            label: 'Update Profile',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const UpdateProfileScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 320),
                ),
              );
            },
          ),

          _MenuItem(
            icon: Icons.flight_takeoff_rounded,
            label: 'My Bookings',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const MyBookingsScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 320),
                ),
              );
            },
          ),

          _MenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            isDark: isDark,
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ChangePasswordScreen(),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(1, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                    child: child,
                  ),
                  transitionDuration: const Duration(milliseconds: 320),
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 8),

          // Logout
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            isDark: isDark,
            isDestructive: true,
            onTap: () => _confirmLogout(context, isDark),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, bool isDark) {
    Navigator.of(context).pop(); // close menu
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
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
            Text(
              'Sign Out?',
              style: TextStyle(
                fontSize: AppSizes.fontXXL,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll need to sign in again to access your bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final rootNav =
                          Navigator.of(sheetCtx, rootNavigator: true);
                      await sheetCtx.read<AuthProvider>().logout();
                      rootNav.pushNamedAndRemoveUntil(
                          AppRoutes.login, (_) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize:
                      const Size(double.infinity, AppSizes.buttonHeightSM),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final iconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.primaryStart.withValues(alpha: 0.08);
    final iconColor = isDestructive ? AppColors.error : AppColors.primaryStart;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppSizes.fontMD,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive
                    ? AppColors.error.withValues(alpha: 0.5)
                    : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Placeholder tabs ─────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _PlaceholderTab(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            '$label\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.fontLG,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature is under construction.',
            style: TextStyle(
              fontSize: AppSizes.fontSM,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}