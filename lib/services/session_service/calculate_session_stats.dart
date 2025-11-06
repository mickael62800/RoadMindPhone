import 'dart:math';
import 'package:roadmindphone/session.dart';

/// Calcule la distance totale (en km) et la vitesse moyenne (en km/h) d'une session.
Map<String, double> calculateSessionStats(Session session) {
  double totalDistance = 0;
  double totalSpeed = 0;
  final gpsData = session.gpsData;

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  if (gpsData.length > 1) {
    for (int i = 0; i < gpsData.length - 1; i++) {
      final point1 = gpsData[i];
      final point2 = gpsData[i + 1];
      totalDistance += calculateDistance(
        point1.latitude,
        point1.longitude,
        point2.latitude,
        point2.longitude,
      );
    }
    for (final point in gpsData) {
      totalSpeed += point.speed ?? 0.0;
    }
  }

  final averageSpeed = gpsData.isNotEmpty
      ? totalSpeed /
            gpsData.length *
            3.6 // m/s to km/h
      : 0.0;

  return {'totalDistance': totalDistance, 'averageSpeed': averageSpeed};
}
