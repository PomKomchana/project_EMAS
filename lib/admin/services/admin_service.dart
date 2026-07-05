import 'package:cloud_firestore/cloud_firestore.dart';

// Centralizes all admin-side Firestore access for 'reports' and 'news'.
// User-facing report creation stays in report/services/report_service.dart —
// this service is for admin-only reads/writes (status changes, deletes, news CRUD). [AdminService]
class AdminService {
  final _reportsRef = FirebaseFirestore.instance.collection('reports');
  final _newsRef = FirebaseFirestore.instance.collection('news');

  /// ============================== [Report Reads] ==============================
  // Raw reports stream, unfiltered — used by the dashboard for stat counts [reportsStream]
  Stream<QuerySnapshot> reportsStream() {
    return _reportsRef.snapshots();
  }

  // Reports filtered by status, newest first — used by the admin tabbed list [reportsByStatusStream]
  Stream<QuerySnapshot> reportsByStatusStream(String status) {
    return _reportsRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ============================== [Report Writes] ==============================
  // Create a report on behalf of the admin (username fixed to 'Admin') [createReport]
  Future<void> createReport({
    required String building,
    required String floor,
    required String room,
    required String description,
    required String severity,
    required String status,
    double? lat,
    double? lng,
  }) {
    return _reportsRef.add({
      'building': building,
      'floor': floor,
      'room': room,
      'description': description,
      'severity': severity,
      'status': status,
      'lat': lat,
      'lng': lng,
      'username': 'Admin',
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update status + admin note on an existing report [updateReportStatus]
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String note,
  }) {
    return _reportsRef.doc(reportId).update({
      'status': status,
      'adminNote': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a report [deleteReport]
  Future<void> deleteReport(String reportId) {
    return _reportsRef.doc(reportId).delete();
  }

  /// ============================== [News Reads] ==============================
  // News stream, newest first [newsStream]
  Stream<QuerySnapshot> newsStream() {
    return _newsRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// ============================== [News Writes] ==============================
  // Create a news post [addNews]
  Future<void> addNews({
    required String title,
    required String content,
  }) {
    return _newsRef.add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing news post [updateNews]
  Future<void> updateNews({
    required String docId,
    required String title,
    required String content,
  }) {
    return _newsRef.doc(docId).update({
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a news post [deleteNews]
  Future<void> deleteNews(String docId) {
    return _newsRef.doc(docId).delete();
  }
}
