import 'package:flutter/material.dart';
import 'package:roadmindphone/main.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/project_index_page.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'mocks.mocks.dart';
import 'dart:math';
import 'mocks/mock_flutter_map.dart';

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
}

void main() {
  group('SessionIndexPage Widget Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late Project project;
    late Session sessionWithGps;
    late Session sessionWithoutGps;
    late double expectedTotalDistanceWithGps;
    late double expectedAverageSpeedWithGps;
    late double expectedTotalDistanceWithoutGps;
    late double expectedAverageSpeedWithoutGps;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      project = Project(id: 1, title: 'Test Project');

      sessionWithGps = Session(
        id: 1,
        projectId: project.id!,
        name: 'Session with GPS',
        duration: const Duration(minutes: 30),
        gpsPoints: 50,
        gpsData: [
          SessionGpsPoint(sessionId: 1, latitude: 48.8566, longitude: 2.3522, speed: 5.0, timestamp: DateTime.now(), videoTimestampMs: 0),
          SessionGpsPoint(sessionId: 1, latitude: 48.8580, longitude: 2.2945, speed: 10.0, timestamp: DateTime.now().add(const Duration(minutes: 1)), videoTimestampMs: 0),
        ],
      );

      sessionWithoutGps = Session(
        id: 2,
        projectId: project.id!,
        name: 'Session without GPS',
        duration: const Duration(minutes: 10),
        gpsPoints: 0,
      );

      // Calculate expected values for sessionWithGps
      if (sessionWithGps.gpsData.length > 1) {
        double totalDistance = 0;
        double totalSpeed = 0;

        for (int i = 0; i < sessionWithGps.gpsData.length - 1; i++) {
          final point1 = sessionWithGps.gpsData[i];
          final point2 = sessionWithGps.gpsData[i + 1];
          totalDistance += _calculateDistance(
            point1.latitude,
            point1.longitude,
            point2.latitude,
            point2.longitude,
          );
        }

        for (final point in sessionWithGps.gpsData) {
          totalSpeed += point.speed ?? 0.0;
        }

        expectedTotalDistanceWithGps = totalDistance;
        expectedAverageSpeedWithGps = sessionWithGps.gpsData.isNotEmpty
            ? totalSpeed / sessionWithGps.gpsData.length * 3.6
            : 0.0;
      } else {
        expectedTotalDistanceWithGps = 0.0;
        expectedAverageSpeedWithGps = 0.0;
      }

      // Calculate expected values for sessionWithoutGps
      expectedTotalDistanceWithoutGps = 0.0;
      expectedAverageSpeedWithoutGps = 0.0;

      when(mockDbHelper.updateSession(any))
          .thenAnswer((invocation) async => 1);
      when(mockDbHelper.deleteSession(any))
          .thenAnswer((_) async => 1);
      when(mockDbHelper.readProject(project.id!))
          .thenAnswer((_) async => project);
      when(mockDbHelper.readSession(sessionWithGps.id!))
          .thenAnswer((_) async => sessionWithGps);
      when(mockDbHelper.readSession(sessionWithoutGps.id!))
          .thenAnswer((_) async => sessionWithoutGps);
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => [project]);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets('Displays session details correctly with GPS data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(
          session: sessionWithGps,
          flutterMapBuilder: ({key, required options, children, mapController}) {
            return MockFlutterMap(
              key: key,
              options: options,
              children: children ?? [],
              mapController: mapController,
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session with GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.text('${expectedAverageSpeedWithGps.toStringAsFixed(2)} km/h'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('${expectedTotalDistanceWithGps.toStringAsFixed(2)} km'), findsOneWidget);
    });

    testWidgets('Displays session details correctly without GPS data', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(
          session: sessionWithoutGps,
          flutterMapBuilder: ({key, required options, children, mapController}) {
            return MockFlutterMap(
              key: key,
              options: options,
              children: children ?? [],
              mapController: mapController,
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Session without GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.text('${expectedAverageSpeedWithoutGps.toStringAsFixed(2)} km/h'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('${expectedTotalDistanceWithoutGps.toStringAsFixed(2)} km'), findsOneWidget);
      expect(find.text('En attente de données'), findsOneWidget);
    });

    testWidgets('Renames a session', (WidgetTester tester) async {
      when(mockDbHelper.updateSession(any))
          .thenAnswer((_) async => 1);

      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(
          session: sessionWithGps,
          flutterMapBuilder: ({key, required options, children, mapController}) {
            return MockFlutterMap(
              key: key,
              options: options,
              children: children ?? [],
              mapController: mapController,
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'));
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Renamed Session');
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed Session'), findsOneWidget);
      expect(find.text('Session with GPS'), findsNothing);
    });

    testWidgets('Deletes a session', (WidgetTester tester) async {
      when(mockDbHelper.deleteSession(sessionWithGps.id!))
          .thenAnswer((_) async => 1);
      when(mockDbHelper.readAllSessionsForProject(project.id!))
          .thenAnswer((_) async => []); // After deletion, no sessions

      await tester.pumpWidget(MaterialApp(
        home: SessionIndexPage(
          session: sessionWithGps,
          flutterMapBuilder: ({key, required options, children, mapController}) {
            return MockFlutterMap(
              key: key,
              options: options,
              children: children ?? [],
              mapController: mapController,
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'Supprimer'
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      expect(find.text('Supprimer la session'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      // Add this line to ensure MyHomePage is rebuilt
      await tester.pumpAndSettle();

      // Verify navigation back to ProjectIndexPage and session is gone
      expect(find.byType(SessionIndexPage), findsNothing); // SessionIndexPage should be gone
      expect(find.text('Session with GPS'), findsNothing); // Session should be deleted
    });
  });
}
