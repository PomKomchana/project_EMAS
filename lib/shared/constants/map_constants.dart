import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Map mode [MapMode]
enum MapMode {
  normal,
  satellite,
}

/// Map Location & Bounds
/// Google Map Location and Bounds config [mapLocation, mapBounds]
const mapLocation = LatLng(14.1076, 100.9822);
final mapBounds = LatLngBounds.fromPoints([
  const LatLng(14.1010, 100.9750),
  const LatLng(14.1140, 100.9900),
]);

/// Tile URL templates for each map mode [mapModeTileUrl]
String mapModeTileUrl(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

    case MapMode.satellite:
      return 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  }
}

/// Icon for each Map Mode [mapModeIcon]
IconData mapModeIcon(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return Icons.map_rounded;

    case MapMode.satellite:
      return Icons.satellite_alt_rounded;
  }
}

/// Display Label for each map mode [mapModeLabel]
String mapModeLabel(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return 'ปกติ';

    case MapMode.satellite:
      return 'ไอบริด';
  }
}
