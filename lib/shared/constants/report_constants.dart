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
  'หอพระ', /// 17
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
  'ตึกคณะวิศวกรรมศาสตร์ (ตึก A)', /// 30
  'อาคารปฏิบัติการวิศกรรมไฟฟ้า (อาคาร C)', /// [31]
  'อาคารปฏิบัติการวิศวกรรมเครื่องกล (อาคาร D)', /// 32
  'อาคารปฏิบัติการวิศวกรรมเคมี (อาคาร E)', /// 33
  'ตึกวิศวกรรมอุตสาหการ (อาคาร I)', /// 34
  'ตึกปฏิบัติการวิศวกรรมโยธา (อาคาร F)', /// 35
  'สนามเทนนิส', /// 36
  'อาคารเรียนรวม', /// 37
  'ร้านเซเว่นอีเลฟเว่น', /// 38
  'อาคารปฏิบัติการพื้นฐาน', /// 39
  'สนามฟุตซอล', /// 40
  'ลานชงโค', /// 41
  'หอพักนิสิต 1', /// 42
  'หอพักนิสิต 2', /// 43
  'หอพักนิสิต 3', /// 44
  'หอพักนิสิต 4', /// 45
  'โรงอาหารหอพักนิสิต', /// 46
  'หอพักนิสิต 5', /// 47
  'หอพักนิสิต 6', /// 48
  'หอพักนิสิต อาคารบริการนิสิต', /// 49
  'หอพักนิสิต 7', /// 50
  'หอพักนิสิต 8', /// 51
  'หอพักนิสิต 9', /// 52
  'หอพักนิสิต 10', /// 53
  'หอพักนิสิต 11', /// 54
  'อาคารมีน้ำใจ (อาคารที่พักบุคลากร A)', /// 55
  'อาคารไมตรีตอบ (อาคารที่พักบุคลากร B)', /// 56
  'อาคารมอบความดี (อาคารที่พักบุคลากร C)', /// 57
  'อาคารศรีวิจิตร', /// 58
  'อาคารจิตอารี', /// 59
  'อาคารกัลยาณมิตร', /// 60
  'อาคารผลิตน้ำประปา', /// 61
  'สถานีไฟฟ้าย่อย', /// 62
  'บ่อเก็บน้ำดิบ', /// 63
  'บ่อระบาย', /// 64
  'ระบบบำบัดน้ำเสีย', /// 65
  'สถานีตำรวจย่อย', /// 66
  'อาคารสโมสร', /// 67
  'โรงจอดรถบัส', /// 68
  'อาคารศูนย์วิศัย', /// 69
  'ศาลากิจกรรม', /// 70
  'อาคารสุขภาวะ', /// 71
  'สถาบันวิจัย พัฒนา และสาธิตการศึกษา', /// 72
  'ศูนย์วิจัยและจัดการความรู้ทางพฤกษศาสตร์', /// 73

  'อาคารหอประชุมคณะวิศวกรรมศาสตร์ (อาคาร B)', /// 74
  'อาคารวิจัยและพัฒนาเทคโนโลยีทางวิศวกรรมไฟฟ้า (อาคาร G)', /// 75
  'พักนิสิต 12', /// 76
  'พักนิสิต 13', /// 77
  'พักนิสิต 14', /// 78
  'พักนิสิต 15', /// 79
  'พักนิสิต 16', /// 80
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
