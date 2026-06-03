// lib/features/flights/widgets/filter_chip_row.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Sort order for the price chip.
enum PriceSortOrder {
  none,       // no sort applied
  ascending,  // lowest first
  descending, // highest first
}

class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final Set<String> activeFilters;
  final ValueChanged<String> onToggle;
  final VoidCallback? onSort;
  final bool isDark;

  // ── Price sort ─────────────────────────────────────────────────────────────
  /// Current price sort direction. Tapping the chip cycles:
  ///   none → ascending → descending → none
  final PriceSortOrder priceSortOrder;
  final ValueChanged<PriceSortOrder>? onPriceSortChanged;

  // ── Price range (slider filter) ────────────────────────────────────────────
  // final double? activePriceMin;
  // final double? activePriceMax;
  // final void Function(double? min, double? max)? onPriceRangeChanged;
  // final double offerMinPrice;
  // final double offerMaxPrice;
  // final String currency;

  const FilterChipRow({
    super.key,
    required this.filters,
    required this.activeFilters,
    required this.onToggle,
    this.onSort,
    required this.isDark,
    this.priceSortOrder = PriceSortOrder.none,
    this.onPriceSortChanged,
    // this.activePriceMin,
    // this.activePriceMax,
    // this.onPriceRangeChanged,
    // this.offerMinPrice = 0,
    // this.offerMaxPrice = 10000,
    // this.currency = 'USD',
  });

  // bool get _priceFilterActive =>
  //     activePriceMin != null || activePriceMax != null;

  // String get _priceRangeLabel {
  //   if (!_priceFilterActive) return 'Price Range';
  //   final min = activePriceMin?.toStringAsFixed(0) ?? '?';
  //   final max = activePriceMax?.toStringAsFixed(0) ?? '?';
  //   return '$currency $min – $max';
  // }

  /// Cycle to the next sort state.
  PriceSortOrder get _nextSortOrder {
    switch (priceSortOrder) {
      case PriceSortOrder.none:
        return PriceSortOrder.ascending;
      case PriceSortOrder.ascending:
        return PriceSortOrder.descending;
      case PriceSortOrder.descending:
        return PriceSortOrder.none;
    }
  }

  String get _sortChipLabel {
    switch (priceSortOrder) {
      case PriceSortOrder.ascending:
        return 'Price: Low → High';
      case PriceSortOrder.descending:
        return 'Price: High → Low';
      case PriceSortOrder.none:
        return 'Sort by Price';
    }
  }

  IconData get _sortChipIcon {
    switch (priceSortOrder) {
      case PriceSortOrder.ascending:
        return Icons.arrow_upward_rounded;
      case PriceSortOrder.descending:
        return Icons.arrow_downward_rounded;
      case PriceSortOrder.none:
        return Icons.swap_vert_rounded;
    }
  }

  bool get _sortChipActive => priceSortOrder != PriceSortOrder.none;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        children: [
          // ── Static filter chips (Direct, Refundable) ───────────────────────
          ...filters.map((f) => _FilterChip(
            label: f,
            isActive: activeFilters.contains(f),
            isDark: isDark,
            onTap: () => onToggle(f),
          )),

          // ── Price sort chip (asc / desc toggle) ───────────────────────────
          if (onPriceSortChanged != null)
            _SortChip(
              label: _sortChipLabel,
              icon: _sortChipIcon,
              isActive: _sortChipActive,
              isDark: isDark,
              onTap: () => onPriceSortChanged!(_nextSortOrder),
            ),

          // ── Price range filter chip ────────────────────────────────────────
          // if (onPriceRangeChanged != null)
          //   _PriceRangeChip(
          //     label: _priceRangeLabel,
          //     isActive: _priceFilterActive,
          //     isDark: isDark,
          //     onTap: () => _showPriceSheet(context),
          //   ),
        ],
      ),
    );
  }

// void _showPriceSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => _PriceRangeSheet(
//       isDark: isDark,
//       currency: currency,
//       minPrice: offerMinPrice,
//       maxPrice: offerMaxPrice,
//       currentMin: activePriceMin ?? offerMinPrice,
//       currentMax: activePriceMax ?? offerMaxPrice,
//       onApply: (min, max) {
//         final clearMin = min <= offerMinPrice;
//         final clearMax = max >= offerMaxPrice;
//         onPriceRangeChanged?.call(
//           clearMin ? null : min,
//           clearMax ? null : max,
//         );
//       },
//       onClear: () => onPriceRangeChanged?.call(null, null),
//     ),
//   );
// }
}

