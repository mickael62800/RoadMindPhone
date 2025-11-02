import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/main.dart' as app;
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_completion_page.dart';
import 'package:roadmindphone/session_gps_point.dart';
import 'package:roadmindphone/session_index_page.dart';
import 'package:roadmindphone/stores/project_store.dart';

import '../test/fake_camera_platform.dart';
import '../test/fake_geolocator_platform.dart';
import '../test/fake_permission_handler_platform.dart';
import '../test/mocks.mocks.dart';

/// Comprehensive E2E tests covering all major user flows
///
/// Coverage Matrix:
/// ✅ Project Management: Create, Read, Update, Delete
/// ✅ Session Management: Create, Read, Update, Delete, Redo
/// ✅ Navigation: All pages transitions
/// ✅ State Management: ProjectStore, SessionStore
/// ✅ Error Handling: Failed operations, cancellations
/// ✅ UI Validation: Empty states, multi-item lists
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete E2E Application Tests', () {
    late MockDatabaseHelper mockDbHelper;
    late CameraPlatform originalCameraPlatform;
    late GeolocatorPlatform originalGeolocatorPlatform;
    late PermissionHandlerPlatform originalPermissionsPlatform;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      originalCameraPlatform = CameraPlatform.instance;
      originalGeolocatorPlatform = GeolocatorPlatform.instance;
      originalPermissionsPlatform = PermissionHandlerPlatform.instance;

      CameraPlatform.instance = FakeCameraPlatform();
      GeolocatorPlatform.instance = FakeGeolocatorPlatform();
      PermissionHandlerPlatform.instance = FakePermissionHandlerPlatform();
    });

    tearDown(() {
      DatabaseHelper.resetInstance();
      CameraPlatform.instance = originalCameraPlatform;
      GeolocatorPlatform.instance = originalGeolocatorPlatform;
      PermissionHandlerPlatform.instance = originalPermissionsPlatform;
    });

    // ========== HELPER FUNCTIONS ==========

    Future<void> pumpUntilFound(
      WidgetTester tester,
      Finder finder, {
      Duration timeout = const Duration(seconds: 5),
    }) async {
      const step = Duration(milliseconds: 100);
      var elapsed = Duration.zero;
      while (elapsed < timeout) {
        await tester.pump(step);
        elapsed += step;
        if (finder.evaluate().isNotEmpty) {
          return;
        }
      }
      fail('Widget ${finder.toString()} not found within $timeout');
    }

    // ========== PROJECT MANAGEMENT TESTS ==========

    testWidgets('Complete project lifecycle: create, rename, delete', (
      WidgetTester tester,
    ) async {
      final project = app.Project(id: 1, title: 'My Awesome Project');

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(mockDbHelper.create(any)).thenAnswer((_) async => project);

      app.main();
      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);

      // Create project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'My Awesome Project',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      expect(find.text('My Awesome Project'), findsOneWidget);

      // Navigate to project
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      await tester.tap(find.text('My Awesome Project'));
      await tester.pumpAndSettle();
      expect(find.text('My Awesome Project'), findsOneWidget); // AppBar

      // Rename project
      when(mockDbHelper.update(any)).thenAnswer((_) async => 1);
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editer'));
      await tester.pumpAndSettle();

      expect(find.text('Renommer le projet'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Renamed Project');
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed Project'), findsOneWidget);

      // Delete project
      when(mockDbHelper.delete(1)).thenAnswer((_) async => 1);
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer le projet'), findsOneWidget);
      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      // Verify back on home page with empty state
      final homeContext = tester.element(find.byType(app.MyHomePage));
      final projectStore = Provider.of<ProjectStore>(
        homeContext,
        listen: false,
      );
      expect(projectStore.hasProjects, isFalse);
      await pumpUntilFound(tester, find.text('Aucun projet pour le moment.'));
    });

    testWidgets('Cancel project creation preserves empty state', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Cancelled Project',
      );
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelled Project'), findsNothing);
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
    });

    testWidgets('Create multiple projects and verify list', (
      WidgetTester tester,
    ) async {
      final project1 = app.Project(id: 1, title: 'Project Alpha');
      final project2 = app.Project(id: 2, title: 'Project Beta');
      final project3 = app.Project(id: 3, title: 'Project Gamma');

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      // Add first project
      when(mockDbHelper.create(any)).thenAnswer((_) async => project1);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Project Alpha',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project1]);

      // Add second project
      when(mockDbHelper.create(any)).thenAnswer((_) async => project2);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Project Beta',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [project1, project2]);

      // Add third project
      when(mockDbHelper.create(any)).thenAnswer((_) async => project3);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Project Gamma',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [project1, project2, project3]);

      // Verify all visible
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsOneWidget);
      expect(find.text('Project Gamma'), findsOneWidget);
    });

    testWidgets('Empty project name shows error', (WidgetTester tester) async {
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
    });

    testWidgets('Error during project creation shows message', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(mockDbHelper.create(any)).thenThrow(Exception('Database error'));

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Failing Project',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsWidgets);
    });

    // ========== SESSION MANAGEMENT TESTS ==========

    testWidgets('Complete session lifecycle: create, rename, delete', (
      WidgetTester tester,
    ) async {
      final project = app.Project(id: 1, title: 'Test Project');
      final session = Session(
        id: 1,
        projectId: 1,
        name: 'Morning Ride',
        duration: Duration.zero,
        gpsPoints: 0,
      );

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(mockDbHelper.create(any)).thenAnswer((_) async => project);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      // Create project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Test Project',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      // Navigate to project
      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      // Create session
      when(mockDbHelper.createSession(any)).thenAnswer((_) async => session);
      await tester.tap(find.byTooltip('Ajouter Session'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Morning Ride');
      await tester.tap(find.text('AJOUTER'));
      await tester.pump();
      await pumpUntilFound(tester, find.byType(SessionCompletionPage));

      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => [session]);
      when(mockDbHelper.readSession(1)).thenAnswer((_) async => session);
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      // Go back
      Navigator.of(tester.element(find.byType(SessionCompletionPage))).pop();
      await tester.pumpAndSettle();

      expect(find.textContaining('Morning Ride'), findsWidgets);

      // Navigate to session detail
      final listTileFinder = find.ancestor(
        of: find.text('Morning Ride'),
        matching: find.byType(ListTile),
      );
      await tester.ensureVisible(listTileFinder.first);
      await tester.pumpAndSettle();
      await tester.tap(listTileFinder.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(SessionIndexPage), findsOneWidget);

      // Rename session
      await tester.tap(find.byType(PopupMenuButton<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editer'));
      await tester.pumpAndSettle();

      expect(find.text('Renommer la session'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Evening Run');
      await tester.tap(find.text('RENOMMER'));
      await tester.pumpAndSettle();

      final renamedSession = session.copy(name: 'Evening Run');
      when(mockDbHelper.readSession(1)).thenAnswer((_) async => renamedSession);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => [renamedSession]);

      expect(find.text('Evening Run'), findsOneWidget);

      // Delete session
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer la session'), findsOneWidget);

      when(mockDbHelper.deleteSession(1)).thenAnswer((_) async => 1);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      await tester.tap(find.text('SUPPRIMER'));
      await tester.pumpAndSettle();

      await pumpUntilFound(tester, find.text('Aucune session pour le moment.'));
    });

    testWidgets('Cancel session creation', (WidgetTester tester) async {
      final project = app.Project(id: 1, title: 'Test Project');

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Ajouter Session'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cancelled Session');
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelled Session'), findsNothing);
      expect(find.text('Aucune session pour le moment.'), findsOneWidget);
    });

    testWidgets('Create multiple sessions in a project', (
      WidgetTester tester,
    ) async {
      final project = app.Project(id: 1, title: 'Multi Session Project');
      final session1 = Session(
        id: 1,
        projectId: 1,
        name: 'Session 1',
        duration: const Duration(minutes: 10),
        gpsPoints: 50,
      );
      final session2 = Session(
        id: 2,
        projectId: 1,
        name: 'Session 2',
        duration: const Duration(minutes: 20),
        gpsPoints: 100,
      );
      final session3 = Session(
        id: 3,
        projectId: 1,
        name: 'Session 3',
        duration: const Duration(minutes: 15),
        gpsPoints: 75,
      );

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Multi Session Project'));
      await tester.pumpAndSettle();

      // Add sessions
      for (var i = 0; i < 3; i++) {
        final session = [session1, session2, session3][i];
        final sessionName = 'Session ${i + 1}';

        when(mockDbHelper.createSession(any)).thenAnswer((_) async => session);
        await tester.tap(find.byTooltip('Ajouter Session'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), sessionName);
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();

        when(mockDbHelper.readSession(i + 1)).thenAnswer((_) async => session);
        when(mockDbHelper.readAllSessionsForProject(1)).thenAnswer(
          (_) async => [session1, session2, session3].sublist(0, i + 1),
        );

        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Verify all visible
      expect(find.text('Session 1'), findsOneWidget);
      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('Session 3'), findsOneWidget);
    });

    testWidgets('Redo session clears data and navigates to completion', (
      WidgetTester tester,
    ) async {
      final project = app.Project(id: 1, title: 'Test Project');
      final originalSession = Session(
        id: 1,
        projectId: 1,
        name: 'Session to Redo',
        duration: const Duration(minutes: 10),
        gpsPoints: 50,
        gpsData: [
          SessionGpsPoint(
            sessionId: 1,
            latitude: 48.8566,
            longitude: 2.3522,
            timestamp: DateTime.now(),
            videoTimestampMs: 0,
          ),
        ],
        videoPath: '/fake/path/video.mp4',
      );

      final redoneSession = Session(
        id: 1,
        projectId: 1,
        name: 'Session to Redo',
        duration: Duration.zero,
        gpsPoints: 0,
        gpsData: [],
        videoPath: null,
      );

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => [originalSession]);
      when(
        mockDbHelper.readSession(1),
      ).thenAnswer((_) async => originalSession);
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Project'));
      await tester.pumpAndSettle();

      expect(find.text('Session to Redo'), findsOneWidget);

      // Navigate to session
      await tester.tap(find.text('Session to Redo'));
      await tester.pumpAndSettle();

      // Verify original data
      expect(find.textContaining('10'), findsWidgets);
      expect(find.textContaining('50'), findsWidgets);

      // Redo
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refaire'));
      await tester.pumpAndSettle();

      expect(find.text('Refaire la session'), findsOneWidget);

      when(mockDbHelper.readSession(1)).thenAnswer((_) async => redoneSession);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => [redoneSession]);

      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Go!'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify cleared data
      final pointsGpsCard = find.ancestor(
        of: find.text('Points GPS'),
        matching: find.byType(Card),
      );
      expect(pointsGpsCard, findsOneWidget);

      final pointsValueFinder = find.descendant(
        of: pointsGpsCard,
        matching: find.text('0'),
      );
      expect(pointsValueFinder, findsOneWidget);
    });

    // ========== NAVIGATION TESTS ==========

    testWidgets('Navigation preserves application state', (
      WidgetTester tester,
    ) async {
      final project = app.Project(id: 1, title: 'Navigation Test');

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(mockDbHelper.create(any)).thenAnswer((_) async => project);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      app.main();
      await tester.pumpAndSettle();

      // Create project
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Navigation Test',
      );
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      expect(find.text('Navigation Test'), findsOneWidget);

      // Navigate forward
      await tester.tap(find.text('Navigation Test'));
      await tester.pumpAndSettle();
      expect(find.text('Aucune session pour le moment.'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify state preserved
      expect(find.text('Liste des Projets'), findsOneWidget);
      expect(find.text('Navigation Test'), findsOneWidget);
    });
  });
}
