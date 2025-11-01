import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roadmindphone/main.dart' as app;
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/session.dart';
import 'package:mockito/mockito.dart';
import '../test/mocks.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end App Test', () {
    late MockDatabaseHelper mockDbHelper;
    late app.Project testProject;
    late Session testSession;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      testProject = app.Project(id: 1, title: 'My Awesome Project');
      testSession = Session(
        id: 1,
        projectId: testProject.id!,
        name: 'Morning Ride',
        duration: Duration.zero,
        gpsPoints: 0,
      );

      // Stubbing for initial state (no projects)
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      // Stubbing for adding a project
      when(mockDbHelper.create(any)).thenAnswer((_) async => testProject);

      // Stubbing for ProjectIndexPage navigation and session display
      when(
        mockDbHelper.readProject(testProject.id!),
      ).thenAnswer((_) async => testProject);
      when(
        mockDbHelper.readAllSessionsForProject(testProject.id!),
      ).thenAnswer((_) async => []);

      // Stubbing for adding a session
      when(
        mockDbHelper.createSession(any),
      ).thenAnswer((_) async => testSession);

      // Stubbing for updating a session (e.g., after recording)
      when(mockDbHelper.updateSession(any)).thenAnswer((_) async => 1);

      // Stubbing for renaming a session
      when(
        mockDbHelper.updateSession(
          argThat(isA<Session>().having((s) => s.name, 'name', 'Evening Run')),
        ),
      ).thenAnswer((_) async => 1);

      // Stubbing for deleting a session
      when(
        mockDbHelper.deleteSession(testSession.id!),
      ).thenAnswer((_) async => 1);

      // Stubbing for deleting a project
      when(mockDbHelper.delete(testProject.id!)).thenAnswer((_) async => 1);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets(
      'Full app flow: add project, add session, rename session, delete session, delete project',
      (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();

        // 1. Verify initial state (no projects)
        expect(find.text('Aucun projet pour le moment.'), findsOneWidget);

        // 2. Add a new project
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Titre du projet'),
          'My Awesome Project',
        );
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();
        expect(find.text('My Awesome Project'), findsOneWidget);

        // Update stub for readAllProjects after adding a project
        when(
          mockDbHelper.readAllProjects(),
        ).thenAnswer((_) async => [testProject]);

        // 3. Navigate to ProjectIndexPage
        await tester.tap(find.text('My Awesome Project'));
        await tester.pumpAndSettle();
        expect(find.text('My Awesome Project'), findsOneWidget); // AppBar title
        expect(find.text('Aucune session pour le moment.'), findsOneWidget);

        // 4. Add a new session
        await tester.tap(find.byTooltip('Ajouter Session'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Morning Ride');
        await tester.tap(find.text('AJOUTER'));
        await tester.pump(); // Pump to start navigation
        await tester.pumpAndSettle(); // Pump until navigation completes
        expect(
          find.text('Morning Ride'),
          findsOneWidget,
        ); // Session name in AppBar of SessionCompletionPage
        expect(
          find.text('Go!'),
          findsOneWidget,
        ); // Button on SessionCompletionPage

        // Simulate stopping the session (this will pop back to ProjectIndexPage)
        await tester.tap(find.text('Go!')); // Tap to start recording
        await tester.pumpAndSettle(
          const Duration(seconds: 2),
        ); // Simulate some recording time
        await tester.tap(find.text('Stop')); // Tap to stop recording
        await tester.pumpAndSettle();

        // Update stub for readAllSessionsForProject after adding a session
        when(
          mockDbHelper.readAllSessionsForProject(testProject.id!),
        ).thenAnswer(
          (_) async => [
            testSession.copy(
              duration: const Duration(seconds: 2),
              gpsPoints: 2,
            ),
          ],
        );

        // Verify we are back on ProjectIndexPage and session is listed
        expect(find.text('My Awesome Project'), findsOneWidget); // AppBar title
        expect(find.text('Morning Ride'), findsOneWidget);

        // 5. Navigate to SessionIndexPage
        await tester.tap(find.text('Morning Ride'));
        await tester.pumpAndSettle();
        expect(find.text('Morning Ride'), findsOneWidget); // AppBar title
        expect(find.textContaining('Durée:'), findsOneWidget);

        // 6. Rename the session
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Editer'));
        await tester.pumpAndSettle();
        expect(find.text('Renommer la session'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Evening Run');
        await tester.tap(find.text('RENOMMER'));
        await tester.pumpAndSettle();
        expect(find.text('Evening Run'), findsOneWidget);
        expect(find.text('Morning Ride'), findsNothing);

        // Update stub for readAllSessionsForProject after renaming a session
        when(
          mockDbHelper.readAllSessionsForProject(testProject.id!),
        ).thenAnswer(
          (_) async => [
            testSession.copy(
              name: 'Evening Run',
              duration: const Duration(seconds: 2),
              gpsPoints: 2,
            ),
          ],
        );

        // 7. Delete the session
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();
        expect(find.text('Supprimer la session'), findsOneWidget);
        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();

        // Update stub for readAllSessionsForProject after deleting a session
        when(
          mockDbHelper.readAllSessionsForProject(testProject.id!),
        ).thenAnswer((_) async => []);

        // Verify we are back on ProjectIndexPage and session is gone
        expect(find.text('My Awesome Project'), findsOneWidget); // AppBar title
        expect(find.text('Evening Run'), findsNothing);
        expect(find.text('Aucune session pour le moment.'), findsOneWidget);

        // 8. Delete the project
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer'));
        await tester.pumpAndSettle();
        expect(find.text('Supprimer le projet'), findsOneWidget);
        await tester.tap(find.text('SUPPRIMER'));
        await tester.pumpAndSettle();

        // Update stub for readAllProjects after deleting a project
        when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

        // Verify we are back on MyHomePage and project is gone
        expect(find.text('Liste des Projets'), findsOneWidget);
        expect(find.text('My Awesome Project'), findsNothing);
        expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      },
    );
  });
}
