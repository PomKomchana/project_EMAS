import 'package:latlong2/latlong.dart';

/// ============================== [BuildingBoundary Model] ==============================

/// Stores the real shape (boundary) of one building.
/// Used to check if a point (lat/lng) falls inside this building.
class BuildingBoundary {
  final String buildingCode; // short code, e.g. 'A', 'B', 'C'
  final String buildingName; // full name, e.g. 'Building A'
  final List<LatLng> polygon; // corner points of the building shape, in order (no need to repeat the first point at the end)
  // อย่าลืมตัดจุดสุดท้ายที่พิกัดซ้ำกัน

  const BuildingBoundary({
    required this.buildingCode,
    required this.buildingName,
    required this.polygon,
  });
}

/// ============================== [Campus Buildings Data] ==============================

/// TODO: replace the placeholder coordinates below with the real building corners.
/// See the "How to get real building coordinates" guide for steps.
const List<BuildingBoundary> campusBuildings = [
  BuildingBoundary(
    buildingCode: '01',
    buildingName: 'สนามกีฬากลาง',
    polygon: [
      LatLng(14.1092736, 100.979091),
      LatLng(14.1092271, 100.9784632),
      LatLng(14.1087093, 100.9781048),
      LatLng(14.1077134, 100.9786314),
      LatLng(14.107735, 100.9792669),
      LatLng(14.1081639, 100.979674),
      LatLng(14.1087071, 100.9794009),
    ],
  ),
  BuildingBoundary(
    buildingCode: '02',
    buildingName: 'สนามรักบี้',
    polygon: [
      LatLng(14.109577, 100.9790662),
      LatLng(14.1092453, 100.9783935),
      LatLng(14.1088229, 100.9780608),
      LatLng(14.1077058, 100.9786185),
      LatLng(14.1076916, 100.9791793),
      LatLng(14.1078024, 100.9794212),
      LatLng(14.1082846, 100.9796692),
      LatLng(14.1089005, 100.9795742),
      LatLng(14.1091584, 100.9792459,),
    ],
  ),
  BuildingBoundary(
    buildingCode: '03',
    buildingName: 'สนามยิงธนู',
    polygon: [
      LatLng(14.1072584, 100.9791585),
      LatLng(14.1069534, 100.9785445),
      LatLng(14.1055783, 100.9792919,),
      LatLng(14.1058795, 100.9799045),
    ],
  ),
  BuildingBoundary(
    buildingCode: '04',
    buildingName: 'สนามซอฟท์บอล',
    polygon: [
      LatLng(14.1076061, 100.9794114),
      LatLng(14.1078359, 100.979910),
      LatLng(14.1077936, 100.9804315),
      LatLng(14.1074093, 100.9809951),
      LatLng(14.107029, 100.9812069),
      LatLng(14.1066622, 100.9804677),
      LatLng(14.1064541, 100.9805724),
      LatLng(14.1062532, 100.9801678),
      LatLng(14.1063627, 100.9798442),
      LatLng(14.1067248, 100.9796599),
      LatLng(14.1068314, 100.9798572),
    ],
  ),
  BuildingBoundary(
    buildingCode: '05',
    buildingName: 'อาคารฝึกกีฬาทางน้ำ',
    polygon: [
      LatLng(14.105658, 100.9798568),
      LatLng(14.1054408, 100.979439),
      LatLng(14.1048623, 100.9797452),
      LatLng(14.104902, 100.979866),
      LatLng(14.1043391, 100.9801112),
      LatLng(14.1045423, 100.9805146),
    ],
  ),
  BuildingBoundary(
    buildingCode: '06',
    buildingName: 'อาคารกีฬา 1',
    polygon: [
      LatLng(14.1054978, 100.9808618),
      LatLng(14.105185, 100.9802653),
      LatLng(14.1046853, 100.9805443),
      LatLng(14.1049874, 100.9811374),
    ],
  ),
  BuildingBoundary(
    buildingCode: '07',
    buildingName: 'อาคารกีฬา 2',
    polygon: [
      LatLng(14.1059053, 100.9814456),
      LatLng(14.105606, 100.9808845),
      LatLng(14.1051227, 100.9811603),
      LatLng(14.1053888, 100.9817057),
    ],
  ),
  BuildingBoundary(
    buildingCode: '08',
    buildingName: 'อาคารกีฬา 3',
    polygon: [
      LatLng(14.1043562, 100.9809546),
      LatLng(14.1040738, 100.9804275),
      LatLng(14.1033526, 100.980796),
      LatLng(14.1036313, 100.9813405),
    ],
  ),
  BuildingBoundary(
    buildingCode: '09',
    buildingName: 'สนามฝึกซ้อมซอฟท์บอล',
    polygon: [
      LatLng(14.1042415, 100.9824825),
      LatLng(14.1040193, 100.9820728),
      LatLng(14.1043928, 100.9818714),
      LatLng(14.1045188, 100.9821327),
      LatLng(14.1044414, 100.9823379),
    ],
  ),
  BuildingBoundary(
    buildingCode: '10',
    buildingName: 'อาคาร Subpress Center',
    polygon: [
      LatLng(14.1043981, 100.9815076),
      LatLng(14.1042422, 100.9811841),
      LatLng(14.1038104, 100.9814995),
      LatLng(14.1039015, 100.9816875),
    ],
  ),
  BuildingBoundary(
    buildingCode: '11',
    buildingName: 'อาคารผู้อำนวยการ',
    polygon: [
      LatLng(14.1058111, 100.9827669),
      LatLng(14.1055024, 100.9821972),
      LatLng(14.1051861, 100.9823671),
      LatLng(14.1054917, 100.9829472),
    ],
  ),
  BuildingBoundary(
    buildingCode: '12',
    buildingName: 'หอสมุดองครักษ์',
    polygon: [
      LatLng(14.1050494, 100.9844476),
      LatLng(14.1052656, 100.9843167),
      LatLng(14.1051373, 100.984083),
      LatLng(14.10531, 100.9839701),
      LatLng(14.1051339, 100.9836267),
      LatLng(14.1047364, 100.9838443),
    ],
  ),
  BuildingBoundary(
    buildingCode: '13',
    buildingName: 'คณะสหเวชศาสตร์',
    polygon: [
      LatLng(14.1056923, 100.9855998),
      LatLng(14.1061667, 100.9853095),
      LatLng(14.1059066, 100.9847637),
      LatLng(14.1059514, 100.9846383),
      LatLng(14.1056632, 100.9845685),
      LatLng(14.1052954, 100.9847865),
    ],
  ),
  BuildingBoundary(
    buildingCode: '14',
    buildingName: 'อาคารผลิดน้ำดื่ม',
    polygon: [
      LatLng(14.1069808, 100.984789),
      LatLng(14.1068944, 100.9846111),
      LatLng(14.1066212, 100.9847574),
      LatLng(14.1067143, 100.984935),
    ],
  ),
  BuildingBoundary(
    buildingCode: '15',
    buildingName: 'คณะเภสัชศาสตร์',
    polygon: [
      LatLng(14.1069808, 100.984789),
      LatLng(14.1068944, 100.9846111),
      LatLng(14.1066212, 100.9847574),
      LatLng(14.1067143, 100.984935),
    ],
  ),
  BuildingBoundary(
    buildingCode: '16',
    buildingName: 'พิพิธภัณฑ์ภูมิปัญญาไทย "เรือนไทยหมู่ ธ ทูลกระหม่อมแก้ว',
    polygon: [
      LatLng(14.1087294, 100.9835848),
      LatLng(14.1085114, 100.9832112),
      LatLng(14.1084085, 100.9832725),
      LatLng(14.1084375, 100.9833218),
      LatLng(14.1083215, 100.9833929),
      LatLng(14.1082978, 100.983354),
      LatLng(14.1081726, 100.9834306),
      LatLng(14.1082481, 100.9835616),
      LatLng(14.1083511, 100.9834994),
      LatLng(14.1084222, 100.9836244),
      LatLng(14.1083466, 100.9836694),
      LatLng(14.1084074, 100.983776),
    ],
  ),
  BuildingBoundary(
    buildingCode: '17',
    buildingName: 'หอพระ',
    polygon: [
      LatLng(14.1115959, 100.9825343),
      LatLng(14.1112182, 100.9817971),
      LatLng(14.1107832, 100.9820265),
      LatLng(14.110359, 100.9818708),
      LatLng(14.1091664, 100.9821987),
      LatLng(14.1088048, 100.9826711),
      LatLng(14.1089659, 100.9829722),
      LatLng(14.1088758, 100.9835828),
      LatLng(14.1085753, 100.9838598),
      LatLng(14.1082449, 100.9839256),
      LatLng(14.1078801, 100.9841389),
      LatLng(14.1082864, 100.9848512),
      LatLng(14.1086484, 100.9850198),
      LatLng(14.1098584, 100.9834998),
    ],
  ),
  BuildingBoundary(
    buildingCode: '18',
    buildingName: 'คณะพยาบาลศาสตร์',
    polygon: [
      LatLng(14.1097758, 100.9844441),
      LatLng(14.1096774, 100.9844857),
      LatLng(14.1095893, 100.9842737),
      LatLng(14.1092618, 100.9844417),
      LatLng(14.1095811, 100.9850848),
    ],
  ),
  BuildingBoundary(
    buildingCode: '19',
    buildingName: 'ศูนย์การแพทย์สมเด็จพระเทพรัตนราชสุดา ฯ สยามบรมราชกุมารี',
    polygon: [
      LatLng(14.1122092, 100.9850346),
      LatLng(14.1119846, 100.9845699),
      LatLng(14.1115968, 100.9842737),
      LatLng(14.1110894, 100.9845436),
      LatLng(14.1115652, 100.9854524),
      LatLng(14.111714, 100.9853438),
      LatLng(14.1117849, 100.9854778),
      LatLng(14.1119144, 100.9854188),
      LatLng(14.1118248, 100.9852344),
    ],
  ),
  BuildingBoundary(
    buildingCode: '20',
    buildingName: 'คณะแพทย์ศาสตร์',
    polygon: [
      LatLng(14.1114474, 100.9836924),
      LatLng(14.1113856, 100.9833686),
      LatLng(14.1111537, 100.9829217),
      LatLng(14.1110577, 100.982907),
      LatLng(14.1105231, 100.9831932),
      LatLng(14.1107334, 100.9836129),
      LatLng(14.1110598, 100.9839008),
    ],
  ),
  BuildingBoundary(
    buildingCode: '21',
    buildingName: 'สนามกีฬาศูนย์แพทย์',
    polygon: [
      LatLng(14.1104903, 100.9860248),
      LatLng(14.1101691, 100.9854543),
      LatLng(14.1096596, 100.9857501),
      LatLng(14.1099782, 100.9863221),
    ],
  ),
  BuildingBoundary(
    buildingCode: '22',
    buildingName: 'หอพักพยาบาล',
    polygon: [
      LatLng(14.1091698, 100.9862497),
      LatLng(14.1088595, 100.9856708),
      LatLng(14.1086129, 100.9857998),
      LatLng(14.1088973, 100.986409),
    ],
  ),
  BuildingBoundary(
    buildingCode: '23',
    buildingName: 'หอพักแพทย์',
    polygon: [
      LatLng(14.1087164, 100.9855836),
      LatLng(14.108596, 100.9853243),
      LatLng(14.1083089, 100.9854859),
      LatLng(14.1084243, 100.9856887),
      LatLng(14.1085194, 100.9857469),
    ],
  ),
  BuildingBoundary(
    buildingCode: '24',
    buildingName: 'หอพักแพทย์ F',
    polygon: [
      LatLng(14.108411, 100.9865871),
      LatLng(14.1081672, 100.9861271),
      LatLng(14.1079233, 100.9862702),
      LatLng(14.1081779, 100.9867214),
    ],
  ),
  BuildingBoundary(
    buildingCode: '25',
    buildingName: 'หอพักแพทย์ C',
    polygon: [
      LatLng(14.107229, 100.9865988),
      LatLng(14.1074821, 100.9870675),
      LatLng(14.1072679, 100.987194),
      LatLng(14.1070192, 100.9867189),
    ],
  ),
  BuildingBoundary(
    buildingCode: '26',
    buildingName: 'หอพักแพทย์ B',
    polygon: [
      LatLng(14.1072181, 100.9872363),
      LatLng(14.1069529, 100.9867492),
      LatLng(14.1067393, 100.9868721),
      LatLng(14.1070105, 100.9873539),
    ],
  ),
  BuildingBoundary(
    buildingCode: '27',
    buildingName: 'หอพักแพทย์ A',
    polygon: [
      LatLng(14.1065542, 100.9869835),
      LatLng(14.1068064, 100.9874541),
      LatLng(14.1065991, 100.9875797),
      LatLng(14.1063326, 100.9871117),
    ],
  ),
  BuildingBoundary(
    buildingCode: '28',
    buildingName: 'ธนาคารไทยพาณิชย์',
    polygon: [
      LatLng(14.1093231, 100.986726),
      LatLng(14.1092393, 100.9865696),
      LatLng(14.1090886, 100.9866544),
      LatLng(14.1091725, 100.9868128),
    ],
  ),
  BuildingBoundary(
    buildingCode: '29',
    buildingName: 'อาคารศูนย์กิจกรรมนิสิตและบริการ (อาคารพลาซ่า)',
    polygon: [
      LatLng(14.1091371, 100.9870374),
      LatLng(14.1089973, 100.9867732),
      LatLng(14.1088276, 100.9868071),
      LatLng(14.108548, 100.9869669),
      LatLng(14.1084614, 100.9871015),
      LatLng(14.1085937, 100.987347),
    ],
  ),
  BuildingBoundary(
    buildingCode: '30',
    buildingName: 'ตึกคณะวิศวกรรมศาสตร์ (ตึก A)',
    polygon: [
      LatLng(14.1034958, 100.982649),
      LatLng(14.1031134, 100.9819496),
      LatLng(14.1028645, 100.9820993),
      LatLng(14.1032457, 100.9827991),
    ],
  ),
  BuildingBoundary(
    buildingCode: '31',
    buildingName: 'อาคารหอประชุมคณะวิศวกรรมศาสตร์ (อาคาร B)',
    polygon: [
      LatLng(14.1032084, 100.982668),
      LatLng(14.1031331, 100.9825176),
      LatLng(14.1031006, 100.9825385),
      LatLng(14.103006, 100.9823572),
      LatLng(14.1028856, 100.9824243),
      LatLng(14.1030538, 100.9827517),
    ],
  ),
  BuildingBoundary(
    buildingCode: '32',
    buildingName: 'อาคารปฏิบัติการวิศกรรมไฟฟ้า (อาคาร C)',
    polygon: [
      LatLng(14.1028898, 100.9829694),
      LatLng(14.1025572, 100.9823328),
      LatLng(14.1022319, 100.9825062),
      LatLng(14.1025623, 100.9831283),
    ],
  ),
  BuildingBoundary(
    buildingCode: '33',
    buildingName: 'อาคารปฏิบัติการวิศวกรรมเครื่องกล (อาคาร D)',
    polygon: [
      LatLng(14.1025096, 100.9831966),
      LatLng(14.1021681, 100.9825407),
      LatLng(14.1018357, 100.9827262),
      LatLng(14.1021756, 100.9833742),
    ],
  ),
  BuildingBoundary(
    buildingCode: '34',
    buildingName: 'อาคารปฏิบัติการวิศวกรรมเคมี (อาคาร E)',
    polygon: [
      LatLng(14.1019667, 100.9834772),
      LatLng(14.1016318, 100.9828309),
      LatLng(14.1013061, 100.9830129),
      LatLng(14.1016411, 100.9836505),
    ],
  ),
  BuildingBoundary(
    buildingCode: '35',
    buildingName: 'ตึกปฏิบัติการวิศวกรรมโยธา (อาคาร F)',
    polygon: [
      LatLng(14.1029297, 100.9810465),
      LatLng(14.1032848, 100.9817336),
      LatLng(14.1029035, 100.9819456),
      LatLng(14.1027899, 100.9817146),
      LatLng(14.1029035, 100.9819456),
      LatLng(14.1027899, 100.9817146),
      LatLng(14.1026592, 100.9817838),
      LatLng(14.1024248, 100.9813113),
    ],
  ),
  BuildingBoundary(
    buildingCode: '36',
    buildingName: 'อาคารวิจัยและพัฒนาเทคโนโลยีทางวิศวกรรมไฟฟ้า (อาคาร G)',
    polygon: [
      LatLng(14.1017102, 100.9837839),
      LatLng(14.1013088, 100.9830095),
      LatLng(14.1008864, 100.9832613),
      LatLng(14.1012804, 100.9840287),
    ],
  ),
  BuildingBoundary(
    buildingCode: '37',
    buildingName: 'ตึกวิศวกรรมอุตสาหการ (อาคาร H)',
    polygon: [
      LatLng(14.101876, 100.9819806),
      LatLng(14.1017347, 100.9817065),
      LatLng(14.1011655, 100.9820248),
      LatLng(14.1013096, 100.9822965),
    ],
  ),
  BuildingBoundary(
    buildingCode: '38',
    buildingName: 'อาคารศูนย์เครื่องมือกลางและสอบเทียบทางวิศวกรรม (อาคาร I)',
    polygon: [
      LatLng(14.1021075, 100.9823342),
      LatLng(14.1019263, 100.9820019),
      LatLng(14.1013695, 100.9823225),
      LatLng(14.1015369, 100.9826436),
    ],
  ),
  BuildingBoundary(
    buildingCode: '39',
    buildingName: 'สนามเทนนิส',
    polygon: [
      LatLng(14.1036838, 100.9840305),
      LatLng(14.1032515, 100.9832108),
      LatLng(14.1025073, 100.9836094),
      LatLng(14.102943, 100.9844405),
    ],
  ),
  BuildingBoundary(
    buildingCode: '40',
    buildingName: 'อาคารเรียนรวม',
    polygon: [
      LatLng(14.1034579, 100.9830568),
      LatLng(14.1043541, 100.9835541),
      LatLng(14.1041227, 100.9839496),
      LatLng(14.1037345, 100.9837864),
      LatLng(14.1034098, 100.9834679),
    ],
  ),
  BuildingBoundary(
    buildingCode: '41',
    buildingName: '7-Eleven (วิศวะ)',
    polygon: [
      LatLng(14.1022759, 100.9837976),
      LatLng(14.1021905, 100.9836505),
      LatLng(14.1020627, 100.9837264),
      LatLng(14.102147, 100.983871),
    ],
  ),
  BuildingBoundary(
    buildingCode: '42',
    buildingName: '7-Eleven (ศูนย์แพทย์)',
    polygon: [
      LatLng(14.1117195, 100.9858224),
      LatLng(14.1116388, 100.9856681),
      LatLng(14.1114913, 100.9857478),
      LatLng(14.1115724, 100.9859025),
    ],
  ),
  BuildingBoundary(
    buildingCode: '43',
    buildingName: 'อาคารเรียนและปฏิบัติการวิชาพื้นฐาน',
    polygon: [
      LatLng(),
      LatLng(),
      LatLng(),
      LatLng(),
    ],
  ),
  BuildingBoundary(
    buildingCode: '46',
    buildingName: 'หอพักนิสิต 1',
    polygon: [
      LatLng(14.1064071, 100.9877709),
      LatLng(14.1060993, 100.9871826),
      LatLng(14.1058258, 100.9873388),
      LatLng(14.1061256, 100.9879258),
    ],
  ),
  BuildingBoundary(
    buildingCode: '47',
    buildingName: 'หอพักนิสิต 2',
    polygon: [
      LatLng(14.1059207, 100.9880142),
      LatLng(14.1056244, 100.9874684),
      LatLng(14.105364, 100.9876113),
      LatLng(14.1056488, 100.9881643),
    ],
  ),
  BuildingBoundary(
    buildingCode: '48',
    buildingName: 'หอพักนิสิต 3',
    polygon: [
      LatLng(14.1055849, 100.988221),
      LatLng(14.1052951, 100.9876756),
      LatLng(14.1051003, 100.9877854),
      LatLng(14.1053868, 100.9883281),
    ],
  ),
  BuildingBoundary(
    buildingCode: '49',
    buildingName: 'หอพักนิสิต 4',
    polygon: [
      LatLng(14.1051933, 100.9884436),
      LatLng(14.1048713, 100.9878211),
      LatLng(14.1046749, 100.9879365),
      LatLng(14.1049906, 100.9885574),
    ],
  ),
  BuildingBoundary(
    buildingCode: '50',
    buildingName: 'หอพักนิสิต 5',
    polygon: [
      LatLng(14.1068705, 100.9884247),
      LatLng(14.1066792, 100.9880409),
      LatLng(14.1064778, 100.9881436),
      LatLng(14.1066641, 100.9885296),
    ],
  ),
  BuildingBoundary(
    buildingCode: '51',
    buildingName: 'หอพักนิสิต 6',
    polygon: [
      LatLng(14.1064808, 100.9886419),
      LatLng(14.1062974, 100.9882717),
      LatLng(14.1061054, 100.9883746),
      LatLng(14.1062903, 100.98874),
    ],
  ),
  BuildingBoundary(
    buildingCode: '52',
    buildingName: 'หอพักนิสิต 7',
    polygon: [
      LatLng(14.1055454, 100.9891476),
      LatLng(14.1053558, 100.9887828),
      LatLng(14.1051538, 100.9888909),
      LatLng(14.105345, 100.9892572),
    ],
  ),
  BuildingBoundary(
    buildingCode: '53',
    buildingName: 'หอพักนิสิต 8',
    polygon: [
      LatLng(14.1055454, 100.9891476),
      LatLng(14.1053558, 100.9887828),
      LatLng(114.1051538, 100.9888909),
      LatLng(14.105345, 100.9892572),
    ],
  ),
  BuildingBoundary(
    buildingCode: '54',
    buildingName: 'หอพักนิสิต 9',
    polygon: [
      LatLng(14.1048359, 100.9895414),
      LatLng(14.1046452, 100.9891653),
      LatLng(14.104444, 100.9892754),
      LatLng(14.1046373, 100.9896533),
    ],
  ),
  BuildingBoundary(
    buildingCode: '55',
    buildingName: 'หอพักนิสิต 10',
    polygon: [
      LatLng(14.1044389, 100.989763),
      LatLng(14.1042477, 100.9893876),
      LatLng(14.104036, 100.9894995),
      LatLng(14.1042228, 100.98988),
    ],
  ),
  BuildingBoundary(
    buildingCode: '56',
    buildingName: 'หอพักนิสิต 11',
    polygon: [
      LatLng(14.1042449, 100.9888206),
      LatLng(14.1042678, 100.9884248),
      LatLng(14.1040599, 100.9884085),
      LatLng(14.1040329, 100.9888059),
    ],
  ),
  BuildingBoundary(
    buildingCode: '57',
    buildingName: 'หอพักนิสิต 12',
    polygon: [
      LatLng(14.103505, 100.9887031),
      LatLng(14.1036561, 100.9883456),
      LatLng(14.103466, 100.9882548),
      LatLng(14.1033118, 100.98862),
    ],
  ),
  BuildingBoundary(
    buildingCode: '58',
    buildingName: 'หอพักนิสิต 13',
    polygon: [
      LatLng(14.1032317, 100.9885746),
      LatLng(14.1033841, 100.9882243),
      LatLng(14.1031921, 100.9881316),
      LatLng(14.1030454, 100.9884828),
    ],
  ),
  BuildingBoundary(
    buildingCode: '59',
    buildingName: 'หอพักนิสิต 14',
    polygon: [
      LatLng(14.1028221, 100.9883981),
      LatLng(14.1029838, 100.9880487),
      LatLng(14.1027935, 100.9879582),
      LatLng(14.1026385, 100.9883182),
    ],
  ),
  BuildingBoundary(
    buildingCode: '60',
    buildingName: 'หอพักนิสิต 15',
    polygon: [
      LatLng(14.1025506, 100.9882677),
      LatLng(14.1027054, 100.9879126),
      LatLng(14.1025281, 100.9878315),
      LatLng(14.1023627, 100.988192),
    ],
  ),
  BuildingBoundary(
    buildingCode: '61',
    buildingName: 'หอพักนิสิต 16',
    polygon: [
      LatLng(14.1021492, 100.9880885),
      LatLng(14.1023064, 100.9877363),
      LatLng(14.1021199, 100.9876493),
      LatLng(14.101969, 100.9880103),
    ],
  ),
  BuildingBoundary(
    buildingCode: '62',
    buildingName: 'อาคารบริการนิสิต (อ๊อกตะ)',
    polygon: [
      LatLng(14.1060909, 100.9889131),
      LatLng(14.1060145, 100.9887572),
      LatLng(14.105901, 100.9888195),
      LatLng(14.1058896, 100.9887766),
      LatLng(14.1059445, 100.9886776),
      LatLng(14.105892, 100.9885363),
      LatLng(14.1057614, 100.9884971),
      LatLng(14.1056348, 100.9885687),
      LatLng(14.1055947, 100.9887055),
      LatLng(14.1056385, 100.9888254),
      LatLng(14.1057551, 100.9888661),
      LatLng(14.105767, 100.9888887),
      LatLng(14.1056796, 100.9889266),
      LatLng(14.1057548, 100.9890852),
    ],
  ),
  BuildingBoundary(
    buildingCode: '63',
    buildingName: 'โรงอาหารหอพักนิสิต (โรงเขียว)',
    polygon: [
      LatLng(14.1048084, 100.9886428),
      LatLng(14.1044744, 100.9880482),
      LatLng(14.1042389, 100.9881828),
      LatLng(14.1045756, 1100.9887772),
    ],
  ),
];
