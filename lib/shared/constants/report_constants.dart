import 'package:flutter/material.dart';

import '../../shared/constants/emas_colors.dart';

/// [buildingOptions]
const buildingOptions = [
  'สนามกีฬากลาง', /// [01]
  'สนามรักบี้', /// [02]
  'สนามยิงธนู', /// [03]
  'สนามซอฟท์บอล', /// [04]
  'อาคารฝึกกีฬาทางน้ำ', /// [05]
  'อาคารกีฬา 1', /// [06]
  'อาคารกีฬา 2', /// [07]
  'อาคารกีฬา 3', /// [08]
  'สนามฝึกซ้อมซอฟท์บอล', /// [09]
  'อาคาร Subpress Center', /// [10]
  'อาคารอำนวยการ', /// [11]
  'หอสมุดองครักษ์', /// [12]
  'คณะสหเวชศาสตร์', /// [13]
  'อาคารผลิตน้ำดื่ม', /// [14]
  'คณะเภสัชศาสตร์', /// [15]
  'พิพิธภัณฑ์ภูมิปัญญาไทย "เรือนไทยหมู่ ธ ทูลกระหม่อมแก้ว"', /// 16
  'หอพระ', /// [17]
  'คณะพยาบาลศาสตร์', /// 18
  'ศูนย์การแพทย์สมเด็จพระเทพรัตนราชสุดา ฯ สยามบรมราชกุมารี', /// 19
  'คณะแพทย์ศาสตร์', /// 20
  'สนามกีฬาศูนย์แพทย์', /// 21
  'หอพักพยาบาล', /// 22
  'หอพักแพทย์', /// 23
  'หอพักแพทย์ F', /// 24
  'หอพักแพทย์ C', /// 25
  'หอพักแพทย์ B', /// 26
  'หอพักแพทย์ A', /// 27
  'ธนาคารไทยพาณิชย์', /// 28
  'อาคารศูนย์กิจกรรมนิสิตและบริการ (อาคารพลาซ่า)', /// 29
  'ตึกคณะวิศวกรรมศาสตร์ (ตึก A)', /// [30]
  'อาคารหอประชุมคณะวิศวกรรมศาสตร์ (อาคาร B)', /// [31]
  'อาคารปฏิบัติการวิศกรรมไฟฟ้า (อาคาร C)', /// [32]
  'อาคารปฏิบัติการวิศวกรรมเครื่องกล (อาคาร D)', /// [33]
  'อาคารปฏิบัติการวิศวกรรมเคมี (อาคาร E)', /// [34]
  'ตึกปฏิบัติการวิศวกรรมโยธา (อาคาร F)', /// [35]
  'อาคารวิจัยและพัฒนาเทคโนโลยีทางวิศวกรรมไฟฟ้า (อาคาร G)', /// [36]
  'ตึกวิศวกรรมอุตสาหการ (อาคาร H)', /// [37]
  'อาคารศูนย์เครื่องมือกลางและสอบเทียบทางวิศวกรรม (อาคาร I)', /// [38]
  'สนามเทนนิส', /// 39
  'อาคารเรียนรวม', /// 40
  '7-Eleven (วิศวะ)', /// 41
  '7-Eleven (ศูนย์แพทย์)', /// 42
  'อาคารปฏิบัติการพื้นฐาน', /// 43
  'สนามฟุตซอล', /// 44
  'ลานชงโค', /// 45
  'หอพักนิสิต 1', /// [46]
  'หอพักนิสิต 2', /// [47]
  'หอพักนิสิต 3', /// [48]
  'หอพักนิสิต 4', /// [49]
  'หอพักนิสิต 5', /// [50]
  'หอพักนิสิต 6', /// [51]
  'หอพักนิสิต 7', /// [52]
  'หอพักนิสิต 8', /// [53]
  'หอพักนิสิต 9', /// [54]
  'หอพักนิสิต 10', /// [55]
  'หอพักนิสิต 11', /// [56]
  'หอพักนิสิต 12', /// [57]
  'หอพักนิสิต 13', /// [58]
  'หอพักนิสิต 14', /// [59]
  'หอพักนิสิต 15', /// [60]
  'หอพักนิสิต 16', /// [61]
  'อาคารบริการนิสิต (อ๊อกตะ)', /// [62]
  'โรงอาหารหอพักนิสิต (โรงเขียว)', /// [63]
  'อาคารมีน้ำใจ (อาคารที่พักบุคลากร A)', /// 64
  'อาคารไมตรีตอบ (อาคารที่พักบุคลากร B)', /// 65
  'อาคารมอบความดี (อาคารที่พักบุคลากร C)', /// 66
  'อาคารศรีวิจิตร', /// 67
  'อาคารจิตอารี', /// 68
  'อาคารกัลยาณมิตร', /// 69
  'อาคารผลิตน้ำประปา', /// 70
  'สถานีไฟฟ้าย่อย', /// 71
  'บ่อเก็บน้ำดิบ', /// 72
  'บ่อระบาย', /// 73
  'ระบบบำบัดน้ำเสีย', /// 74
  'สถานีตำรวจย่อย', /// 75
  'อาคารสโมสร', /// 76
  'โรงจอดรถบัส', /// 77
  'อาคารศูนย์วิศัย', /// 78
  'ศาลากิจกรรม', /// 79
  'อาคารสุขภาวะ', /// 80
  'สถาบันวิจัย พัฒนา และสาธิตการศึกษา', /// 81
  'ศูนย์วิจัยและจัดการความรู้ทางพฤกษศาสตร์', /// 82
];

