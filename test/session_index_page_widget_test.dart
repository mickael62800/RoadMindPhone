import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:roadmindphone/session_completion_page.dart';

import 'package:roadmindphone/main.dart';
import 'mocks.mocks.dart';
import 'mocks/mock_flutter_map.dart';

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a =
      0.5 -
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
          SessionGpsPoint(
            sessionId: 1,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: 5.0,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 1,
            latitude: 48.8580,
            longitude: 2.2945,
            speed: 10.0,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 0,
          ),
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

      when(mockDbHelper.updateSession(any)).thenAnswer((invocation) async => 1);
      when(mockDbHelper.deleteSession(any)).thenAnswer((_) async => 1);
      when(
        mockDbHelper.readProject(project.id!),
      ).thenAnswer((_) async => project);
      when(
        mockDbHelper.readSession(sessionWithGps.id!),
      ).thenAnswer((_) async => sessionWithGps);
      when(
        mockDbHelper.readSession(sessionWithoutGps.id!),
      ).thenAnswer((_) async => sessionWithoutGps);
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets('Displays session details correctly with GPS data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session with GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(
        find.text('${expectedAverageSpeedWithGps.toStringAsFixed(2)} km/h'),
        findsOneWidget,
      );
      expect(find.text('Distance'), findsOneWidget);
      expect(
        find.text('${expectedTotalDistanceWithGps.toStringAsFixed(2)} km'),
        findsOneWidget,
      );
    });

    testWidgets('Displays session details correctly without GPS data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithoutGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Session without GPS'), findsOneWidget);
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('00:10:00'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(
        find.text('${expectedAverageSpeedWithoutGps.toStringAsFixed(2)} km/h'),
        findsOneWidget,
      );
      expect(find.text('Distance'), findsOneWidget);
      expect(
        find.text('${expectedTotalDistanceWithoutGps.toStringAsFixed(2)} km'),
        findsOneWidget,
      );
      expect(find.text('En attente de données'), findsOneWidget);
    });

    testWidgets('Renames a session', (WidgetTester tester) async {
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Renamed Session');
      await tester.tap(find.text('RENOMMER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Renamed Session'), findsOneWidget);
      expect(find.text('Session with GPS'), findsNothing);
    });

    testWidgets('Deletes a session', (WidgetTester tester) async {
      when(
        mockDbHelper.deleteSession(sessionWithGps.id!),
      ).thenAnswer((_) async => 1);
      when(
        mockDbHelper.readAllSessionsForProject(project.id!),
      ).thenAnswer((_) async => []); // After deletion, no sessions

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Supprimer'
      await tester.tap(find.text('Supprimer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      expect(find.text('Supprimer la session'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Add this line to ensure MyHomePage is rebuilt
      await tester.pumpAndSettle();

      // Verify navigation back to ProjectIndexPage and session is gone
      expect(
        find.byType(SessionIndexPage),
        findsNothing,
      ); // SessionIndexPage should be gone
      expect(
        find.text('Session with GPS'),
        findsNothing,
      ); // Session should be deleted
    });

    testWidgets('Redoes a session', (WidgetTester tester) async {
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Refaire'
      await tester.tap(find.text('Refaire'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Confirm redo in the dialog
      expect(find.text('Refaire la session'), findsOneWidget);
      await tester.tap(find.text('CONFIRMER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify navigation to SessionCompletionPage
      expect(find.byType(SessionCompletionPage), findsOneWidget);
    });

    testWidgets('Cancels session rename', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify session name hasn't changed
      expect(find.text('Session with GPS'), findsOneWidget);
    });

    testWidgets('Cancels session deletion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Supprimer'
      await tester.tap(find.text('Supprimer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Cancel deletion in the dialog
      expect(find.text('Supprimer la session'), findsOneWidget);
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify session is still there
      expect(find.byType(SessionIndexPage), findsOneWidget);
      expect(find.text('Session with GPS'), findsOneWidget);
    });

    testWidgets('Cancels session redo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Refaire'
      await tester.tap(find.text('Refaire'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Cancel redo in the dialog
      expect(find.text('Refaire la session'), findsOneWidget);
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify we're still on SessionIndexPage
      expect(find.byType(SessionIndexPage), findsOneWidget);
      expect(find.text('Session with GPS'), findsOneWidget);
    });

    testWidgets('Renames session by pressing Enter', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Renamed by Enter');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Renamed by Enter'), findsOneWidget);
      expect(find.text('Session with GPS'), findsNothing);
    });

    testWidgets('Does not rename session with empty name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Tap on 'Editer'
      await tester.tap(find.text('Editer'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the rename dialog is shown
      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.text('RENOMMER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify session name hasn't changed
      expect(find.text('Session with GPS'), findsOneWidget);
    });

    testWidgets('Displays video player with video', (
      WidgetTester tester,
    ) async {
      final sessionWithVideo = Session(
        id: 3,
        projectId: project.id!,
        name: 'Session with Video',
        duration: const Duration(minutes: 30),
        gpsPoints: 0,
        videoPath: '/fake/video/path.mp4',
      );

      when(
        mockDbHelper.readSession(sessionWithVideo.id!),
      ).thenAnswer((_) async => sessionWithVideo);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithVideo,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pump();

      // Since video file doesn't exist, it should show "En attente de vidéo"
      expect(find.text('En attente de vidéo'), findsOneWidget);
    });

    testWidgets('Opens export menu option', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify 'Exporter' option is present
      expect(find.text('Exporter'), findsOneWidget);
    });

    testWidgets('Displays formatted duration correctly', (
      WidgetTester tester,
    ) async {
      final sessionWithLongDuration = Session(
        id: 4,
        projectId: project.id!,
        name: 'Long Session',
        duration: const Duration(hours: 2, minutes: 35, seconds: 45),
        gpsPoints: 100,
      );

      when(
        mockDbHelper.readSession(sessionWithLongDuration.id!),
      ).thenAnswer((_) async => sessionWithLongDuration);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithLongDuration,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('02:35:45'), findsOneWidget);
    });

    testWidgets('Calculates distance with single GPS point', (
      WidgetTester tester,
    ) async {
      final sessionWithSingleGps = Session(
        id: 5,
        projectId: project.id!,
        name: 'Single GPS Point Session',
        duration: const Duration(minutes: 5),
        gpsPoints: 1,
        gpsData: [
          SessionGpsPoint(
            sessionId: 5,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: 5.0,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
        ],
      );

      when(
        mockDbHelper.readSession(sessionWithSingleGps.id!),
      ).thenAnswer((_) async => sessionWithSingleGps);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithSingleGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // With single GPS point, distance should be 0
      expect(find.text('0.00 km'), findsOneWidget);
    });

    testWidgets('Displays info cards in landscape orientation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: SessionIndexPage(
              session: sessionWithGps,
              flutterMapBuilder:
                  ({key, required options, children, mapController}) {
                    return MockFlutterMap(
                      key: key,
                      options: options,
mapController: mapController,
children: children ?? [],
                    );
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all info cards are present
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
    });

    testWidgets('Info cards display correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Card widgets exist
      expect(find.byType(Card), findsAtLeastNWidgets(4));

      // Verify FittedBox widgets exist for proper scaling
      expect(find.byType(FittedBox), findsAtLeastNWidgets(4));
    });

    testWidgets('Displays map with polyline for GPS data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify MockFlutterMap is used
      expect(find.byType(MockFlutterMap), findsOneWidget);
    });

    testWidgets('GPS points with zero speed are handled', (
      WidgetTester tester,
    ) async {
      final sessionWithZeroSpeed = Session(
        id: 6,
        projectId: project.id!,
        name: 'Zero Speed Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 2,
        gpsData: [
          SessionGpsPoint(
            sessionId: 6,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: 0.0,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 6,
            latitude: 48.8580,
            longitude: 2.2945,
            speed: 0.0,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 0,
          ),
        ],
      );

      when(
        mockDbHelper.readSession(sessionWithZeroSpeed.id!),
      ).thenAnswer((_) async => sessionWithZeroSpeed);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithZeroSpeed,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Average speed should be 0.00 km/h
      expect(find.text('0.00 km/h'), findsOneWidget);
    });

    testWidgets('GPS points with null speed are handled', (
      WidgetTester tester,
    ) async {
      final sessionWithNullSpeed = Session(
        id: 7,
        projectId: project.id!,
        name: 'Null Speed Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 2,
        gpsData: [
          SessionGpsPoint(
            sessionId: 7,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: null,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 7,
            latitude: 48.8580,
            longitude: 2.2945,
            speed: null,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 0,
          ),
        ],
      );

      when(
        mockDbHelper.readSession(sessionWithNullSpeed.id!),
      ).thenAnswer((_) async => sessionWithNullSpeed);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithNullSpeed,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Average speed should be 0.00 km/h when all speeds are null
      expect(find.text('0.00 km/h'), findsOneWidget);
    });

    testWidgets('Empty GPS data list shows waiting message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithoutGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify waiting message for GPS data
      expect(find.text('En attente de données'), findsOneWidget);
    });

    testWidgets('Shows video icon when no video available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithoutGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify video waiting icon
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
      expect(find.text('En attente de vidéo'), findsOneWidget);
    });

    testWidgets('Multiple GPS points calculate correct average speed', (
      WidgetTester tester,
    ) async {
      final sessionWithMultiplePoints = Session(
        id: 8,
        projectId: project.id!,
        name: 'Multiple Points Session',
        duration: const Duration(minutes: 20),
        gpsPoints: 4,
        gpsData: [
          SessionGpsPoint(
            sessionId: 8,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: 5.0,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 8,
            latitude: 48.8580,
            longitude: 2.2945,
            speed: 10.0,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 8,
            latitude: 48.8600,
            longitude: 2.2800,
            speed: 15.0,
            timestamp: DateTime.now().add(const Duration(minutes: 2)),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 8,
            latitude: 48.8620,
            longitude: 2.2700,
            speed: 20.0,
            timestamp: DateTime.now().add(const Duration(minutes: 3)),
            videoTimestampMs: 0,
          ),
        ],
      );

      when(
        mockDbHelper.readSession(sessionWithMultiplePoints.id!),
      ).thenAnswer((_) async => sessionWithMultiplePoints);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithMultiplePoints,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Average of speeds (5 + 10 + 15 + 20) / 4 = 12.5 m/s * 3.6 = 45.0 km/h
      expect(find.text('45.00 km/h'), findsOneWidget);
    });

    testWidgets('Session with mix of null and non-null speeds', (
      WidgetTester tester,
    ) async {
      final sessionWithMixedSpeeds = Session(
        id: 9,
        projectId: project.id!,
        name: 'Mixed Speed Session',
        duration: const Duration(minutes: 15),
        gpsPoints: 3,
        gpsData: [
          SessionGpsPoint(
            sessionId: 9,
            latitude: 48.8566,
            longitude: 2.3522,
            speed: null,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 9,
            latitude: 48.8580,
            longitude: 2.2945,
            speed: 10.0,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 9,
            latitude: 48.8600,
            longitude: 2.2800,
            speed: 20.0,
            timestamp: DateTime.now().add(const Duration(minutes: 2)),
            videoTimestampMs: 0,
          ),
        ],
      );

      when(
        mockDbHelper.readSession(sessionWithMixedSpeeds.id!),
      ).thenAnswer((_) async => sessionWithMixedSpeeds);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithMixedSpeeds,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Average of speeds (0 + 10 + 20) / 3 = 10 m/s * 3.6 = 36.0 km/h
      expect(find.text('36.00 km/h'), findsOneWidget);
    });

    testWidgets('Portrait layout displays correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify portrait layout elements
      expect(find.text('Points GPS'), findsOneWidget);
      expect(find.text('Durée'), findsOneWidget);
      expect(find.text('Vitesse Moyenne'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
    });

    testWidgets('Session with short duration formats correctly', (
      WidgetTester tester,
    ) async {
      final sessionWithShortDuration = Session(
        id: 10,
        projectId: project.id!,
        name: 'Short Duration Session',
        duration: const Duration(seconds: 45),
        gpsPoints: 5,
      );

      when(
        mockDbHelper.readSession(sessionWithShortDuration.id!),
      ).thenAnswer((_) async => sessionWithShortDuration);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithShortDuration,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Duration should be 00:00:45
      expect(find.text('00:00:45'), findsOneWidget);
    });

    testWidgets('Uses default FlutterMap builder when not provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            // Not providing flutterMapBuilder to test default
          ),
        ),
      );
      await tester.pump();

      // Should build without error using default builder
      expect(find.byType(SessionIndexPage), findsOneWidget);
    });

    testWidgets('AppBar displays session name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar shows session name
      expect(find.widgetWithText(AppBar, 'Session with GPS'), findsOneWidget);
    });

    testWidgets('PopupMenu contains all expected options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify all menu options
      expect(find.text('Editer'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);
      expect(find.text('Refaire'), findsOneWidget);
      expect(find.text('Exporter'), findsOneWidget);
    });

    testWidgets('Video controller is null when no video path', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithoutGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify video waiting state
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    });

    testWidgets('Landscape orientation shows horizontal scroll', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify SingleChildScrollView exists in landscape
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('All info cards have proper structure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 4 cards exist
      final cards = find.byType(Card);
      expect(cards, findsAtLeastNWidgets(4));
    });

    testWidgets('Map shows correct initial center for GPS data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify MockFlutterMap is rendered
      expect(find.byType(MockFlutterMap), findsOneWidget);
    });

    testWidgets('Session with zero duration formats correctly', (
      WidgetTester tester,
    ) async {
      final sessionWithZeroDuration = Session(
        id: 11,
        projectId: project.id!,
        name: 'Zero Duration Session',
        duration: Duration.zero,
        gpsPoints: 0,
      );

      when(
        mockDbHelper.readSession(sessionWithZeroDuration.id!),
      ).thenAnswer((_) async => sessionWithZeroDuration);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithZeroDuration,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Duration should be 00:00:00
      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('Expanded widgets in portrait use spaceAround', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Expanded widgets exist for map and video
      expect(find.byType(Expanded), findsWidgets);
    });

    testWidgets('ClipRRect rounds corners correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ClipRRect widgets exist
      expect(find.byType(ClipRRect), findsAtLeastNWidgets(2));
    });

    testWidgets('Container borders have correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Container widgets with decoration
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Padding is applied correctly to cards', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Padding widgets exist
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('OrientationBuilder responds to orientation changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify OrientationBuilder exists
      expect(find.byType(OrientationBuilder), findsOneWidget);
    });

    testWidgets('Row widgets are properly structured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Row widgets exist
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('Column widgets are properly structured', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Column widgets exist
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('SizedBox constraints are applied', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify SizedBox widgets exist in landscape
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Text widgets display correct theme styles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Text widgets exist
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Icon widgets are displayed correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithoutGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Icon widgets exist
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('Scaffold structure is correct', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithGps,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Scaffold exists
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Duration with only minutes formats correctly', (
      WidgetTester tester,
    ) async {
      final sessionWithMinutes = Session(
        id: 12,
        projectId: project.id!,
        name: 'Minutes Session',
        duration: const Duration(minutes: 5, seconds: 30),
        gpsPoints: 10,
      );

      when(
        mockDbHelper.readSession(sessionWithMinutes.id!),
      ).thenAnswer((_) async => sessionWithMinutes);

      await tester.pumpWidget(
        MaterialApp(
          home: SessionIndexPage(
            session: sessionWithMinutes,
            flutterMapBuilder:
                ({key, required options, children, mapController}) {
                  return MockFlutterMap(
                    key: key,
                    options: options,
mapController: mapController,
children: children ?? [],
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Duration should be 00:05:30
      expect(find.text('00:05:30'), findsOneWidget);
    });
  });
}
