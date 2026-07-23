import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/constants/report_constants.dart';

class ReportMarkerLayer extends StatefulWidget {
  final void Function(Map<String, dynamic> data)? onTapMarker;

  const ReportMarkerLayer({super.key, this.onTapMarker});

  @override
  State<ReportMarkerLayer> createState() => _ReportMarkerLayerState();
}

class _ReportMarkerLayerState extends State<ReportMarkerLayer> {
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('reports').get();

    final markers = snapshot.docs.map((doc) {
      final data = doc.data();

      final lat = data['lat'];
      final lng = data['lng'];

      if (lat == null || lng == null) return null;

      /// ดึงข้อมูลระดับความอันตรายของ report นี้ (เหมือนใน report_list_page.dart)
      final severityKey = data['severity'] as String?;
      final severity = getSeverityInfo(severityKey);
      final isHigh = severity.label == severityLevels['high']!.label;

      return Marker(
        point: LatLng(lat, lng),
        // High severity ใหญ่กว่านิดหน่อยให้เด่นขึ้นบนแผนที่
        width: isHigh ? 56 : 50,
        height: isHigh ? 56 : 50,
        child: GestureDetector(
          onTap: () {
            widget.onTapMarker?.call(data);
          },
          child: _buildMarkerIcon(severity, isHigh),
        ),
      );
    }).whereType<Marker>().toList();

    setState(() {
      _markers = markers;
    });
  }

  /// ไอคอนหมุด: สีตามระดับความอันตราย + มี outline สีขาวรอบไอคอน, high มี badge ตกใจ (!)
  Widget _buildMarkerIcon(SeverityInfo severity, bool isHigh) {
    final iconSize = isHigh ? 44.0 : 40.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Outline: ไอคอนสีขาวขนาดใหญ่กว่าเล็กน้อยอยู่ด้านหลัง ทำหน้าที่เป็นขอบ
        Icon(
          Icons.location_on,
          color: Colors.grey.shade600.withOpacity(0.6),
          size: iconSize + 4,
        ),
        // ไอคอนจริงสีตาม severity วางทับด้านบน
        Icon(
          Icons.location_on,
          color: severity.color,
          size: iconSize,
        ),
        if (isHigh)
          Positioned(
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: severity.color, width: 1.5),
              ),
              child: Text(
                '!',
                style: TextStyle(
                  color: severity.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(markers: _markers);
  }
}