/// Label + Color for one severity level [SeverityInfo]
class SeverityInfo {
  final String label;
  final Color color;

  const SeverityInfo({
    required this.label,
    required this.color,
  });
}

/// All severity levels, keyed by Firestore value
const Map<String, SeverityInfo> severityLevels = {
  'low': SeverityInfo(label: 'อันตรายต่ำ', color: Color(0xFF22c55e)),
  'medium': SeverityInfo(label: 'อันตรายปานกลาง', color: Color(0xFFf97316)),
  'high': SeverityInfo(label: 'อันตรายสูง', color: Color(0xFFef4444)),
  'none': SeverityInfo(label: 'ยังไม่ระบุ', color: Colors.grey),
};

/// Lookup with fallback to "none" [getSeverityInfo]
SeverityInfo getSeverityInfo(String? severityKey) {
  return severityLevels[severityKey] ?? severityLevels['none']!;
}

/// Status values, stored as Strings in Firestore [ReportStatus]
class ReportStatus {
  static const pending = 'รอดำเนินการ';
  static const inProgress = 'กำลังดำเนินการ';
  static const done = 'เสร็จสิ้น';

  /// null = Show all statuses
  static const List<String?> filterOptions = [
    null,
    pending,
    inProgress,
    done,
  ];
}

/// bg/fg color pair for a status chip [getStatusColors]
({Color bg, Color fg}) getStatusColors(String status) {
  switch (status) {
    case ReportStatus.pending:
      return (bg: Colors.orange.shade50, fg: Colors.orange.shade700);
    case ReportStatus.inProgress:
      return (bg: Colors.blue.shade50, fg: Colors.blue.shade700);
    case ReportStatus.done:
      return (bg: Colors.green.shade50, fg: Colors.green.shade700);
    default:
      return (bg: emasColor.withOpacity(0.1), fg: emasColorDarker);
  }
}

/// Text-only color for a status (Used on detail page) [getStatusTextColor]
Color getStatusTextColor(String status) {
  switch (status) {
    case ReportStatus.pending:
      return Colors.orange.shade700;
    case ReportStatus.inProgress:
      return Colors.blue.shade700;
    case ReportStatus.done:
      return Colors.green.shade700;
    default:
      return emasColorDarker;
  }
}
