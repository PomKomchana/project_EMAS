import 'dart:ui';
import 'package:flutter/material.dart';
import 'report_form_constants.dart';

/// <<<<< Glass Card >>>>>>
// Glass card with a clear white background.
// Used to wrap every section on the report form (map, image, reporter info, etc).
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// <<<<< Card Header >>>>>>
// Section header used inside a [GlassCard]: small icon chip + bold title.
class CardHeader extends StatelessWidget {
  const CardHeader({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: emasColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: emasColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// <<<<< Gradient Button >>>>>>
// Gradient pill button. Used for the submit button and the confirm-pin
// button — pass [color1]/[color2] to re-theme it (e.g. green for "confirm").
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onTap,
    required this.child,
    this.color1 = emasColor,
    this.color2 = emasColorDarker,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color color1;
  final Color color2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 15),
            child: IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// <<<<< Outline Button >>>>>>
// Red outline button. Used below the map for "เลือกตำแหน่ง" / "เปลี่ยนตำแหน่ง".
class OutlineButton extends StatelessWidget {
  const OutlineButton({
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
        height: 46,
        decoration: BoxDecoration(
          color: emasColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: emasColor.withOpacity(0.4), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: emasColor),
            const SizedBox(width: 6),
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

/// <<<<< Pin Badge >>>>>>
// Small green "ปักหมุดแล้ว" badge shown next to the location button
// once a pin has been placed.
class PinBadge extends StatelessWidget {
  const PinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 15),
          const SizedBox(width: 4),
          Text(
            'ปักหมุดแล้ว',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// <<<<< Glass Map Button >>>>>>
// Small frosted-glass pill button overlaid on the map (used for the
// map-mode switcher, e.g. "ปกติ" / "ดาวเทียม").
class GlassMapButton extends StatelessWidget {
  const GlassMapButton({
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: emasColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
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

/// <<<<< Picking Banner >>>>>>
// "📍 แตะเพื่อปักหมุดจุดเกิดเหตุ" banner shown over the map while in
// pin-picking mode.
class PickingBanner extends StatelessWidget {
  const PickingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: emasColor.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '📍  แตะเพื่อปักหมุดจุดเกิดเหตุ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// <<<<< Close Map Button >>>>>>
// Round "X" button (frosted glass) used to collapse the expanded map.
class CloseMapButton extends StatelessWidget {
  const CloseMapButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

/// <<<<< Change Image Button >>>>>>
// "เปลี่ยน" pill button overlaid on the picked image, to re-open the
// image-source picker sheet.
class ChangeImageButton extends StatelessWidget {
  const ChangeImageButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'เปลี่ยน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

/// <<<<< Image Placeholder >>>>>>
// Dashed-style placeholder box shown when no image has been picked yet.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: emasColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: emasColor.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 32, color: emasColor.withOpacity(0.7)),
            const SizedBox(height: 6),
            Text(
              'แตะเพื่อเพิ่มรูปภาพ',
              style: TextStyle(
                color: emasColor.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text('ถ่ายรูปหรือเลือกจากคลัง', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// <<<<< Styled Dropdown >>>>>>
// Custom-styled dropdown used for "เลือกอาคาร" / "เลือกชั้น".
// Border highlights pink once a value is selected.
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

/// <<<<< Sheet Option >>>>>>
// One tappable option inside the image-source bottom sheet
// (e.g. "ถ่ายรูป" / "คลังภาพ").
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
