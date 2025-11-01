import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/main.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

void main() {
  group('MyHomePage Widget Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      // Default stub for readAllProjects to return an empty list
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(
        mockDbHelper.readAllSessionsForProject(any),
      ).thenAnswer((_) async => []);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets('Displays no projects message when no projects exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('Can add a new project', (WidgetTester tester) async {
      final newProject = Project(id: 1, title: 'New Test Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [newProject]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap the add project button
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the add project dialog is shown
      expect(find.text('Nouveau Projet'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Titre du projet'), findsOneWidget);

      // Enter project title
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'New Test Project',
      );
      await tester.tap(find.text('AJOUTER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify the new project is displayed
      expect(find.text('New Test Project'), findsOneWidget);
      expect(find.text('Sessions: 0 | Durée: 00:00:00'), findsOneWidget);
    });

    testWidgets('Displays existing projects', (WidgetTester tester) async {
      final project1 = Project(id: 1, title: 'Existing Project 1');
      final project2 = Project(id: 2, title: 'Existing Project 2');
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [project1, project2]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Existing Project 1'), findsOneWidget);
      expect(find.text('Existing Project 2'), findsOneWidget);
    });

    testWidgets('Navigates to ProjectIndexPage when a project is tapped', (
      WidgetTester tester,
    ) async {
      final project = Project(id: 1, title: 'Navigable Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Navigable Project'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Navigable Project'),
        findsOneWidget,
      ); // AppBar title of ProjectIndexPage
      expect(find.text('Aucune session pour le moment.'), findsOneWidget);
    });

    testWidgets('Cancels adding a new project', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap the add project button
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Nouveau Projet'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('ANNULER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Nouveau Projet'), findsNothing);
    });

    testWidgets('Does not add project with empty title', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap the add project button
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Try to add with empty title
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        '',
      );
      await tester.tap(find.text('AJOUTER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Dialog should still be there (using byType instead)
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Titre du projet'), findsOneWidget);
    });

    testWidgets('Adds project by pressing Enter', (WidgetTester tester) async {
      final newProject = Project(id: 1, title: 'Enter Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [newProject]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap the add project button
      await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Enter title and press Enter
      await tester.enterText(
        find.widgetWithText(TextField, 'Titre du projet'),
        'Enter Project',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify project was added - use findsNWidgets to allow for EditableText
      expect(find.text('Enter Project'), findsAtLeastNWidgets(1));
    });

    testWidgets('Displays project with session count and duration', (
      WidgetTester tester,
    ) async {
      final project = Project(
        id: 1,
        title: 'Project With Stats',
        sessionCount: 3,
        duration: const Duration(hours: 1, minutes: 30),
      );
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Project With Stats'), findsOneWidget);
      expect(find.text('Sessions: 3 | Durée: 01:30:00'), findsOneWidget);
    });

    testWidgets('Shows FloatingActionButton', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('AppBar has correct title and actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('RoadMindPhone'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Navigates to SettingsPage when settings icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap settings icon
      await tester.tap(find.byIcon(Icons.settings), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify SettingsPage is displayed (checking for its title)
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('ListView displays multiple projects', (
      WidgetTester tester,
    ) async {
      final projects = List.generate(
        5,
        (index) => Project(id: index, title: 'Project $index'),
      );
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => projects);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // It's a GridView, not ListView
      expect(find.byType(GridView), findsOneWidget);
      for (var project in projects) {
        expect(find.text(project.title), findsOneWidget);
      }
    });

    testWidgets('Card widgets are displayed for projects', (
      WidgetTester tester,
    ) async {
      final project = Project(id: 1, title: 'Card Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('Empty state icon is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('shows error state when database fails', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.readAllProjects()).thenThrow(Exception('DB Error'));

      await tester.pumpWidget(const MyApp());
      await tester.pump(); // Don't settle, just pump once
      await tester.pump(); // Pump again to let FutureBuilder show error

      // Expect error message is shown
      expect(find.text('Error: Exception: DB Error'), findsOneWidget);
    });
  });
}
