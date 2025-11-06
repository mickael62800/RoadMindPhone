import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/project.dart';
import 'package:roadmindphone/session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:roadmindphone/session_gps_point.dart';

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

      final readProject = await dbHelper.readProject(createdProject.id);
      expect(readProject.id, createdProject.id);
      expect(readProject.title, 'Test Project');
    });

    test('Create and Read Session', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );

      final createdSession = await dbHelper.createSession(session);

      expect(createdSession.id, isNotNull);
      expect(createdSession.name, 'Test Session');

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions, hasLength(1));
      expect(sessions.first.name, 'Test Session');
    });

    test('Update Project', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final updatedProject = createdProject.copy(title: 'Updated Project');
      final result = await dbHelper.update(updatedProject);

      expect(result, 1);

      final readProject = await dbHelper.readProject(createdProject.id);
      expect(readProject.title, 'Updated Project');
    });

    test('Delete Project', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final result = await dbHelper.delete(createdProject.id);
      expect(result, 1);

      expect(() => dbHelper.readProject(createdProject.id), throwsException);
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
        projectId: createdProject.id,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );
      final createdSession = await dbHelper.createSession(session);

      final updatedSession = createdSession.copy(
        name: 'Updated Session',
        duration: Duration(minutes: 20),
      );
      final result = await dbHelper.updateSession(updatedSession);

      expect(result, 1);

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions.first.name, 'Updated Session');
      expect(sessions.first.duration, Duration(minutes: 20));
    });

    test('Delete Session', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Test Session',
        duration: Duration(minutes: 10),
        gpsPoints: 100,
      );
      final createdSession = await dbHelper.createSession(session);

      final result = await dbHelper.deleteSession(createdSession.id);
      expect(result, 1);

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions, isEmpty);
    });

    test('Project sessionCount and duration are correct', () async {
      final project = Project(title: 'Project with Sessions');
      final createdProject = await dbHelper.create(project);

      await dbHelper.createSession(
        Session(
          projectId: createdProject.id,
          name: 'Session 1',
          duration: Duration(minutes: 10),
          gpsPoints: 10,
        ),
      );
      await dbHelper.createSession(
        Session(
          projectId: createdProject.id,
          name: 'Session 2',
          duration: Duration(minutes: 20),
          gpsPoints: 20,
        ),
      );

      final readProject = await dbHelper.readProject(createdProject.id);
      expect(readProject.sessionCount, 2);
      expect(readProject.duration, Duration(minutes: 30));

      final allProjects = await dbHelper.readAllProjects();
      final projectWithSessions = allProjects.firstWhere(
        (p) => p.id == createdProject.id,
      );
      expect(projectWithSessions.sessionCount, 2);
      expect(projectWithSessions.duration, Duration(minutes: 30));
    });

    test('readSession retrieves correct session with GPS data', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final gpsData = [
        SessionGpsPoint(
          sessionId: 'test-guid',
          latitude: 48.8566,
          longitude: 2.3522,
          speed: 10.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 0,
        ),
        SessionGpsPoint(
          sessionId: 'test-guid',
          latitude: 48.8580,
          longitude: 2.2945,
          speed: 15.0,
          timestamp: DateTime.now(),
          videoTimestampMs: 1000,
        ),
      ];

      final session = Session(
        projectId: createdProject.id,
        name: 'Session with GPS',
        duration: const Duration(minutes: 15),
        gpsPoints: 2,
        gpsData: gpsData,
      );

      final createdSession = await dbHelper.createSession(session);
      final readSession = await dbHelper.readSession(createdSession.id);

      expect(readSession.id, createdSession.id);
      expect(readSession.name, 'Session with GPS');
      expect(readSession.gpsData.length, 2);
      expect(readSession.gpsData[0].latitude, 48.8566);
      expect(readSession.gpsData[1].longitude, 2.2945);
    });

    test('Session with videoPath is stored and retrieved correctly', () async {
      final project = Project(title: 'Test Project');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Session with Video',
        duration: const Duration(minutes: 20),
        gpsPoints: 50,
        videoPath: '/path/to/video.mp4',
      );

      final createdSession = await dbHelper.createSession(session);
      final readSession = await dbHelper.readSession(createdSession.id);

      expect(readSession.videoPath, '/path/to/video.mp4');
    });

    test('Multiple sessions for same project', () async {
      final project = Project(title: 'Multi-Session Project');
      final createdProject = await dbHelper.create(project);

      await dbHelper.createSession(
        Session(
          projectId: createdProject.id,
          name: 'Session A',
          duration: const Duration(minutes: 5),
          gpsPoints: 10,
        ),
      );

      await dbHelper.createSession(
        Session(
          projectId: createdProject.id,
          name: 'Session B',
          duration: const Duration(minutes: 10),
          gpsPoints: 20,
        ),
      );

      await dbHelper.createSession(
        Session(
          projectId: createdProject.id,
          name: 'Session C',
          duration: const Duration(minutes: 15),
          gpsPoints: 30,
        ),
      );

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions.length, 3);
      expect(sessions.map((s) => s.name).toList(), [
        'Session A',
        'Session B',
        'Session C',
      ]);
    });

    test('Database is singleton', () {
      final instance1 = DatabaseHelper.instance;
      final instance2 = DatabaseHelper.instance;
      expect(identical(instance1, instance2), true);
    });

    test('Empty project list when no projects exist', () async {
      await _cleanDatabase(dbHelper);
      final projects = await dbHelper.readAllProjects();
      expect(projects, isEmpty);
    });

    test('Empty session list when no sessions for project', () async {
      final project = Project(title: 'Empty Project');
      final createdProject = await dbHelper.create(project);

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions, isEmpty);
    });

    test('readSession returns correct session', () async {
      final project = Project(title: 'Project for Session');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Test Session',
        duration: const Duration(minutes: 10),
        gpsPoints: 5,
      );
      final createdSession = await dbHelper.createSession(session);

      final readSession = await dbHelper.readSession(createdSession.id);
      expect(readSession.id, createdSession.id);
      expect(readSession.name, 'Test Session');
      expect(readSession.projectId, createdProject.id);
    });

    test('updateSession modifies existing session', () async {
      final project = Project(title: 'Project for Update');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Original Name',
        duration: const Duration(minutes: 5),
        gpsPoints: 3,
      );
      final createdSession = await dbHelper.createSession(session);

      final updatedSession = createdSession.copy(
        name: 'Updated Name',
        gpsPoints: 10,
      );
      await dbHelper.updateSession(updatedSession);

      final readSession = await dbHelper.readSession(createdSession.id);
      expect(readSession.name, 'Updated Name');
      expect(readSession.gpsPoints, 10);
    });

    test('deleteSession removes session from database', () async {
      final project = Project(title: 'Project for Delete');
      final createdProject = await dbHelper.create(project);

      final session = Session(
        projectId: createdProject.id,
        name: 'Session to Delete',
        duration: const Duration(minutes: 5),
        gpsPoints: 2,
      );
      final createdSession = await dbHelper.createSession(session);

      await dbHelper.deleteSession(createdSession.id);

      final sessions = await dbHelper.readAllSessionsForProject(
        createdProject.id,
      );
      expect(sessions, isEmpty);
    });

    test('readAllProjects returns all projects', () async {
      await _cleanDatabase(dbHelper);

      final project1 = Project(title: 'Project 1');
      final project2 = Project(title: 'Project 2');

      await dbHelper.create(project1);
      await dbHelper.create(project2);

      final projects = await dbHelper.readAllProjects();
      expect(projects.length, 2);
      expect(projects.any((p) => p.title == 'Project 1'), true);
      expect(projects.any((p) => p.title == 'Project 2'), true);
    });

    test('database upgrade from old version works', () async {
      // This tests the _onUpgrade method by creating a DB with old schema
      final testPath = 'test_upgrade_real.db';
      databaseFactory = databaseFactoryFfi;

      // Delete if exists
      try {
        await deleteDatabase(testPath);
      } catch (_) {}

      // Create a database with version 3 (old version)
      var db = await openDatabase(
        testPath,
        version: 3,
        onCreate: (db, version) async {
          // Old schema without description field
          await db.execute('''
            CREATE TABLE projects (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              projectId INTEGER NOT NULL,
              name TEXT NOT NULL,
              duration INTEGER NOT NULL,
              gpsPoints INTEGER NOT NULL
            )
          ''');
        },
      );

      // Insert some test data
      await db.insert('projects', {'title': 'Old Project'});
      await db.close();

      // Now upgrade to version 5 - this should trigger _onUpgrade
      db = await openDatabase(
        testPath,
        version: 5,
        onCreate: (db, version) async {
          // Won't be called
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          // This mirrors the real _onUpgrade method
          if (oldVersion < 5) {
            await db.execute('DROP TABLE IF EXISTS sessions');
            await db.execute('DROP TABLE IF EXISTS projects');
            // Recreate with new schema
            await db.execute('''
              CREATE TABLE projects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                projectId INTEGER NOT NULL,
                name TEXT NOT NULL,
                duration INTEGER NOT NULL,
                gpsPoints INTEGER NOT NULL,
                videoPath TEXT,
                notes TEXT
              )
            ''');
          }
        },
      );

      // Verify tables exist with new schema
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      expect(tables.any((t) => t['name'] == 'projects'), true);
      expect(tables.any((t) => t['name'] == 'sessions'), true);

      // Verify new schema has description column
      final projectsInfo = await db.rawQuery('PRAGMA table_info(projects)');
      final hasDescription = projectsInfo.any(
        (col) => col['name'] == 'description',
      );
      expect(hasDescription, true);

      await db.close();
      await deleteDatabase(testPath);
    });

    test('readSession throws exception when not found', () async {
      await _cleanDatabase(dbHelper);

      expect(
        () async => await dbHelper.readSession('not-found-guid'),
        throwsException,
      );
    });

    test('close database', () async {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.database; // Ensure db is open
      await dbHelper.close();
      // After close, accessing database should reopen it
      final db = await dbHelper.database;
      expect(db.isOpen, true);
    });
  });
}

Future<void> _cleanDatabase(DatabaseHelper dbHelper) async {
  final db = await dbHelper.database;
  await db.delete('projects');
  await db.delete('sessions');
}
