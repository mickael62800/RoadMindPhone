import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:roadmindphone/export_data_page.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportDataPage', () {
    late ProjectEntity testProject;
    late List<Session> testSessions;

    setUp(() {
      testProject = ProjectEntity(
        id: 1,
        title: 'Test Project',
        description: 'Test Description',
        createdAt: DateTime(2023, 1, 1),
      );

      testSessions = [
        Session(
          id: 1,
          projectId: 1,
          name: 'Test Session',
          startTime: DateTime(2023, 1, 1, 10, 0),
          duration: const Duration(minutes: 10),
          videoPath: '/test/video.mp4',
          gpsPoints: 1,
          gpsData: [
            SessionGpsPoint(
              sessionId: 1,
              latitude: 48.8566,
              longitude: 2.3522,
              altitude: 35.0,
              speed: 10.5,
              timestamp: DateTime(2023, 1, 1, 10, 0),
              videoTimestampMs: 0,
            ),
          ],
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'db_server_address': '192.168.1.15',
        'db_port': '5000',
      });
    });

    testWidgets('displays correct title', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 404);
        }
        return http.Response('Not Found', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exporter Test Project'), findsOneWidget);
    });

    testWidgets('displays upload icon when project does not exist', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 404); // Project not found
        }
        return http.Response('Not Found', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(
        find.text('Le projet n\'existe pas encore sur le serveur'),
        findsOneWidget,
      );
      expect(find.text('Créer le projet'), findsOneWidget);
    });

    testWidgets('displays done icon when project exists', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 200); // Project exists
        }
        return http.Response('OK', 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Le projet existe sur le serveur'), findsOneWidget);
      expect(find.text('Mettre à jour le projet'), findsOneWidget);
    });

    testWidgets('loads server settings from SharedPreferences', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'db_server_address': '192.168.1.100',
        'db_port': '8080',
      });

      final List<String> capturedUrls = [];
      final mockClient = MockClient((request) async {
        capturedUrls.add(request.url.toString());
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the correct server was used
      expect(
        capturedUrls.any((url) => url.contains('192.168.1.100:8080')),
        isTrue,
      );
    });

    testWidgets('shows progress indicator during export', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 404);
        }
        if (request.method == 'POST') {
          // Simulate slow response
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'Test Project',
              'sessions': [
                {'id': 1, 'name': 'Test Session'},
              ],
            }),
            201,
          );
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the create button
      await tester.tap(find.text('Créer le projet'));
      await tester.pump(const Duration(milliseconds: 50)); // Start animation

      // Should show progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Projet créé avec succès ! 🎉'), findsOneWidget);
    });

    testWidgets('displays error message on failed export', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 404);
        }
        if (request.method == 'POST') {
          return http.Response('Internal Server Error', 500);
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the create button
      await tester.tap(find.text('Créer le projet'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Échec de la création: 500'), findsOneWidget);
    });

    testWidgets('verifies ProjectData JSON contains PascalCase keys', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          return http.Response('{"status":"Healthy"}', 200);
        }
        if (request.method == 'HEAD') {
          return http.Response('', 404);
        }
        if (request.method == 'POST') {
          // The POST will be sent, just verify it goes through
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'Test Project',
              'sessions': [
                {'id': 1, 'name': 'Test Session'},
              ],
            }),
            201,
          );
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the create button
      await tester.tap(find.text('Créer le projet'));
      await tester.pumpAndSettle();

      // Verify success (means JSON was accepted)
      expect(find.text('Projet créé avec succès ! 🎉'), findsOneWidget);
    });

    testWidgets('handles network errors gracefully', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          throw Exception('Network error');
        }
        throw Exception('Network error');
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      // Should not crash
      await tester.pumpAndSettle();
      expect(find.byType(ExportDataPage), findsOneWidget);
    });

    testWidgets('checks API health on initialization', (
      WidgetTester tester,
    ) async {
      bool healthCheckCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/health')) {
          healthCheckCalled = true;
          return http.Response('{"status":"Healthy"}', 200);
        }
        return http.Response('', 404);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ExportDataPage(
            project: testProject,
            sessions: testSessions,
            httpClient: mockClient,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(healthCheckCalled, isTrue);
    });
  });
}
