import 'package:flutter/material.dart';

import '../../shared/constants/emas_colors.dart';
import '../../shared/constants/map_constants.dart';
import '../../shared/constants/report_constants.dart';

class ReportDetailSheet extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onClose;

  const ReportDetailSheet({
    super.key,
    required this.report,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _closeButton(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildDetailImage(report['imageUrl']),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, size: 20, color: emasColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${report['building'] ?? '-'} · '
                          '${report['floor'] ?? '-'} · '
                          'ห้อง ${report['room'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (report['severity'] != null)
                        Builder(builder: (_) {
                          final severity = getSeverityInfo(report['severity']);
                          return _dotChip(
                            severity.label,
                            dotColor: severity.color,
                            bg: severity.color.withOpacity(0.12),
                            fg: severity.color,
                          );
                        }),
                      Builder(builder: (_) {
                        final status = report['status'] ?? ReportStatus.pending;
                        final colors = getStatusColors(status);
                        return _chip(status, bg: colors.bg, color: colors.fg);
                      }),
                      _chip(
                        report['date'] ?? '-',
                        bg: Colors.grey.shade200,
                        color: Colors.grey.shade700,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 16),

                  _sectionSimple(
                    icon: Icons.description_outlined,
                    title: "รายละเอียด",
                    color: Colors.black87,
                    text: report['description'] ?? 'ไม่มีรายละเอียด',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildDetailImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              "ไม่มีรูปภาพ",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stack) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined,
            size: 32, color: Colors.grey.shade400),
      ),
    );
  }

  Widget _chip(String text, {required Color bg, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _dotChip(String text, {required Color dotColor, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _sectionSimple({
    required IconData icon,
    required String title,
    required String text,
    Color color = Colors.black87,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: color, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
