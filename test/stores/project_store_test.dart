import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/main.dart';
import 'package:roadmindphone/stores/project_store.dart';

import '../mocks.mocks.dart';

void main() {
  group('ProjectStore', () {
    late MockDatabaseHelper mockDbHelper;
    late ProjectStore projectStore;

    setUp(() {
      mockDbHelper = MockDatabaseHelper();
      projectStore = ProjectStore(databaseHelper: mockDbHelper);
    });

    test('initial state is empty', () {
      expect(projectStore.projects, isEmpty);
      expect(projectStore.isLoading, false);
      expect(projectStore.error, isNull);
      expect(projectStore.hasProjects, false);
      expect(projectStore.projectCount, 0);
    });

    test('loadProjects loads projects successfully', () async {
      final projects = [
        Project(id: 1, title: 'Project 1'),
        Project(id: 2, title: 'Project 2'),
      ];
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => projects);

      await projectStore.loadProjects();

      expect(projectStore.projects, equals(projects));
      expect(projectStore.isLoading, false);
      expect(projectStore.error, isNull);
      expect(projectStore.hasProjects, true);
      expect(projectStore.projectCount, 2);
    });

    test('loadProjects sets loading state', () async {
      when(mockDbHelper.readAllProjects()).thenAnswer(
        (_) async =>
            Future.delayed(const Duration(milliseconds: 100), () => []),
      );

      final loadFuture = projectStore.loadProjects();

      // Check loading state is set
      expect(projectStore.isLoading, true);

      await loadFuture;

      expect(projectStore.isLoading, false);
    });

    test('loadProjects handles errors', () async {
      when(
        mockDbHelper.readAllProjects(),
      ).thenThrow(Exception('Database error'));

      expect(() => projectStore.loadProjects(), throwsA(isA<Exception>()));

      expect(projectStore.error, contains('Erreur lors du chargement'));
      expect(projectStore.isLoading, false);
    });

    test('createProject creates and adds project', () async {
      final newProject = Project(id: 1, title: 'New Project');
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);

      final result = await projectStore.createProject('New Project');

      expect(result, equals(newProject));
      expect(projectStore.projects, contains(newProject));
      expect(projectStore.projectCount, 1);
      verify(mockDbHelper.create(any)).called(1);
    });

    test('createProject with description', () async {
      final newProject = Project(
        id: 1,
        title: 'New Project',
        description: 'Description',
      );
      when(mockDbHelper.create(any)).thenAnswer((_) async => newProject);

      await projectStore.createProject(
        'New Project',
        description: 'Description',
      );

      expect(projectStore.projects.first.description, 'Description');
    });

    test('createProject handles errors', () async {
      when(mockDbHelper.create(any)).thenThrow(Exception('Create error'));

      expect(
        () => projectStore.createProject('Test'),
        throwsA(isA<Exception>()),
      );

      expect(projectStore.error, contains('Erreur lors de la création'));
    });

    test('updateProject updates existing project', () async {
      final initialProject = Project(id: 1, title: 'Initial');
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [initialProject]);
      await projectStore.loadProjects();

      final updatedProject = Project(id: 1, title: 'Updated');
      when(mockDbHelper.update(any)).thenAnswer((_) async => 1);

      await projectStore.updateProject(updatedProject);

      expect(projectStore.projects.first.title, 'Updated');
      verify(mockDbHelper.update(updatedProject)).called(1);
    });

    test('updateProject handles non-existent project', () async {
      final project = Project(id: 999, title: 'Non-existent');
      when(mockDbHelper.update(any)).thenAnswer((_) async => 0);

      await projectStore.updateProject(project);

      // Should not be in the list
      expect(projectStore.projects, isEmpty);
    });

    test('updateProject handles errors', () async {
      final project = Project(id: 1, title: 'Test');
      when(mockDbHelper.update(any)).thenThrow(Exception('Update error'));

      expect(
        () => projectStore.updateProject(project),
        throwsA(isA<Exception>()),
      );

      expect(projectStore.error, contains('Erreur lors de la mise à jour'));
    });

    test('deleteProject removes project', () async {
      final projects = [
        Project(id: 1, title: 'Project 1'),
        Project(id: 2, title: 'Project 2'),
      ];
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => projects);
      await projectStore.loadProjects();

      when(mockDbHelper.delete(1)).thenAnswer((_) async => 1);

      await projectStore.deleteProject(1);

      expect(projectStore.projectCount, 1);
      expect(projectStore.projects.any((p) => p.id == 1), false);
      verify(mockDbHelper.delete(1)).called(1);
    });

    test('deleteProject handles errors', () async {
      when(mockDbHelper.delete(1)).thenThrow(Exception('Delete error'));

      expect(() => projectStore.deleteProject(1), throwsA(isA<Exception>()));

      expect(projectStore.error, contains('Erreur lors de la suppression'));
    });

    test('getProjectById returns correct project', () async {
      final projects = [
        Project(id: 1, title: 'Project 1'),
        Project(id: 2, title: 'Project 2'),
      ];
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => projects);
      await projectStore.loadProjects();

      final project = projectStore.getProjectById(2);

      expect(project, isNotNull);
      expect(project?.title, 'Project 2');
    });

    test('getProjectById returns null for non-existent id', () {
      final project = projectStore.getProjectById(999);

      expect(project, isNull);
    });

    test('refreshProject updates specific project', () async {
      final initialProject = Project(id: 1, title: 'Initial');
      when(
        mockDbHelper.readAllProjects(),
      ).thenAnswer((_) async => [initialProject]);
      await projectStore.loadProjects();

      final updatedProject = Project(id: 1, title: 'Refreshed');
      when(mockDbHelper.readProject(1)).thenAnswer((_) async => updatedProject);

      await projectStore.refreshProject(1);

      expect(projectStore.projects.first.title, 'Refreshed');
    });

    test('refreshProject handles non-existent project', () async {
      await projectStore.refreshProject(999);

      // Should not crash and projects should remain empty
      expect(projectStore.projects, isEmpty);
    });

    test('clearError clears error message', () async {
      when(mockDbHelper.readAllProjects()).thenThrow(Exception('Test error'));

      try {
        await projectStore.loadProjects();
      } catch (_) {}

      expect(projectStore.error, isNotNull);

      projectStore.clearError();

      expect(projectStore.error, isNull);
    });

    test('notifies listeners on state changes', () async {
      var notificationCount = 0;
      projectStore.addListener(() => notificationCount++);

      final projects = [Project(id: 1, title: 'Project 1')];
      when(mockDbHelper.readAllProjects()).thenAnswer((_) async => projects);

      await projectStore.loadProjects();

      // Should notify at start (loading=true) and end (loading=false)
      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    test('projects getter returns unmodifiable list', () {
      expect(
        () =>
            (projectStore.projects as List).add(Project(id: 1, title: 'Test')),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('uses default DatabaseHelper.instance when not provided', () {
      final store = ProjectStore();
      // Should not crash and should be initialized
      expect(store.projects, isEmpty);
      expect(store.isLoading, false);
      expect(store.error, isNull);
    });
  });
}
