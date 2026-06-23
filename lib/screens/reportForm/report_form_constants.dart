import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

/// <<<<< Theme Colors >>>>>>
// EMAS Theme Colors [emasColor, emasColorDarker]
// NOTE: duplicated in report_list_constants.dart
const emasColor = Color(0xFFe85d6a);
const emasColorDarker = Color(0xFFc4394a);

/// <<<<< Map Location & Bounds >>>>>>
// Google Map Location and Bounds config [mapLocation, mapBounds]
const mapLocation = LatLng(14.1076, 100.9822);
final mapBounds = LatLngBounds(
  const LatLng(14.1010, 100.9750),
  const LatLng(14.1140, 100.9900),
);

/// <<<<< Tile URLs - GoogleMap >>>>>>
// Tile URL templates for each map mode [tileNormal, tileSatellite]
const tileNormal = 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const tileSatellite = 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';

/// <<<<< Map Mode >>>>>>
// Map display mode [MapMode]
enum MapMode {normal, satellite}

// ==== Free functions so any widget can use them without the form's State ====
// [mapModeTileUrl, mapModeLabel, mapModeIcon]

// Tile URL for the mode
String mapModeTileUrl(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return tileNormal;
    case MapMode.satellite:
      return tileSatellite;
  }
}

// Thai label for the mode
String mapModeLabel(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return 'ปกติ';
    case MapMode.satellite:
      return 'ดาวเทียม';
  }
}

// Icon for the mode switch button
IconData mapModeIcon(MapMode mode) {
  switch (mode) {
    case MapMode.normal:
      return Icons.layers_outlined;
    case MapMode.satellite:
      return Icons.satellite_alt;
  }
}

/// <<<<< Dropdown Options >>>>>>
// Dropdown Options [buildingOptions, floorOptions, roomOptions]
// roomOptions: unused, room is a free-text field
const buildingOptions = ['อาคาร 1', 'อาคาร 2', 'อาคาร 3', 'อาคาร 4', 'อาคาร 5'];
const floorOptions = ['ชั้น 1', 'ชั้น 2', 'ชั้น 3', 'ชั้น 4', 'ชั้น 5'];
const roomOptions = ['110', '111', '112', '113', '114'];
