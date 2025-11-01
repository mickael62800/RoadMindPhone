import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'dart:convert';

void main() {
  group('Session', () {
    test('Session can be created with required fields', () {
      final session = Session(
        projectId: 1,
        name: 'Test Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 100,
      );
      expect(session.projectId, 1);
      expect(session.name, 'Test Session');
      expect(session.duration, const Duration(minutes: 10));
      expect(session.gpsPoints, 100);
      expect(session.id, isNull);
      expect(session.videoPath, isNull);
      expect(session.gpsData, isEmpty);
    });

    test('Session can be created with all fields', () {
      final gpsData = [
        SessionGpsPoint(
          sessionId: 1,
          latitude: 1.0,
          longitude: 2.0,
          speed: 10.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 0,
        ),
        SessionGpsPoint(
          sessionId: 1,
          latitude: 3.0,
          longitude: 4.0,
          speed: 20.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 0,
        ),
      ];
      final session = Session(
        id: 1,
        projectId: 2,
        name: 'Test Session 2',
        duration: const Duration(hours: 1),
        gpsPoints: 200,
        videoPath: '/path/to/video.mp4',
        gpsData: gpsData,
      );
      expect(session.id, 1);
      expect(session.projectId, 2);
      expect(session.name, 'Test Session 2');
      expect(session.duration, const Duration(hours: 1));
      expect(session.gpsPoints, 200);
      expect(session.videoPath, '/path/to/video.mp4');
      expect(session.gpsData, gpsData);
    });

    test('Session.copy creates a new instance with updated values', () {
      final originalSession = Session(
        id: 1,
        projectId: 1,
        name: 'Original Session',
        duration: const Duration(minutes: 30),
        gpsPoints: 50,
      );

      final updatedSession = originalSession.copy(
        name: 'Updated Session',
        gpsPoints: 75,
      );

      expect(updatedSession.id, originalSession.id);
      expect(updatedSession.projectId, originalSession.projectId);
      expect(updatedSession.name, 'Updated Session');
      expect(updatedSession.duration, originalSession.duration);
      expect(updatedSession.gpsPoints, 75);
      expect(
        originalSession.name,
        'Original Session',
      ); // Ensure original is unchanged
    });

    test('Session.fromMap creates a Session object from a map', () {
      final gpsData = [
        SessionGpsPoint(
          sessionId: 1,
          latitude: 1.0,
          longitude: 2.0,
          speed: 10.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 0,
        ),
      ];
      final map = {
        'id': 1,
        'projectId': 1,
        'name': 'Mapped Session',
        'duration': const Duration(minutes: 15).inMilliseconds,
        'gpsPoints': 30,
        'videoPath': '/path/to/mapped_video.mp4',
        'gpsData': json.encode(gpsData.map((e) => e.toMap()).toList()),
      };
      final session = Session.fromMap(map);
      expect(session.id, 1);
      expect(session.projectId, 1);
      expect(session.name, 'Mapped Session');
      expect(session.duration, const Duration(minutes: 15));
      expect(session.gpsPoints, 30);
      expect(session.videoPath, '/path/to/mapped_video.mp4');
      expect(session.gpsData.length, 1);
      expect(session.gpsData[0].latitude, 1.0);
      expect(session.gpsData[0].longitude, 2.0);
      expect(session.gpsData[0].speed, 10.0);
    });

    test('Session.toMap converts a Session object to a map', () {
      final gpsData = [
        SessionGpsPoint(
          sessionId: 2,
          latitude: 1.0,
          longitude: 2.0,
          speed: 10.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 0,
        ),
      ];
      final session = Session(
        id: 2,
        projectId: 2,
        name: 'Session to Map',
        duration: const Duration(minutes: 20),
        gpsPoints: 40,
        videoPath: '/path/to/video_to_map.mp4',
        gpsData: gpsData,
      );
      final map = session.toMap();
      expect(map['id'], 2);
      expect(map['projectId'], 2);
      expect(map['name'], 'Session to Map');
      expect(map['duration'], const Duration(minutes: 20).inMilliseconds);
      expect(map['gpsPoints'], 40);
      expect(map['videoPath'], '/path/to/video_to_map.mp4');
      expect(
        map['gpsData'],
        json.encode(gpsData.map((e) => e.toMap()).toList()),
      );
    });

    test('Session.fromMap handles null gpsData', () {
      final map = {
        'id': 3,
        'projectId': 3,
        'name': 'Session with null GPS',
        'duration': const Duration(minutes: 5).inMilliseconds,
        'gpsPoints': 0,
        'videoPath': null,
        'gpsData': null,
      };
      final session = Session.fromMap(map);
      expect(session.id, 3);
      expect(session.projectId, 3);
      expect(session.name, 'Session with null GPS');
      expect(session.duration, const Duration(minutes: 5));
      expect(session.gpsPoints, 0);
      expect(session.videoPath, null);
      expect(session.gpsData, isEmpty); // Should be empty list, not null
    });
  });
}
