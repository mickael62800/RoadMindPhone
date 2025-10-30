
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/main.dart';
import 'package:roadmindphone/project_index_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      // Make sure the database is clean before each test
      await dbHelper.database;
      await _cleanDatabase(dbHelper);
    });

    tearDown(() async {
      // No need to close for in-memory database
    });

    test('Create and Read Project', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      expect(createdProject.id, isNotNull);
      expect(createdProject.title, 'Test Project');

      final readProject = await dbHelper.readProject(createdProject.id!);
      expect(readProject.id, createdProject.id);
      expect(readProject.title, 'Test Project');
    });

    test('Create and Read Session', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id!,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );

      final createdSession = await dbHelper.createSession(session);

      expect(createdSession.id, isNotNull);
      expect(createdSession.name, 'Test Session');

      final sessions = await dbHelper.readAllSessionsForProject(createdProject.id!);
      expect(sessions, hasLength(1));
      expect(sessions.first.name, 'Test Session');
    });

    test('Update Project', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final updatedProject = createdProject.copy(title: 'Updated Project');
      final result = await dbHelper.update(updatedProject);

      expect(result, 1);

      final readProject = await dbHelper.readProject(createdProject.id!);
      expect(readProject.title, 'Updated Project');
    });

    test('Delete Project', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final result = await dbHelper.delete(createdProject.id!);
      expect(result, 1);

      expect(() => dbHelper.readProject(createdProject.id!), throwsException);
    });

    test('Read All Projects', () async {
      await dbHelper.create(Project(title: 'Project A'));
      await dbHelper.create(Project(title: 'Project B'));

      final projects = await dbHelper.readAllProjects();
      expect(projects, hasLength(2));
      expect(projects[0].title, 'Project A');
      expect(projects[1].title, 'Project B');
    });

    test('Update Session', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id!,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );
      final createdSession = await dbHelper.createSession(session);

      final updatedSession = createdSession.copy(name: 'Updated Session', duration: Duration(minutes: 20));
      final result = await dbHelper.updateSession(updatedSession);

      expect(result, 1);

      final sessions = await dbHelper.readAllSessionsForProject(createdProject.id!);
      expect(sessions.first.name, 'Updated Session');
      expect(sessions.first.duration, Duration(minutes: 20));
    });

    test('Delete Session', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id!,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );
      final createdSession = await dbHelper.createSession(session);

      final result = await dbHelper.deleteSession(createdSession.id!);
      expect(result, 1);

      final sessions = await dbHelper.readAllSessionsForProject(createdProject.id!);
      expect(sessions, isEmpty);
    });

    test('Project sessionCount and duration are correct', () async {
      final project = Project(title: 'Project with Sessions');
      final createdProject = await dbHelper.create(project);

      await dbHelper.createSession(Session(
        projectId: createdProject.id!,
        name: 'Session 1',
        duration: Duration(minutes: 10),
        gpsPoints: 10,
      ));
      await dbHelper.createSession(Session(
        projectId: createdProject.id!,
        name: 'Session 2',
        duration: Duration(minutes: 20),
        gpsPoints: 20,
      ));

      final readProject = await dbHelper.readProject(createdProject.id!);
      expect(readProject.sessionCount, 2);
      expect(readProject.duration, Duration(minutes: 30));

      final allProjects = await dbHelper.readAllProjects();
      final projectWithSessions = allProjects.firstWhere((p) => p.id == createdProject.id);
      expect(projectWithSessions.sessionCount, 2);
      expect(projectWithSessions.duration, Duration(minutes: 30));
    });
  });
}

Future<void> _cleanDatabase(DatabaseHelper dbHelper) async {
  final db = await dbHelper.database;
  await db.delete('projects');
  await db.delete('sessions');
}

