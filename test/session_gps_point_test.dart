import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('SessionGpsPoint', () {
    test('toMap converts object to map correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final point = SessionGpsPoint(
        id: 1,
        sessionId: 10,
        latitude: 45.5,
        longitude: -73.5,
        altitude: 100.0,
        speed: 50.0,
        heading: 180.0,
        timestamp: timestamp,
        videoTimestampMs: 5000,
      );

      final map = point.toMap();

      expect(map['id'], 1);
      expect(map['sessionId'], 10);
      expect(map['latitude'], 45.5);
      expect(map['longitude'], -73.5);
      expect(map['altitude'], 100.0);
      expect(map['speed'], 50.0);
      expect(map['heading'], 180.0);
      expect(map['timestamp'], timestamp.toIso8601String());
      expect(map['videoTimestampMs'], 5000);
    });

    test('toMap handles null values', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final point = SessionGpsPoint(
        sessionId: 10,
        latitude: 45.5,
        longitude: -73.5,
        timestamp: timestamp,
        videoTimestampMs: 5000,
      );

      final map = point.toMap();

      expect(map['id'], null);
      expect(map['altitude'], null);
      expect(map['speed'], null);
      expect(map['heading'], null);
    });

    test('fromMap converts map to object correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final map = {
        'id': 1,
        'sessionId': 10,
        'latitude': 45.5,
        'longitude': -73.5,
        'altitude': 100.0,
        'speed': 50.0,
        'heading': 180.0,
        'timestamp': timestamp.toIso8601String(),
        'videoTimestampMs': 5000,
      };

      final point = SessionGpsPoint.fromMap(map);

      expect(point.id, 1);
      expect(point.sessionId, 10);
      expect(point.latitude, 45.5);
      expect(point.longitude, -73.5);
      expect(point.altitude, 100.0);
      expect(point.speed, 50.0);
      expect(point.heading, 180.0);
      expect(point.timestamp, timestamp);
      expect(point.videoTimestampMs, 5000);
    });

    test('fromMap handles null values', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final map = {
        'sessionId': 10,
        'latitude': 45.5,
        'longitude': -73.5,
        'timestamp': timestamp.toIso8601String(),
        'videoTimestampMs': 5000,
      };

      final point = SessionGpsPoint.fromMap(map);

      expect(point.id, null);
      expect(point.altitude, null);
      expect(point.speed, null);
      expect(point.heading, null);
    });

    test('toLatLng converts to LatLng correctly', () {
      final point = SessionGpsPoint(
        sessionId: 10,
        latitude: 45.5,
        longitude: -73.5,
        timestamp: DateTime.now(),
        videoTimestampMs: 5000,
      );

      final latLng = point.toLatLng();

      expect(latLng.latitude, 45.5);
      expect(latLng.longitude, -73.5);
      expect(latLng, isA<LatLng>());
    });

    test('creates object with all parameters', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final point = SessionGpsPoint(
        id: 1,
        sessionId: 10,
        latitude: 45.5,
        longitude: -73.5,
        altitude: 100.0,
        speed: 50.0,
        heading: 180.0,
        timestamp: timestamp,
        videoTimestampMs: 5000,
      );

      expect(point.id, 1);
      expect(point.sessionId, 10);
      expect(point.latitude, 45.5);
      expect(point.longitude, -73.5);
      expect(point.altitude, 100.0);
      expect(point.speed, 50.0);
      expect(point.heading, 180.0);
      expect(point.timestamp, timestamp);
      expect(point.videoTimestampMs, 5000);
    });

    test('creates object with only required parameters', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final point = SessionGpsPoint(
        sessionId: 10,
        latitude: 45.5,
        longitude: -73.5,
        timestamp: timestamp,
        videoTimestampMs: 5000,
      );

      expect(point.id, null);
      expect(point.sessionId, 10);
      expect(point.latitude, 45.5);
      expect(point.longitude, -73.5);
      expect(point.altitude, null);
      expect(point.speed, null);
      expect(point.heading, null);
      expect(point.timestamp, timestamp);
      expect(point.videoTimestampMs, 5000);
    });
  });
}
