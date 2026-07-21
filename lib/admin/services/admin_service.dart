import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Centralizes all admin-side Firestore access for 'reports' and 'news'.
// User-facing report creation stays in report/services/report_service.dart —
// this service is for admin-only reads/writes (status changes, deletes, news CRUD). [AdminService]
class AdminService {
  final _reportsRef = FirebaseFirestore.instance.collection('reports');
  final _newsRef = FirebaseFirestore.instance.collection('news');
  final _storage = FirebaseStorage.instance;

  /// ============================== [Image Upload] ==============================
  // Upload a picked image to Storage, return its download URL. Stored under
  // reports/admin/<uid>/ to keep admin-created report images separate from
  // user-submitted ones. Same pattern as ReportService._uploadImage. [_uploadImage]
  Future<String?> _uploadImage(File image) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

    final ref = _storage
        .ref()
        .child('reports')
        .child('admin')
        .child(uid)
        .child(fileName);

    final uploadTask = await ref.putFile(image);

    return uploadTask.ref.getDownloadURL();
  }

  // Same upload pattern as _uploadImage, but stored under news/<uid>/ so
  // announcement images stay separate from report images. [_uploadNewsImage]
  Future<String?> _uploadNewsImage(File image) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

    final ref = _storage.ref().child('news').child(uid).child(fileName);

    final uploadTask = await ref.putFile(image);

    return uploadTask.ref.getDownloadURL();
  }

  /// ============================== [Report Reads] ==============================
  // Raw reports stream, unfiltered — used by the dashboard for stat counts [reportsStream]
  Stream<QuerySnapshot> reportsStream() {
    return _reportsRef.snapshots();
  }

  // Reports filtered by status, newest first — used by the admin tabbed list.
  // Scope (user/admin) is applied client-side on top of this in AdminReportListPage. [reportsByStatusStream]
  Stream<QuerySnapshot> reportsByStatusStream(String status) {
    return _reportsRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Reports created by an admin (via createReport), newest first — used to
  // merge admin-created reports into the announcements feed. [adminReportsStream]
  Stream<QuerySnapshot> adminReportsStream() {
    return _reportsRef
        .where('createdBy', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ============================== [Report Writes] ==============================
  // Create a report on behalf of the admin (username fixed to 'Admin').
  // Uploads image first (if provided) so imageUrl is written in the same
  // add() call — avoids a partial doc with no image. [createReport]
  Future<void> createReport({
    required String building,
    required String floor,
    required String room,
    required String description,
    required String severity,
    required String status,
    double? lat,
    double? lng,
    File? image,
  }) async {
    final imageUrl = image != null ? await _uploadImage(image) : null;

    await _reportsRef.add({
      'building': building,
      'floor': floor,
      'room': room,
      'description': description,
      'severity': severity,
      'status': status,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'username': 'Admin',
      'createdBy': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update status + admin note on an existing report [updateReportStatus]
  Future<void> updateReportStatus({
    required String reportId,
    required String status,
    required String severity,
    required String note,
  }) {
    return _reportsRef.doc(reportId).update({
      'status': status,
      'severity': severity,
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
  // Create a news post. Uploads image first (if provided) so imageUrl is
  // written in the same add() call, same reasoning as createReport. [addNews]
  Future<void> addNews({
    required String title,
    required String content,
    String? link,
    File? image,
  }) async {
    final imageUrl = image != null ? await _uploadNewsImage(image) : null;

    await _newsRef.add({
      'title': title,
      'content': content,
      'link': link,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing news post. Pass `image` to upload+replace the photo,
  // `removeImage: true` to clear it, or leave both alone (with
  // `existingImageUrl` unchanged) to keep the current photo as-is. [updateNews]
  Future<void> updateNews({
    required String docId,
    required String title,
    required String content,
    String? link,
    File? image,
    bool removeImage = false,
    String? existingImageUrl,
  }) async {
    String? imageUrl = existingImageUrl;
    if (image != null) {
      imageUrl = await _uploadNewsImage(image);
    } else if (removeImage) {
      imageUrl = null;
    }

    await _newsRef.doc(docId).update({
      'title': title,
      'content': content,
      'link': link,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a news post [deleteNews]
  Future<void> deleteNews(String docId) {
    return _newsRef.doc(docId).delete();
  }
}
