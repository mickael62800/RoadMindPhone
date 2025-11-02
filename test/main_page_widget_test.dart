import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/main.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/stores/project_store.dart';
import 'mocks.mocks.dart';

void main() {
  group('MyHomePage Widget Tests with ProjectStore', () {
    late MockProjectStore mockStore;

    setUp(() {
      mockStore = MockProjectStore();
      when(mockStore.loadProjects()).thenAnswer((_) async => {});
      when(mockStore.projects).thenReturn([]);
      when(mockStore.isLoading).thenReturn(false);
      when(mockStore.error).thenReturn(null);
      when(mockStore.hasProjects).thenReturn(false);
      when(mockStore.clearError()).thenAnswer((_) async => {});
    });

    Future<void> pumpMyApp(WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProjectStore>.value(
          value: mockStore,
          child: const MyApp(),
        ),
      );
      await tester.pump();
    }

    testWidgets('Displays loading indicator when loading',
        (WidgetTester tester) async {
      when(mockStore.isLoading).thenReturn(true);
      await pumpMyApp(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays no projects message when no projects exist',
        (WidgetTester tester) async {
      await pumpMyApp(tester);
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('Can add a new project', (WidgetTester tester) async {
      final newProject = Project(id: 1, title: 'New Test Project');
      when(mockStore.createProject(any))
          .thenAnswer((_) async => newProject);
      when(mockStore.projects).thenReturn([newProject]);
      when(mockStore.hasProjects).thenReturn(true);

      await pumpMyApp(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau Projet'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'New Test Project');
      await tester.tap(find.widgetWithText(TextButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      verify(mockStore.createProject('New Test Project')).called(1);
    });

    testWidgets('Displays existing projects', (WidgetTester tester) async {
      final projects = [
        Project(id: 1, title: 'Existing Project 1'),
        Project(id: 2, title: 'Existing Project 2'),
      ];
      when(mockStore.projects).thenReturn(projects);
      when(mockStore.hasProjects).thenReturn(true);

      await pumpMyApp(tester);

      expect(find.text('Existing Project 1'), findsOneWidget);
      expect(find.text('Existing Project 2'), findsOneWidget);
    });

    testWidgets('Displays error message when an error occurs',
        (WidgetTester tester) async {
      when(mockStore.error).thenReturn('Failed to load');
      await pumpMyApp(tester);
      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Retry button calls loadProjects', (WidgetTester tester) async {
      when(mockStore.error).thenReturn('Failed to load');
      await pumpMyApp(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Réessayer'));
      await tester.pumpAndSettle();

      verifyInOrder([
        mockStore.clearError(),
        mockStore.loadProjects(),
      ]);
    });
  });
}
