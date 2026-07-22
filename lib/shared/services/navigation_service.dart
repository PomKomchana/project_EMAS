// lib/shared/services/navigation_service.dart
import 'package:flutter/material.dart';

// Root navigator key — ให้ service ที่ไม่มี BuildContext (เช่น push notification)
// เรียก Navigator.push ได้ [navigatorKey]
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// สั่งให้ MainPage สลับ bottom-nav tab จากข้างนอก (เช่นตอนกด notification)
// MainPage ฟัง notifier ตัวนี้ผ่าน addListener ใน initState [mainTabRequest]
final ValueNotifier<int?> mainTabRequest = ValueNotifier<int?>(null);

// Tab index ของแต่ละหน้า ให้เรียกจากที่อื่นแบบมีชื่อ ไม่ต้องจำเลขมั่ว [MainTab]
class MainTab {
  static const home = 0;
  static const reportList = 1;
  static const announcement = 2;
  static const profile = 3;
}
