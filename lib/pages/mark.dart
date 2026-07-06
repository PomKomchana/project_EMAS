import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      return Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            widget.onTapMarker?.call(data);
          },
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }).whereType<Marker>().toList();

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(markers: _markers);
  }
}
