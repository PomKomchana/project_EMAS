// lib/shared/services/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'navigation_service.dart';
import '../../report/pages/report_detail_page.dart';

class NotifType {
  static const news = 'news';
  static const report = 'report';
}

class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._();
  PushNotificationService._();

  final _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _fln.initialize(initSettings);

    await _saveToken();
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => _saveToken());

    // แอปเปิดอยู่ (foreground) → เด้ง local notification เอง
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // แอปอยู่ background แล้วผู้ใช้กด notification → navigate ทันที
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTap(message.data);
    });

    // แอปถูก terminate แล้วเปิดจาก notification → เช็คตอน start
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      // รอ frame แรกให้ MainPage/Navigator ถูกสร้างก่อนค่อย navigate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTap(initialMessage.data);
      });
    }
  }

  bool _shouldNotify(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == NotifType.news) return true;
    if (type == NotifType.report) return data['severity'] == 'high';
    return false;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    if (!_shouldNotify(data)) return;

    final notification = message.notification;
    final title = notification?.title ?? _defaultTitle(data['type']);
    final body = notification?.body ?? data['body'] ?? '';

    _fln.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'emas_channel',
          'EMAS Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // กด notification แล้วพาไปหน้าที่ถูกต้อง ตาม data['type'] [_handleTap]
  Future<void> _handleTap(Map<String, dynamic> data) async {
    final type = data['type'];

    if (type == NotifType.news) {
      // สลับ MainPage ไป tab ข่าวสาร
      mainTabRequest.value = MainTab.announcement;
      return;
    }

    if (type == NotifType.report) {
      final reportId = data['reportId'] as String?;
      if (reportId == null) return;

      try {
        final doc = await FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .get();

        if (!doc.exists) return;

        final reportData = doc.data()!;
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ReportDetailPage(data: reportData, id: doc.id),
          ),
        );
      } catch (e) {
        debugPrint('Failed to open report from notification: $e');
      }
    }
  }

  String _defaultTitle(String? type) {
    switch (type) {
      case NotifType.news:
        return 'ประกาศใหม่';
      case NotifType.report:
        return 'แจ้งเตือนความเสี่ยงสูง';
      default:
        return 'EMAS';
    }
  }

  Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
