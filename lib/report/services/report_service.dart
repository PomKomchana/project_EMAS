import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/constants/report_constants.dart';

/// Service for managing the Firestore collection "reports" [ReportService]
class ReportService {
  final _reportsRef = FirebaseFirestore.instance.collection('reports');
  final _storage = FirebaseStorage.instance;

  /// ============================== [Image Upload] ==============================
  /// Upload a picked image to Storage, return its download URL. Returns null if image is null. [_uploadImage]
 Future<String?> _uploadImage(File image) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final fileName =
      '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

  final ref = _storage
      .ref()
      .child('reports')
      .child(uid)
      .child(fileName);

  final uploadTask = await ref.putFile(image);

  return uploadTask.ref.getDownloadURL();
}

  /// ============================== [Report Write] ==============================
  /// Submit new report to Firestore. Uploads image first (if provided) so imageUrl
  /// is written in the same add() call — avoids a partial doc with no image. [submitReport]
  Future<void> submitReport({
    required String date,
    required String username,
    required String phone,
    required String building,
    required String floor,
    required String room,
    required String description,
    LatLng? location,
    File? image,
  }) async {
    final imageUrl = image != null ? await _uploadImage(image) : null;

    await _reportsRef.add({
      'date': date,
      'username': username,
      'phone': phone,
      'building': building,
      'floor': floor,
      'room': room,
      'description': description.trim(),
      'status': ReportStatus.pending,
      'lat': location?.latitude,
      'lng': location?.longitude,
      'imageUrl': imageUrl,
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
