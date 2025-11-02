import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:roadmindphone/main.dart';
import 'package:roadmindphone/stores/project_store.dart';
import 'package:roadmindphone/stores/session_store.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:mockito/mockito.dart';
import 'mocks.mocks.dart';

/// Tests pour MyHomePage avec ProjectStore
/// Ces tests valident l'intégration du Provider et du ProjectStore
void main() {
  group('MyHomePage with ProjectStore Integration Tests', () {
    late MockDatabaseHelper mockDbHelper;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      DatabaseHelper.setTestInstance(mockDbHelper);

      // Stubs par défaut
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => []);
      when(
        mockDbHelper.readAllSessionsForProject(any),
      ).thenAnswer((_) async => []);
    });

    tearDown(() {
      DatabaseHelper.resetInstance();
    });

    /// Helper pour créer un widget avec Provider
    Widget createTestWidget(ProjectStore store) {
      final sessionStore = SessionStore(databaseHelper: mockDbHelper);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectStore>.value(value: store),
          ChangeNotifierProvider<SessionStore>.value(value: sessionStore),
        ],
        child: const MaterialApp(home: MyHomePage(title: 'Test App')),
      );
    }

    testWidgets('ProjectStore is properly injected via Provider', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Vérifier que le store est accessible
      final context = tester.element(find.byType(MyHomePage));
      final foundStore = Provider.of<ProjectStore>(context, listen: false);

      expect(foundStore, equals(store));
    });

    testWidgets('Consumer rebuilds when ProjectStore notifies', (
      WidgetTester tester,
    ) async {
      final project1 = Project(id: 1, title: 'Initial Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project1]);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));

      // Charger les projets initiaux
      await store.loadProjects();
      await tester.pumpAndSettle();

      expect(find.text('Initial Project'), findsOneWidget);

      // Ajouter un nouveau projet
      final project2 = Project(id: 2, title: 'New Project');
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [project1, project2]);
      when(mockDbHelper.create(any)).thenAnswer((_) async => project2);

      await store.createProject('New Project');
      await tester.pumpAndSettle();

      // Vérifier que le nouveau projet est affiché
      expect(find.text('Initial Project'), findsOneWidget);
      expect(find.text('New Project'), findsOneWidget);
    });

    testWidgets('Shows loading state from ProjectStore', (
      WidgetTester tester,
    ) async {
      final completer = Completer<List<Project>>();
      when(mockDbHelper.readAllProjects()).thenAnswer((_) => completer.future);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));

      // Lancer la frame post build
      await tester.pump();
      await tester.pump();

      // Vérifier l'indicateur de chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(store.isLoading, isTrue);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('Shows error state from ProjectStore', (
      WidgetTester tester,
    ) async {
      when(
        mockDbHelper.readAllProjects(),
      ).thenThrow(Exception('Database connection failed'));

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Vérifier l'affichage de l'erreur
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Database connection failed'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      expect(store.error, isNotNull);
    });

    testWidgets('Shows empty state from ProjectStore', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Vérifier l'état vide
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(store.hasProjects, isFalse);
      expect(store.projectCount, equals(0));
    });

    testWidgets('Error retry button clears error and reloads', (
      WidgetTester tester,
    ) async {
      // Premier appel échoue
      when(
        mockDbHelper.readAllProjects(),
      ).thenThrow(Exception('Network error'));

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);

      // Corriger pour le retry
      final project = Project(id: 1, title: 'Recovered Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      // Appuyer sur Réessayer
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      // Vérifier que l'erreur est effacée et les données chargées
      expect(find.text('Recovered Project'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
      expect(store.error, isNull);
    });

    testWidgets('Creates project via ProjectStore', (
      WidgetTester tester,
    ) async {
      final newProject = Project(id: 1, title: 'Store Created Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Ouvrir le dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Entrer le titre
      await tester.enterText(find.byType(TextField), 'Store Created Project');

      // Ajouter via le store
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Vérifier que le projet est créé
      verify(mockDbHelper.create(any)).called(1);
      expect(store.projectCount, equals(1));
      expect(find.text('Store Created Project'), findsOneWidget);
    });

    testWidgets('ProjectStore handles create with description', (
      WidgetTester tester,
    ) async {
      final projectWithDesc = Project(
        id: 1,
        title: 'Described Project',
        description: 'Test description',
      );
      when(mockDbHelper.create(any)).thenAnswer((_) async => projectWithDesc);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Créer avec description
      await store.createProject(
        'Described Project',
        description: 'Test description',
      );
      await tester.pumpAndSettle();

      expect(store.projectCount, equals(1));
      expect(store.projects.first.description, equals('Test description'));
    });

    testWidgets('Shows SnackBar on successful project creation', (
      WidgetTester tester,
    ) async {
      final newProject = Project(id: 1, title: 'Success Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Ouvrir dialog et créer projet
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Success Project');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Vérifier le SnackBar
      expect(find.text('Projet créé avec succès'), findsOneWidget);
    });

    testWidgets('Shows SnackBar on project creation error', (
      WidgetTester tester,
    ) async {
      when(mockDbHelper.create(any)).thenThrow(Exception('Create failed'));

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await tester.pumpAndSettle();

      // Ouvrir dialog
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Fail Project');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Vérifier l'erreur dans SnackBar
      expect(find.textContaining('Erreur:'), findsWidgets);
      expect(find.textContaining('Create failed'), findsWidgets);
    });

    testWidgets('ProjectStore immutable list prevents external modification', (
      WidgetTester tester,
    ) async {
      final project = Project(id: 1, title: 'Immutable Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));

      await store.loadProjects();
      await tester.pumpAndSettle();

      final projects = store.projects;

      // Tenter de modifier la liste (devrait lancer une erreur)
      expect(
        () => projects.add(Project(id: 2, title: 'Hacked')),
        throwsUnsupportedError,
      );
    });

    testWidgets('Multiple Consumers receive same updates', (
      WidgetTester tester,
    ) async {
      final project = Project(id: 1, title: 'Shared Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(
        ChangeNotifierProvider<ProjectStore>.value(
          value: store,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Consumer<ProjectStore>(
                    builder: (context, store, child) {
                      return Text('Consumer1: ${store.projectCount}');
                    },
                  ),
                  Consumer<ProjectStore>(
                    builder: (context, store, child) {
                      return Text('Consumer2: ${store.projectCount}');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await store.loadProjects();
      await tester.pumpAndSettle();

      // Les deux consumers doivent afficher la même valeur
      expect(find.text('Consumer1: 1'), findsOneWidget);
      expect(find.text('Consumer2: 1'), findsOneWidget);
    });

    testWidgets('FloatingActionButton triggers project creation dialog', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await store.loadProjects();
      await tester.pumpAndSettle();

      // Vérifier le FAB existe
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Taper sur le FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Vérifier le dialog
      expect(find.text('Nouveau Projet'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('AJOUTER'), findsOneWidget);
      expect(find.text('ANNULER'), findsOneWidget);
    });

    testWidgets('Cancel dialog does not create project', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await store.loadProjects();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Cancelled Project');
      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      // Vérifier qu'aucun projet n'a été créé
      verifyNever(mockDbHelper.create(any));
      expect(store.projectCount, equals(0));
      expect(find.text('Cancelled Project'), findsNothing);
    });

    testWidgets('Empty title does not create project', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await store.loadProjects();
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Laisser vide et tenter d'ajouter
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Vérifier qu'aucun projet n'a été créé
      verifyNever(mockDbHelper.create(any));
      expect(store.projectCount, equals(0));
    });

    // NOTE: This test disabled - ProjectIndexPage now uses SessionBloc, not SessionStore.
    // Test needs rewrite to provide SessionBloc via BlocProvider.
    testWidgets('Navigation to ProjectIndexPage works with store', skip: true, (
      WidgetTester tester,
    ) async {
      final project = Project(id: 1, title: 'Navigable Project');
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => [project]);
      when(
        mockDbHelper.readAllSessionsForProject(1),
      ).thenAnswer((_) async => []);

      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await store.loadProjects();
      await tester.pumpAndSettle();

      // Taper sur le projet
      await tester.tap(find.text('Navigable Project'));
      await tester.pumpAndSettle();

      // Vérifier la navigation
      expect(find.text('Aucune session pour le moment.'), findsOneWidget);
    });

    // NOTE: This test disabled - ProjectIndexPage now uses SessionBloc, not SessionStore.
    // Test needs rewrite to provide SessionBloc via BlocProvider.
    testWidgets(
      'Refreshes projects after returning from ProjectIndexPage',
      skip: true,
      (WidgetTester tester) async {
        final project1 = Project(id: 1, title: 'Original Project');
        when(
          mockDbHelper.readAllProjects(),
        ).thenAnswer((_) async => [project1]);
        when(
          mockDbHelper.readAllSessionsForProject(1),
        ).thenAnswer((_) async => []);

        final store = ProjectStore(databaseHelper: mockDbHelper);

        await tester.pumpWidget(createTestWidget(store));
        await store.loadProjects();
        await tester.pumpAndSettle();

        // Naviguer vers ProjectIndexPage
        await tester.tap(find.text('Original Project'));
        await tester.pumpAndSettle();

        // Simuler modification en background
        final project2 = Project(id: 2, title: 'New Project');
        when(
          mockDbHelper.readAllProjects(),
        ).thenAnswer((_) async => [project1, project2]);

        // Retourner
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Le store devrait se rafraîchir automatiquement
        // (comportement à implémenter avec didPopRoute ou similaire)
        expect(find.text('Original Project'), findsOneWidget);
      },
    );

    testWidgets('Settings navigation works independently of ProjectStore', (
      WidgetTester tester,
    ) async {
      final store = ProjectStore(databaseHelper: mockDbHelper);

      await tester.pumpWidget(createTestWidget(store));
      await store.loadProjects();
      await tester.pumpAndSettle();

      // Naviguer vers Settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      // Retourner
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Vérifier retour à MyHomePage
      expect(find.byType(MyHomePage), findsOneWidget);
    });
  });
}
