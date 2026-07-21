import 'dart:ui';
import 'package:flutter/material.dart';

import '../constants/emas_colors.dart';

// WIDGETS: ChangeImageButton
// Pill overlaid on the picked image, reopens the image picker sheet ("เปลี่ยน")
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

// WIDGETS: ImagePlaceholder
// Empty-state box shown when no image is picked yet
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
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 32,
              color: emasColor.withOpacity(0.7),
            ),
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
            Text(
              'ถ่ายรูปหรือเลือกจากคลัง',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
