import 'package:flutter/material.dart';

class SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final Function(String) onSortSelected;

  const SortBottomSheet({
    super.key,
    required this.currentSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sorts = [
      {'label': 'Price', 'value': 'total_amount'},
      {'label': 'Duration', 'value': 'duration'},
      {'label': 'Departure Time', 'value': 'departure'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: sorts.map((s) {
          final selected = currentSort == s['value'];

          return ListTile(
            title: Text(s['label']!),
            trailing: selected
                ? const Icon(Icons.check_circle)
                : null,
            onTap: () {
              onSortSelected(s['value']!);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}