import 'package:flutter/material.dart';

// EMAS Theme Colors [emasColor, emasColorDarker]
// NOTE: duplicated in report_form_constants.dart
const emasColor = Color(0xFFe85d6a);
const emasColorDarker = Color(0xFFc4394a);

// Label + color for one severity level
class SeverityInfo {
  final String label;
  final Color color;

  const SeverityInfo({required this.label, required this.color});
}

// All severity levels, keyed by Firestore value
const Map<String, SeverityInfo> severityLevels = {
  'low': SeverityInfo(label: 'อันตรายต่ำ', color: Color(0xFF22c55e)),
  'medium': SeverityInfo(label: 'อันตรายปานกลาง', color: Color(0xFFf97316)),
  'high': SeverityInfo(label: 'อันตรายสูง', color: Color(0xFFef4444)),
  'none': SeverityInfo(label: 'ยังไม่ระบุ', color: Colors.grey),
};

// Lookup with fallback to "none" [getSeverityInfo]
SeverityInfo getSeverityInfo(String? severityKey) {
  return severityLevels[severityKey] ?? severityLevels['none']!;
}

// Status values, stored as Thai strings in Firestore [ReportStatus]
class ReportStatus {
  static const pending = 'รอดำเนินการ';
  static const inProgress = 'กำลังดำเนินการ';
  static const done = 'เสร็จสิ้น';

  // null = show all statuses
  static const List<String?> filterOptions = [
    null,
    pending,
    inProgress,
    done,
  ];
}

// bg/fg color pair for a status chip [getStatusColors]
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

// Text-only color for a status (used on detail page) [getStatusTextColor]
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
