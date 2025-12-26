import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UnicefDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const UnicefDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 CLEAN list + remove duplicates + trim values
    final cleanedItems = items
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toSet()
        .toList()
      ..sort();

    // 🔥 CLEAN current value
    final cleanedValue = value?.trim();

    // 🔥 Ensure the dropdown will NOT crash:
    // If the current value is NOT found inside items → use null
    final safeValue = cleanedItems.contains(cleanedValue) ? cleanedValue : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      items: cleanedItems
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppTheme.unicefBlue,
          fontWeight: FontWeight.w600,
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
