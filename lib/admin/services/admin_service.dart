import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// All admin Firestore work for 'reports' and 'news'. User-side report
// creation stays in report_service.dart — this is admin-only. [AdminService]
class AdminService {
  final _reportsRef = FirebaseFirestore.instance.collection('reports');
  final _newsRef = FirebaseFirestore.instance.collection('news');
  final _storage = FirebaseStorage.instance;

  /// ============================== [Image Upload] ==============================
  // Upload a report image, return its URL. Saved under reports/admin/<uid>/. [_uploadImage]
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

  // Same as _uploadImage but for news, saved under news/<uid>/. [_uploadNewsImage]
  Future<String?> _uploadNewsImage(File image) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

    final ref = _storage
        .ref()
        .child('news')
        .child(uid)
        .child(fileName);

    final uploadTask = await ref.putFile(image);

    return uploadTask.ref.getDownloadURL();
  }

  /// ============================== [Auth] ==============================
  // Re-check the admin's password before delete. Used by
  // showDeleteConfirmDialog. Returns false on any error. [reauthenticate]
  Future<bool> reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return false;

    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// ============================== [Report Reads] ==============================
  // All reports, no filter. Used for dashboard counts. [reportsStream]
  Stream<QuerySnapshot> reportsStream() {
    return _reportsRef.snapshots();
  }

  // Reports by status, newest first. User/admin scope is filtered later in
  // AdminReportListPage. [reportsByStatusStream]
  Stream<QuerySnapshot> reportsByStatusStream(String status) {
    return _reportsRef
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ============================== [Report Writes] ==============================
  // Create a report as admin (username set to 'Admin'). Uploads image
  // first so imageUrl is set in the same write. [createReport]
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

  // Update status, severity, and admin note on a report [updateReportStatus]
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
  // News, newest first [newsStream]
  Stream<QuerySnapshot> newsStream() {
    return _newsRef.orderBy('createdAt', descending: true).snapshots();
  }

  /// ============================== [News Writes] ==============================
  // Create a news post. Uploads image first, same reason as createReport. [addNews]
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

  // Update a news post. Pass `image` to replace the photo, `removeImage:
  // true` to clear it, or leave both alone to keep it as-is. [updateNews]
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
