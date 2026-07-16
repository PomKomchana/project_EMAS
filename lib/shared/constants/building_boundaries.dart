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
    buildingCode: '31',
    buildingName: 'อาคารปฏิบัติการวิศกรรมไฟฟ้า',
    polygon: [
      LatLng(14.1028898, 100.9829694),
      LatLng(14.1025572, 100.9823328),
      LatLng(14.1022319, 100.9825062),
      LatLng(14.1025623, 100.9831283),
    ],
  ),
  BuildingBoundary(
    buildingCode: '32',
    buildingName: 'อาคารปฏิบัติการวิศวกรรมเครื่องกล (อาคาร D)',
    polygon: [
      LatLng(14.1025096, 100.9831966),
      LatLng(14.1021681, 100.9825407),
      LatLng(14.1018357, 100.9827262),
      LatLng(14.1021756, 100.9833742),
    ],
  ),
  BuildingBoundary(
    buildingCode: '33',
    buildingName: 'อาคารปฏิบัติการวิศวกรรมเคมี (อาคาร E)',
    polygon: [
      LatLng(14.1019667, 100.9834772),
      LatLng(14.1016318, 100.9828309),
      LatLng(14.1013061, 100.9830129),
      LatLng(14.1016411, 100.9836505),
    ],
  ),
  BuildingBoundary(
    buildingCode: '34',
    buildingName: 'ตึกวิศวกรรมอุตสาหการ (อาคาร I)',
    polygon: [
      LatLng(14.1019667, 100.9834772),
      LatLng(14.1016318, 100.9828309),
      LatLng(14.1013061, 100.9830129),
      LatLng(14.1016411, 100.9836505),
    ],
  ),
  BuildingBoundary(
    buildingCode: '75',
    buildingName: 'อาคารวิจัยและพัฒนาเทคโนโลยีทางวิศวกรรมไฟฟ้า (อาคาร G)',
    polygon: [
      LatLng(14.1017102, 100.9837839),
      LatLng(14.1013088, 100.9830095),
      LatLng(14.1008864, 100.9832613),
      LatLng(14.1012804, 100.9840287),
    ],
  ),
];
