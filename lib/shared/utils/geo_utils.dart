import 'package:latlong2/latlong.dart';
import '../constants/building_boundaries.dart';

/// ============================== [Point in Polygon Logic] ==============================

/// Checks if [point] is inside the shape [polygon].
/// How it works (Ray Casting): draw an imaginary line from the point going right,
/// and count how many times it crosses the shape's edges.
/// Odd number of crossings = inside. Even number = outside. [_isPointInPolygon]
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  if (polygon.length < 3) return false; // not a real shape, needs at least 3 points

  bool isInside = false;
  int previousIndex = polygon.length - 1;

  for (int currentIndex = 0; currentIndex < polygon.length; currentIndex++) {
    final currentPoint = polygon[currentIndex];
    final previousPoint = polygon[previousIndex];

    final currentLat = currentPoint.latitude;
    final currentLng = currentPoint.longitude;
    final previousLat = previousPoint.latitude;
    final previousLng = previousPoint.longitude;

    // Check if an imaginary horizontal line from our point crosses this edge
    final edgeCrossesLine = (currentLat > point.latitude) != (previousLat > point.latitude);

    if (edgeCrossesLine) {
      // Find where the edge crosses, and see if it's to the right of our point
      final crossingLng = (previousLng - currentLng) *
              (point.latitude - currentLat) /
              (previousLat - currentLat) +
          currentLng;

      if (point.longitude < crossingLng) {
        isInside = !isInside; // flip inside/outside each time we cross an edge
      }
    }

    previousIndex = currentIndex;
  }

  return isInside;
}

/// Finds which building [point] is inside. Returns the building name, or null if it's not inside any building. [getBuildingNameFromPoint]
String? getBuildingNameFromPoint(LatLng point) {
  for (final building in campusBuildings) {
    if (_isPointInPolygon(point, building.polygon)) {
      return building.buildingName;
    }
  }
  return null;
}

/// Same as above, but returns the building code instead (useful for matching with other data). [getBuildingCodeFromPoint]
String? getBuildingCodeFromPoint(LatLng point) {
  for (final building in campusBuildings) {
    if (_isPointInPolygon(point, building.polygon)) {
      return building.buildingCode;
    }
  }
  return null;
}