// ── Generic filter chip ────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.fontSM,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? Colors.white
                : (isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

// ── Price sort chip ────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
    isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive
              ? null
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(
              color:
              isDark ? AppColors.darkBorder : AppColors.lightBorder),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(icon),
                size: 14,
                color: isActive ? Colors.white : inactiveColor,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.fontSM,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Price range chip ───────────────────────────────────────────────────────────

// class _PriceRangeChip extends StatelessWidget {
//   final String label;
//   final bool isActive;
//   final bool isDark;
//   final VoidCallback onTap;
//
//   const _PriceRangeChip({
//     required this.label,
//     required this.isActive,
//     required this.isDark,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final inactiveColor =
//     isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
//
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         margin: const EdgeInsets.only(right: 8),
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           gradient: isActive ? AppColors.primaryGradient : null,
//           color: isActive
//               ? null
//               : (isDark ? AppColors.darkCard : AppColors.lightCard),
//           borderRadius: BorderRadius.circular(20),
//           border: isActive
//               ? null
//               : Border.all(
//               color:
//               isDark ? AppColors.darkBorder : AppColors.lightBorder),
//           boxShadow: isActive
//               ? [
//             BoxShadow(
//               color: AppColors.primaryStart.withValues(alpha: 0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 3),
//             )
//           ]
//               : null,
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(Icons.attach_money_rounded,
//                 size: 14,
//                 color: isActive ? Colors.white : inactiveColor),
//             const SizedBox(width: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: AppSizes.fontSM,
//                 fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
//                 color: isActive ? Colors.white : inactiveColor,
//               ),
//             ),
//             const SizedBox(width: 4),
//             Icon(Icons.keyboard_arrow_down_rounded,
//                 size: 14,
//                 color: isActive ? Colors.white : inactiveColor),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ── Price range bottom sheet ──────────────────────────────────────────────────

// class _PriceRangeSheet extends StatefulWidget {
//   final bool isDark;
//   final String currency;
//   final double minPrice;
//   final double maxPrice;
//   final double currentMin;
//   final double currentMax;
//   final void Function(double min, double max) onApply;
//   final VoidCallback onClear;

//   const _PriceRangeSheet({
//     required this.isDark,
//     required this.currency,
//     required this.minPrice,
//     required this.maxPrice,
//     required this.currentMin,
//     required this.currentMax,
//     required this.onApply,
//     required this.onClear,
//   });

//   @override
//   State<_PriceRangeSheet> createState() => _PriceRangeSheetState();
// }

// class _PriceRangeSheetState extends State<_PriceRangeSheet> {
//   late RangeValues _range;
//   late List<_PricePreset> _presets;

//   @override
//   void initState() {
//     super.initState();
//     _range = RangeValues(widget.currentMin, widget.currentMax);
//     _buildPresets();
//   }

//   void _buildPresets() {
//     final min = widget.minPrice;
//     final max = widget.maxPrice;
//     final mid1 = min + (max - min) * 0.33;
//     final mid2 = min + (max - min) * 0.66;
//     _presets = [
//       _PricePreset(label: 'Lowest', icon: Icons.arrow_downward_rounded, min: min, max: mid1),
//       _PricePreset(label: 'Mid-range', icon: Icons.remove_rounded, min: mid1, max: mid2),
//       _PricePreset(label: 'Highest', icon: Icons.arrow_upward_rounded, min: mid2, max: max),
//       _PricePreset(label: 'All', icon: Icons.all_inclusive_rounded, min: min, max: max),
//     ];
//   }

//   bool _isPresetActive(_PricePreset p) =>
//       (_range.start - p.min).abs() < 1 && (_range.end - p.max).abs() < 1;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = widget.isDark;
//     final bg = isDark ? AppColors.darkCard : Colors.white;
//     final textPrimary =
//     isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
//     final textSecondary =
//     isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
//     final borderColor =
//     isDark ? AppColors.darkBorder : AppColors.lightBorder;

//     return Container(
//       decoration: BoxDecoration(
//           color: bg,
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
//       padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//                 width: 36, height: 4,
//                 decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2))),
//           ),
//           const SizedBox(height: 20),
//           Row(children: [
//             Text('Price Range',
//                 style: TextStyle(fontSize: AppSizes.fontXXL, fontWeight: FontWeight.w800, color: textPrimary)),
//             const Spacer(),
//             TextButton(
//               onPressed: () { widget.onClear(); Navigator.pop(context); },
//               child: const Text('Clear', style: TextStyle(color: AppColors.primaryStart, fontWeight: FontWeight.w700)),
//             ),
//           ]),
//           const SizedBox(height: 4),
//           Text('Narrow results by price range', style: TextStyle(fontSize: AppSizes.fontSM, color: textSecondary)),
//           const SizedBox(height: 20),
//           Row(
//             children: _presets.map((p) {
//               final active = _isPresetActive(p);
//               return Expanded(
//                 child: GestureDetector(
//                   onTap: () => setState(() => _range = RangeValues(p.min, p.max)),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 200),
//                     margin: const EdgeInsets.only(right: 6),
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     decoration: BoxDecoration(
//                       gradient: active ? AppColors.primaryGradient : null,
//                       color: active ? null : (isDark ? AppColors.darkInputBg : AppColors.lightInputBg),
//                       borderRadius: BorderRadius.circular(12),
//                       border: active ? null : Border.all(color: borderColor),
//                     ),
//                     child: Column(children: [
//                       Icon(p.icon, size: 16, color: active ? Colors.white : AppColors.primaryStart),
//                       const SizedBox(height: 4),
//                       Text(p.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
//                           color: active ? Colors.white : textSecondary), textAlign: TextAlign.center),
//                     ]),
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 24),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _PriceBox(label: 'Min', value: '${widget.currency} ${_range.start.toStringAsFixed(0)}', isDark: isDark),
//               Container(width: 20, height: 2, color: borderColor),
//               _PriceBox(label: 'Max', value: '${widget.currency} ${_range.end.toStringAsFixed(0)}', isDark: isDark),
//             ],
//           ),
//           const SizedBox(height: 12),
//           SliderTheme(
//             data: SliderThemeData(
//               trackHeight: 4,
//               activeTrackColor: AppColors.primaryStart,
//               inactiveTrackColor: borderColor,
//               thumbColor: AppColors.primaryStart,
//               overlayColor: AppColors.primaryStart.withValues(alpha: 0.15),
//               rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
//               rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
//             ),
//             child: RangeSlider(
//               values: _range,
//               min: widget.minPrice,
//               max: widget.maxPrice,
//               divisions: 20,
//               onChanged: (v) => setState(() => _range = v),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//               Text('${widget.currency} ${widget.minPrice.toStringAsFixed(0)}',
//                   style: TextStyle(fontSize: AppSizes.fontXS, color: textSecondary)),
//               Text('${widget.currency} ${widget.maxPrice.toStringAsFixed(0)}',
//                   style: TextStyle(fontSize: AppSizes.fontXS, color: textSecondary)),
//             ]),
//           ),
//           const SizedBox(height: 24),
//           GestureDetector(
//             onTap: () { widget.onApply(_range.start, _range.end); Navigator.pop(context); },
//             child: Container(
//               height: 52,
//               decoration: BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: AppColors.primaryStart.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
//               ),
//               child: const Center(child: Text('Apply Filter',
//                   style: TextStyle(fontSize: AppSizes.fontMD, fontWeight: FontWeight.w700, color: Colors.white))),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PriceBox extends StatelessWidget {
//   final String label, value;
//   final bool isDark;
//   const _PriceBox({required this.label, required this.value, required this.isDark});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: AppColors.primaryStart.withValues(alpha: 0.08),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: AppColors.primaryStart.withValues(alpha: 0.2)),
//       ),
//       child: Column(children: [
//         Text(label, style: TextStyle(fontSize: 10,
//             color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
//         const SizedBox(height: 2),
//         Text(value, style: const TextStyle(fontSize: AppSizes.fontMD,
//             fontWeight: FontWeight.w800, color: AppColors.primaryStart)),
//       ]),
//     );
//   }
// }

// class _PricePreset {
//   final String label;
//   final IconData icon;
//   final double min, max;
//   const _PricePreset({required this.label, required this.icon, required this.min, required this.max});
// }