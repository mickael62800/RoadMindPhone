import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';
import 'package:roadmindphone/features/project/presentation/pages/pages.dart';

import 'project_list_page_test.mocks.dart';

@GenerateMocks([ProjectBloc])
void main() {
  late MockProjectBloc mockProjectBloc;

  setUp(() {
    mockProjectBloc = MockProjectBloc();
    // Set up default state stream
    when(mockProjectBloc.state).thenReturn(const ProjectInitial());
    when(
      mockProjectBloc.stream,
    ).thenAnswer((_) => Stream<ProjectState>.empty());
  });

  tearDown(() {
    mockProjectBloc.close();
  });

  Widget makeTestableWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<ProjectBloc>.value(
        value: mockProjectBloc,
        child: child,
      ),
    );
  }

  group('ProjectListPage', () {
    testWidgets(
      'should display loading indicator when state is ProjectsLoading',
      (tester) async {
        // Arrange
        when(mockProjectBloc.state).thenReturn(const ProjectsLoading());
        when(
          mockProjectBloc.stream,
        ).thenAnswer((_) => Stream.value(const ProjectsLoading()));

        // Act
        await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
        await tester.pump();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('should display empty message when state is ProjectsEmpty', (
      tester,
    ) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectsEmpty());
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream.value(const ProjectsEmpty()));

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Assert
      expect(find.text('Aucun projet pour le moment.'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('Créer un projet'), findsOneWidget);
    });

    testWidgets('should display error message when state is ProjectError', (
      tester,
    ) async {
      // Arrange
      const errorMessage = 'Database error';
      when(
        mockProjectBloc.state,
      ).thenReturn(const ProjectError(message: errorMessage));
      when(mockProjectBloc.stream).thenAnswer(
        (_) => Stream.value(const ProjectError(message: errorMessage)),
      );

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Assert
      expect(find.text('Erreur: $errorMessage'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets(
      'should display list of projects when state is ProjectsLoaded',
      (tester) async {
        // Arrange
        final projects = [
          ProjectEntity(
            id: 1,
            title: 'Project 1',
            createdAt: DateTime(2024, 1, 1),
            sessionCount: 2,
            duration: const Duration(hours: 1),
          ),
          ProjectEntity(
            id: 2,
            title: 'Project 2',
            createdAt: DateTime(2024, 1, 2),
            sessionCount: 3,
            duration: const Duration(hours: 2),
          ),
        ];
        when(
          mockProjectBloc.state,
        ).thenReturn(ProjectsLoaded(projects: projects));
        when(
          mockProjectBloc.stream,
        ).thenAnswer((_) => Stream.value(ProjectsLoaded(projects: projects)));

        // Act
        await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
        await tester.pump();

        // Assert
        expect(find.text('Project 1'), findsOneWidget);
        expect(find.text('Project 2'), findsOneWidget);
        expect(find.text('Sessions: 2 | Durée: 01:00:00'), findsOneWidget);
        expect(find.text('Sessions: 3 | Durée: 02:00:00'), findsOneWidget);
      },
    );

    testWidgets('should add LoadProjectsEvent on init', (tester) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectInitial());
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream<ProjectState>.empty());

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Assert
      verify(mockProjectBloc.add(const LoadProjectsEvent())).called(1);
    });

    testWidgets('should add CreateProjectEvent when add button is tapped', (
      tester,
    ) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectsEmpty());
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream.value(const ProjectsEmpty()));

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter project title
      await tester.enterText(find.byType(TextField), 'New Project');
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        mockProjectBloc.add(const CreateProjectEvent(title: 'New Project')),
      ).called(1);
    });

    testWidgets('should add RefreshProjectsEvent when retry button is tapped', (
      tester,
    ) async {
      // Arrange
      when(
        mockProjectBloc.state,
      ).thenReturn(const ProjectError(message: 'Error'));
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream.value(const ProjectError(message: 'Error')));

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Tap retry button
      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      // Assert
      verify(
        mockProjectBloc.add(const LoadProjectsEvent()),
      ).called(2); // 1 from init + 1 from retry
    });

    testWidgets('should show snackbar when ProjectOperationSuccess', (
      tester,
    ) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectInitial());
      when(mockProjectBloc.stream).thenAnswer(
        (_) => Stream.value(
          const ProjectOperationSuccess(message: 'Project created'),
        ),
      );

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();
      await tester.pump(); // Process the stream event

      // Assert
      expect(find.text('Project created'), findsOneWidget);
    });

    testWidgets('should show error snackbar when ProjectError', (tester) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectInitial());
      when(mockProjectBloc.stream).thenAnswer(
        (_) => Stream.value(const ProjectError(message: 'Error occurred')),
      );

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();
      await tester.pump(); // Process the stream event

      // Assert
      expect(find.text('Error occurred'), findsOneWidget);
    });

    testWidgets('should display app bar with title and settings icon', (
      tester,
    ) async {
      // Arrange
      when(mockProjectBloc.state).thenReturn(const ProjectInitial());
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream<ProjectState>.empty());

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Assert
      expect(find.text('Liste des Projets'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should format duration correctly', (tester) async {
      // Arrange
      final projects = [
        ProjectEntity(
          id: 1,
          title: 'Project 1',
          createdAt: DateTime(2024, 1, 1),
          sessionCount: 0,
          duration: const Duration(hours: 2, minutes: 30, seconds: 45),
        ),
      ];
      when(
        mockProjectBloc.state,
      ).thenReturn(ProjectsLoaded(projects: projects));
      when(
        mockProjectBloc.stream,
      ).thenAnswer((_) => Stream.value(ProjectsLoaded(projects: projects)));

      // Act
      await tester.pumpWidget(makeTestableWidget(const ProjectListPage()));
      await tester.pump();

      // Assert
      expect(find.text('Sessions: 0 | Durée: 02:30:45'), findsOneWidget);
    });
  });
}
