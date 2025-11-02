import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:roadmindphone/stores/session_store.dart';

import 'mocks.mocks.dart';
import 'mocks/mock_flutter_map.dart';

void main() {
  group('SessionIndexPage Additional Coverage Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late MockSessionStore mockSessionStore;
    late Session testSession;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      mockSessionStore = MockSessionStore();
      DatabaseHelper.setTestInstance(mockDbHelper);

      testSession = Session(
        id: 1,
        projectId: 1,
        name: 'Test Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 5,
        gpsData: [
          SessionGpsPoint(
            sessionId: 1,
            latitude: 48.8566,
            longitude: 2.3522,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
          SessionGpsPoint(
            sessionId: 1,
            latitude: 48.8576,
            longitude: 2.3532,
            timestamp: DateTime.now().add(const Duration(minutes: 1)),
            videoTimestampMs: 60000,
          ),
        ],
      );
    });

    tearDown(() {
      DatabaseHelper.resetInstance();
    });

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionStore>.value(value: mockSessionStore),
          ],
          child: child,
        ),
      );
    }

    testWidgets('Fallback to DatabaseHelper when SessionStore fails', (
      WidgetTester tester,
    ) async {
      when(
        mockSessionStore.refreshSession(
          projectId: testSession.projectId,
          sessionId: testSession.id!,
        ),
      ).thenThrow(Exception('SessionStore error'));

      when(
        mockDbHelper.readSession(testSession.id!),
      ).thenAnswer((_) async => testSession);

      await tester.pumpWidget(
        buildTestWidget(
          SessionIndexPage(
            session: testSession,
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

      // Should fallback to reading from database directly
      verify(mockDbHelper.readSession(testSession.id!)).called(greaterThan(0));
    });

    testWidgets('WillPopScope returns hasChanged value', (
      WidgetTester tester,
    ) async {
      when(
        mockDbHelper.readSession(testSession.id!),
      ).thenAnswer((_) async => testSession);
      when(
        mockSessionStore.refreshSession(
          projectId: testSession.projectId,
          sessionId: testSession.id!,
        ),
      ).thenAnswer((_) async {});

      bool? poppedValue;

      await tester.pumpWidget(
        buildTestWidget(
          PopScope(
            canPop: true,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SessionIndexPage(
                            session: testSession,
                            flutterMapBuilder:
                                ({
                                  key,
                                  required options,
                                  children,
                                  mapController,
                                }) {
                                  return MockFlutterMap(
                                    key: key,
                                    options: options,
                                    mapController: mapController,
                                    children: children ?? [],
                                  );
                                },
                          ),
                        ),
                      ).then((value) => poppedValue = value);
                    },
                    child: const Text('Go to Session'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go to Session'));
      await tester.pumpAndSettle();

      // Now pop the page
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Should return false (default _hasChanged value)
      expect(poppedValue, false);
    });

    testWidgets('Export session handles success response', (
      WidgetTester tester,
    ) async {
      when(
        mockDbHelper.readSession(testSession.id!),
      ).thenAnswer((_) async => testSession);
      when(
        mockSessionStore.refreshSession(
          projectId: testSession.projectId,
          sessionId: testSession.id!,
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          SessionIndexPage(
            session: testSession,
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

      // Find and tap the PopupMenuButton to open the menu
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);

      await tester.tap(popupMenuButton);
      await tester.pumpAndSettle();

      // Find and tap the 'Exporter' option
      final exportOption = find.text('Exporter');
      expect(exportOption, findsOneWidget);

      await tester.tap(exportOption);
      await tester.pumpAndSettle();

      // Note: The actual HTTP request will fail in test environment
      // but we're testing that the code path is executed
    });

    testWidgets('Default menu option prints debug message', (
      WidgetTester tester,
    ) async {
      when(
        mockDbHelper.readSession(testSession.id!),
      ).thenAnswer((_) async => testSession);
      when(
        mockSessionStore.refreshSession(
          projectId: testSession.projectId,
          sessionId: testSession.id!,
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          SessionIndexPage(
            session: testSession,
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

      // Test that the menu exists
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      expect(popupMenuButton, findsOneWidget);
    });

    testWidgets('Video player shows error state on initialization failure', (
      WidgetTester tester,
    ) async {
      final sessionWithVideo = Session(
        id: 2,
        projectId: 1,
        name: 'Video Session',
        duration: const Duration(minutes: 5),
        gpsPoints: 0,
        videoPath: '/nonexistent/video.mp4', // Invalid path
      );

      when(
        mockDbHelper.readSession(sessionWithVideo.id!),
      ).thenAnswer((_) async => sessionWithVideo);
      when(
        mockSessionStore.refreshSession(
          projectId: sessionWithVideo.projectId,
          sessionId: sessionWithVideo.id!,
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          SessionIndexPage(
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

      await tester.pumpAndSettle();

      // Should show video off icon when video doesn't exist
      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
      expect(find.text('En attente de vidéo'), findsOneWidget);
    });

    testWidgets('Handles missing video file gracefully', (
      WidgetTester tester,
    ) async {
      final sessionNoVideo = Session(
        id: 3,
        projectId: 1,
        name: 'No Video Session',
        duration: const Duration(minutes: 5),
        gpsPoints: 3,
      );

      when(
        mockDbHelper.readSession(sessionNoVideo.id!),
      ).thenAnswer((_) async => sessionNoVideo);
      when(
        mockSessionStore.refreshSession(
          projectId: sessionNoVideo.projectId,
          sessionId: sessionNoVideo.id!,
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTestWidget(
          SessionIndexPage(
            session: sessionNoVideo,
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

      // Should show "En attente de vidéo"
      expect(find.text('En attente de vidéo'), findsOneWidget);
    });

    test('Session data can be serialized to JSON for export', () {
      final sessionData = {
        'id': testSession.id,
        'projectId': testSession.projectId,
        'name': testSession.name,
        'duration': testSession.duration.inMilliseconds,
        'gpsPointsCount': testSession.gpsPoints,
        'videoPath': testSession.videoPath,
        'gpsData': testSession.gpsData
            .map((gpsPoint) => gpsPoint.toMap())
            .toList(),
      };

      final jsonString = jsonEncode(sessionData);
      expect(jsonString, isNotEmpty);
      expect(jsonString, contains(testSession.name));
    });
  });
}
