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
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => []);
      when(mockDbHelper.readAllSessionsForProject(any))
          .thenAnswer((_) async => []);
    });

    tearDown(() {
      // Reset the DatabaseHelper instance after each test
      DatabaseHelper.resetInstance();
    });

    testWidgets('Displays no projects message when no projects exist', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('Can add a new project', (WidgetTester tester) async {
      final newProject = Project(id: 1, title: 'New Test Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => [newProject]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap the add project button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify the add project dialog is shown
      expect(find.text('Nouveau Projet'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Titre du projet'), findsOneWidget);

      // Enter project title
      await tester.enterText(find.widgetWithText(TextField, 'Titre du projet'), 'New Test Project');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Verify the new project is displayed
      expect(find.text('New Test Project'), findsOneWidget);
      expect(find.text('Sessions: 0 | Durée: 00:00:00'), findsOneWidget);
    });

    testWidgets('Displays existing projects', (WidgetTester tester) async {
      final project1 = Project(id: 1, title: 'Existing Project 1');
      final project2 = Project(id: 2, title: 'Existing Project 2');
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => [project1, project2]);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Existing Project 1'), findsOneWidget);
      expect(find.text('Existing Project 2'), findsOneWidget);
    });

    testWidgets('Navigates to ProjectIndexPage when a project is tapped', (WidgetTester tester) async {
      final project = Project(id: 1, title: 'Navigable Project');
      when(mockDbHelper.readAllProjects())
          .thenAnswer((_) async => [project]);
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => project);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Navigable Project'));
      await tester.pumpAndSettle();

      expect(find.text('Navigable Project'), findsOneWidget); // AppBar title of ProjectIndexPage
      expect(find.text('Aucune session pour le moment.'), findsOneWidget);
    });
  });
}
