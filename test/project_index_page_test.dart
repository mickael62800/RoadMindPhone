import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/main.dart';
import 'package:roadmindphone/project_index_page.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'mocks.mocks.dart';

import 'package:roadmindphone/session_gps_point.dart';

void main() {
  group('ProjectIndexPage', () {
    late MockDatabaseHelper mockDbHelper;
    late Project project;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      project = Project(id: 1, title: 'Test Project');

      when(mockDbHelper.readAllSessionsForProject(project.id!))
          .thenAnswer((_) async => []);
      when(mockDbHelper.delete(project.id!))
          .thenAnswer((_) async => 1);
      when(mockDbHelper.createSession(any))
          .thenAnswer((invocation) async => (invocation.positionalArguments[0] as Session).copy(id: 1));
      when(mockDbHelper.updateSession(any))
          .thenAnswer((_) async => 1);

      // Mock platform channel calls for Geolocator
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'isLocationServiceEnabled') {
            return true;
          }
          if (methodCall.method == 'checkPermission') {
            return LocationPermission.whileInUse.index; // Return index of LocationPermission enum
          }
          if (methodCall.method == 'requestPermission') {
            return LocationPermission.whileInUse.index;
          }
          if (methodCall.method == 'getCurrentPosition') {
            return {
              'latitude': 0.0,
              'longitude': 0.0,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'accuracy': 0.0,
              'altitude': 0.0,
              'heading': 0.0,
              'speed': 0.0,
              'speed_accuracy': 0.0,
              'is_mocked': false,
              'altitude_accuracy': 0.0,
              'heading_accuracy': 0.0,
            };
          }
          if (methodCall.method == 'getPositionStream') {
            // Return a stream with a single position
            return [
              {
                'latitude': 0.0,
                'longitude': 0.0,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'accuracy': 0.0,
                'altitude': 0.0,
                'heading': 0.0,
                'speed': 0.0,
                'speed_accuracy': 0.0,
                'is_mocked': false,
                'altitude_accuracy': 0.0,
                'heading_accuracy': 0.0,
              }
            ];
          }
          return null;
        },
      );

      // Mock platform channel calls for camera
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/camera'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'availableCameras') {
            return [];
          }
          if (methodCall.method == 'initialize') {
            return null;
          }
          if (methodCall.method == 'startVideoRecording') {
            return null;
          }
          if (methodCall.method == 'stopVideoRecording') {
            return {'path': '/mock/video/path.mp4'};
          }
          return null;
        },
      );

      // Mock platform channel calls for permission_handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermissions') {
            return {Permission.microphone.value: PermissionStatus.granted.index};
          }
          return null;
        },
      );
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
      // Clear mock method call handlers after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/geolocator'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/camera'), null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'), null);
    });

    testWidgets('shows project title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProjectIndexPage(project: project),
      ));

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('shows no sessions message', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ProjectIndexPage(project: project),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Aucune session pour le moment.'), findsOneWidget);
    });

    testWidgets('shows a list of sessions', (WidgetTester tester) async {
      final session = Session(
        id: 1,
        projectId: project.id!,
        name: 'Test Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 100,
      );
      when(mockDbHelper.readAllSessionsForProject(project.id!))
          .thenAnswer((_) async => [session]);

      await tester.pumpWidget(MaterialApp(
        home: ProjectIndexPage(project: project),
      ));

      await tester.pumpAndSettle();

      expect(find.text('Test Session'), findsOneWidget);
      expect(find.text('Durée: 00:10:00 | GPS Points: 100'), findsOneWidget);
    });

    testWidgets('adds a new session and navigates to SessionCompletionPage', (WidgetTester tester) async {
      final sessionWithGpsData = Session(
        id: 1,
        projectId: project.id!,
        name: 'New Session',
        duration: const Duration(minutes: 1),
        gpsPoints: 10,
        gpsData: [
          SessionGpsPoint(sessionId: 1, latitude: 48.8566, longitude: 2.3522, speed: 5.0, timestamp: DateTime.now(), videoTimestampMs: 0),
        ],
      );
      when(mockDbHelper.createSession(any))
          .thenAnswer((_) async => sessionWithGpsData);
      when(mockDbHelper.updateSession(any))
          .thenAnswer((_) async => 1);

      await tester.pumpWidget(MaterialApp(
        home: ProjectIndexPage(project: project),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ajouter Session'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'New Session');
      await tester.tap(find.text('AJOUTER'));
      await tester.pump(); // Pump to start the navigation
      await tester.pumpAndSettle(); // Pump until the navigation completes

      expect(find.text('New Session'), findsOneWidget); // Session should be listed
      expect(find.text('Go!'), findsOneWidget); // Should navigate to SessionCompletionPage and show the 'Go!' button
    });

    testWidgets('deletes a project', (WidgetTester tester) async {
      // Mock initial state: one project exists
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => [project]);

      await tester.pumpWidget(const MyApp()); // Start with MyHomePage
      await tester.pumpAndSettle();

      // Verify MyHomePage shows the project
      expect(find.text('Test Project'), findsOneWidget);

      // Tap on the project to navigate to ProjectIndexPage
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      // Verify we are on ProjectIndexPage
      expect(find.text('Test Project'), findsOneWidget); // AppBar title

      // Mock state after deletion: no projects exist
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => []);

      // Open the popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Tap on 'Supprimer'
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      expect(find.text('Supprimer le projet'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      // Verify navigation back to MyHomePage and project is gone
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget); // Back on MyHomePage, showing empty message
      expect(find.text('Test Project'), findsNothing); // Project should be deleted
    });
  });
}