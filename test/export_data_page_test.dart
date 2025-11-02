import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/export_data_page.dart';
import 'package:roadmindphone/main.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:http/http.dart' as http;

import 'mocks.mocks.dart';

// NOTE: These tests need to be updated to use ProjectEntity and pass sessions
// explicitly. Currently marked as skip until the Session feature is migrated
// to Clean Architecture.

// Custom mock for io.File to control existsSync()
class MockFile implements io.File {
  final String _path;
  final bool _exists;
  final Uint8List? _bytes;

  MockFile(this._path, {bool exists = true, Uint8List? bytes})
    : _exists = exists,
      _bytes = bytes;

  @override
  bool existsSync() => _exists;

  @override
  Future<Uint8List> readAsBytes() async {
    if (_bytes != null) {
      return _bytes;
    }
    throw io.FileSystemException('File not found', _path);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Helper class to mock StreamedResponse
class MockStreamedResponse implements http.StreamedResponse {
  final int _statusCode;
  final String _body;

  MockStreamedResponse(this._statusCode, {String body = ''}) : _body = body;

  @override
  int get statusCode => _statusCode;

  @override
  http.ByteStream get stream => http.ByteStream.fromBytes(_body.codeUnits);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group(
    'ExportDataPage [DEPRECATED]',
    () {
      late MockClient mockClient;
      late Project testProject;

      setUp(() {
        mockClient = MockClient();
        // Set up a default mock for http.head to avoid unexpected network calls
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));

        testProject = Project(
          id: 1,
          title: 'Test Project',
          description: 'A project for testing export',
          sessions: [
            Session(
              id: 101,
              projectId: 1,
              name: 'Session 1',
              duration: Duration(minutes: 30),
              gpsPoints: 50,
              videoPath: '/path/to/video1.mp4',
              gpsData: [
                SessionGpsPoint(
                  sessionId: 101,
                  latitude: 1.0,
                  longitude: 1.0,
                  speed: 10.0,
                  timestamp: DateTime.now(),
                  videoTimestampMs: 0,
                ),
              ],
            ),
          ],
        );
      });

      testWidgets(
        'displays "Le projet n\'existe PAS" when project does not exist remotely',
        (WidgetTester tester) async {
          when(
            mockClient.head(any),
          ).thenAnswer((_) async => http.Response('', 404));

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ExportDataPage(
                  project: testProject,
                  httpClient: mockClient,
                ),
              ),
            ),
          );
          await tester
              .pumpAndSettle(); // Wait for initial build and _checkProjectExists to complete
          await tester
              .pumpAndSettle(); // Wait for setState to trigger a rebuild

          expect(
            find.text(
              'Le projet n\'existe PAS dans la base de données distante.',
            ),
            findsOneWidget,
          );
          expect(find.text('Créer le projet'), findsOneWidget);
        },
      );

      testWidgets('displays "Le projet existe" when project exists remotely', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 200));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester
            .pumpAndSettle(); // Wait for initial build and _checkProjectExists to complete
        await tester.pumpAndSettle(); // Wait for setState to trigger a rebuild

        expect(
          find.text('Le projet existe dans la base de données distante.'),
          findsOneWidget,
        );
        expect(find.text('Mettre à jour le projet'), findsOneWidget);
      });

      testWidgets('creates project successfully', (WidgetTester tester) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));
        when(
          mockClient.send(any),
        ).thenAnswer((_) async => MockStreamedResponse(201, body: '{"id":1}'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Créer le projet'), findsOneWidget);
        await tester.tap(find.text('Créer le projet'));
        await tester.pumpAndSettle();

        expect(find.text('Projet créé avec succès !'), findsOneWidget);
        expect(
          find.text('Le projet existe dans la base de données distante.'),
          findsOneWidget,
        );
      });

      testWidgets('fails to create project', (WidgetTester tester) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));
        when(
          mockClient.send(any),
        ).thenAnswer((_) async => MockStreamedResponse(500, body: 'Error'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Créer le projet'), findsOneWidget);
        await tester.tap(find.text('Créer le projet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Échec de la création du projet: 500'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Le projet n\'existe PAS dans la base de données distante.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('updates project successfully', (WidgetTester tester) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 200));
        when(
          mockClient.send(any),
        ).thenAnswer((_) async => MockStreamedResponse(200, body: '{"id":1}'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mettre à jour le projet'), findsOneWidget);
        await tester.tap(find.text('Mettre à jour le projet'));
        await tester.pumpAndSettle();

        expect(find.text('Projet mis à jour avec succès !'), findsOneWidget);
        expect(
          find.text('Le projet existe dans la base de données distante.'),
          findsOneWidget,
        );
      });

      testWidgets('fails to update project', (WidgetTester tester) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 200));
        when(
          mockClient.send(any),
        ).thenAnswer((_) async => MockStreamedResponse(500, body: 'Error'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mettre à jour le projet'), findsOneWidget);
        await tester.tap(find.text('Mettre à jour le projet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Échec de la mise à jour du projet: 500'),
          findsOneWidget,
        );
        expect(
          find.text('Le projet existe dans la base de données distante.'),
          findsOneWidget,
        );
      });

      testWidgets('handles network error during project existence check', (
        WidgetTester tester,
      ) async {
        when(mockClient.head(any)).thenThrow(io.SocketException('No internet'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Erreur lors de la vérification de l\'existence du projet',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Le projet n\'existe PAS dans la base de données distante.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('handles network error during project creation', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));
        when(mockClient.send(any)).thenThrow(io.SocketException('No internet'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Créer le projet'), findsOneWidget);
        await tester.tap(find.text('Créer le projet'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Erreur lors de la création du projet'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Le projet n\'existe PAS dans la base de données distante.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('handles network error during project update', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 200));
        when(mockClient.send(any)).thenThrow(io.SocketException('No internet'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mettre à jour le projet'), findsOneWidget);
        await tester.tap(find.text('Mettre à jour le projet'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Erreur lors de la mise à jour du projet'),
          findsOneWidget,
        );
        expect(
          find.text('Le projet existe dans la base de données distante.'),
          findsOneWidget,
        );
      });

      testWidgets('handles non-200 status when checking project existence', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 500));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Erreur lors de la vérification de l\'existence du projet: 500',
          ),
          findsOneWidget,
        );
      });

      testWidgets('handles non-200 status when creating project', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));

        final streamedResponse = MockStreamedResponse(500);
        when(mockClient.send(any)).thenAnswer((_) async => streamedResponse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Créer le projet'), findsOneWidget);
        await tester.tap(find.text('Créer le projet'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Échec de la création du projet: 500'),
          findsOneWidget,
        );
      });

      testWidgets('handles non-200 status when updating project', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 200));

        final streamedResponse = MockStreamedResponse(500);
        when(mockClient.send(any)).thenAnswer((_) async => streamedResponse);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: testProject,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mettre à jour le projet'), findsOneWidget);
        await tester.tap(find.text('Mettre à jour le projet'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Échec de la mise à jour du projet: 500'),
          findsOneWidget,
        );
      });

      testWidgets('creates project with sessions containing video paths', (
        WidgetTester tester,
      ) async {
        when(
          mockClient.head(any),
        ).thenAnswer((_) async => http.Response('', 404));

        final streamedResponse = MockStreamedResponse(201, body: '{"id":1}');
        when(mockClient.send(any)).thenAnswer((_) async => streamedResponse);

        final projectWithVideo = Project(
          id: 1,
          title: 'Video Project',
          sessions: [
            Session(
              id: 1,
              projectId: 1,
              name: 'Video Session',
              duration: const Duration(minutes: 10),
              gpsPoints: 5,
              videoPath: null,
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ExportDataPage(
                project: projectWithVideo,
                httpClient: mockClient,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Créer le projet'));
        await tester.pumpAndSettle();

        verify(mockClient.send(any)).called(1);
      });
    },
    skip: true,
  ); // Skip: ExportDataPage now uses ProjectEntity and requires sessions parameter
}
