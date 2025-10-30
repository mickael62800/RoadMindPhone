import 'package:latlong2/latlong.dart';

class SessionGpsPoint {
  int? id;
  final int sessionId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final int videoTimestampMs;

  SessionGpsPoint({
    this.id,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.heading,
    required this.timestamp,
    required this.videoTimestampMs,
  });

  // Convert a SessionGpsPoint into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
      'videoTimestampMs': videoTimestampMs,
    };
  }

  // Convert a Map into a SessionGpsPoint.
  factory SessionGpsPoint.fromMap(Map<String, dynamic> map) {
    return SessionGpsPoint(
      id: map['id'],
      sessionId: map['sessionId'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      altitude: map['altitude'],
      speed: map['speed'],
      heading: map['heading'],
      timestamp: DateTime.parse(map['timestamp']),
      videoTimestampMs: map['videoTimestampMs'],
    );
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }
}