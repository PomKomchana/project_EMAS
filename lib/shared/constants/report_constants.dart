import 'package:flutter/material.dart';

import '../../shared/constants/emas_colors.dart';

// [buildingOptions]
const buildingOptions = [
  'อาคาร 1',
  'อาคาร 2',
  'อาคาร 3',
  'อาคาร 4',
  'อาคาร 5',
];

// [floorOptions]
const floorOptions = [
  'ชั้น 1',
  'ชั้น 2',
  'ชั้น 3',
  'ชั้น 4',
  'ชั้น 5',
];

// Label + Color for one severity level [SeverityInfo]
class SeverityInfo {
  final String label;
  final Color color;

  const SeverityInfo({
    required this.label,
    required this.color,
  });
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

// Status values, stored as Strings in Firestore [ReportStatus]
class ReportStatus {
  static const pending = 'รอดำเนินการ';
  static const inProgress = 'กำลังดำเนินการ';
  static const done = 'เสร็จสิ้น';

  // null = Show all statuses
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

// Text-only color for a status (Used on detail page) [getStatusTextColor]
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
