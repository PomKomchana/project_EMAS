import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/emas_colors.dart';

/// WIDGETS: GradientButton
/// Gradient pill button (color1 / color2)
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

/// WIDGETS: OutlineButton
/// Red outline button ("เลือกตำแหน่ง" / "เปลี่ยนตำแหน่ง")
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
