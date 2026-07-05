import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/emas_colors.dart';

// WIDGETS: StyledDropdown
// Dropdown for ("เลือกอาคาร" / "เลือกชั้น")
// Border turns pink once selected
class StyledDropdown extends StatelessWidget {
  const StyledDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hint;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null ? emasColor.withOpacity(0.5) : Colors.grey.shade200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: emasColor.withOpacity(0.7)),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// WIDGETS: SheetOption
// One tappable option in the image-source bottom sheet ("ถ่ายรูป" / "คลังภาพ")
class SheetOption extends StatelessWidget {
  const SheetOption({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: emasColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: emasColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: emasColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: emasColor, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: emasColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
