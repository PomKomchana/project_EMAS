import 'package:flutter/material.dart';
// 1 2
const emasColor = Color(0xFFe85d6a);
const emasColorDarker = Color(0xFFc4394a);

class SeverityInfo {
  final String label;
  final Color color;

  const SeverityInfo({required this.label, required this.color});
}

const Map<String, SeverityInfo> severityLevels = {
  'high': SeverityInfo(label: 'ด่วนมาก', color: Color(0xFFef4444)),
  'medium': SeverityInfo(label: 'ปานกลาง', color: Color(0xFFf97316)),
  'low': SeverityInfo(label: 'ไม่ด่วน', color: Color(0xFF22c55e)),
  'none': SeverityInfo(label: 'ยังไม่ระบุ', color: Colors.grey),
};

SeverityInfo getSeverityInfo(String? severityKey) {
  return severityLevels[severityKey] ?? severityLevels['none']!;
}

class ReportStatus {
  static const pending = 'รอดำเนินการ';
  static const inProgress = 'กำลังดำเนินการ';
  static const done = 'เสร็จสิ้น';

  static const List<String?> filterOptions = [
    null,
    pending,
    inProgress,
    done,
  ];
}

({Color bg, Color fg}) getStatusColors(String status) {
  switch (status) {
    case ReportStatus.inProgress:
      return (bg: Colors.orange.shade50, fg: Colors.orange.shade700);
    case ReportStatus.done:
      return (bg: Colors.green.shade50, fg: Colors.green.shade700);
    default:
      return (bg: emasColor.withOpacity(0.1), fg: emasColorDarker);
  }
}

Color getStatusTextColor(String status) {
  switch (status) {
    case ReportStatus.inProgress:
      return Colors.orange.shade700;
    case ReportStatus.done:
      return Colors.green.shade700;
    default:
      return emasColorDarker;
  }
}
