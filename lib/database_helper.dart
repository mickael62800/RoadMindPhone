import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:roadmindphone/project.dart';
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/session_gps_point.dart';
// Imports déjà présents plus bas, supprimés ici pour éviter les doublons

class DatabaseHelper {
  // CRUD pour les points GPS
  Future<void> insertSessionGpsPoint(SessionGpsPoint point) async {
    final db = await instance.database;
    await db.insert('session_gps_points', point.toMap());
  }

  Future<List<SessionGpsPoint>> getSessionGpsPoints(String sessionId) async {
    final db = await instance.database;
    final result = await db.query(
      'session_gps_points',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return result.map((e) => SessionGpsPoint.fromMap(e)).toList();
  }

  Future<void> deleteSessionGpsPoints(String sessionId) async {
    final db = await instance.database;
    await db.delete(
      'session_gps_points',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._init();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._init();
    return _instance!;
  }

  // For testing purposes
  static setTestInstance(DatabaseHelper newInstance) {
    _instance = newInstance;
    _database = null; // Reset database when setting a test instance
  }

  static void resetInstance() {
    _instance = null;
    _database = null;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('roadmind.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      // Ajout colonne exported si migration depuis une version précédente
      await db.execute(
        'ALTER TABLE sessions ADD COLUMN exported INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 7) {
      await db.execute('DROP TABLE IF EXISTS sessions');
      await db.execute('DROP TABLE IF EXISTS projects');
      await _createDB(db, newVersion);
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE projects (
  id $idType,
  title $textType,
  description TEXT,
  session_count INTEGER DEFAULT 0,
  duration INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE sessions (
  id $idType,
  projectId TEXT NOT NULL,
  name $textType,
  duration $integerType,
  gpsPoints $integerType,
  videoPath TEXT,
  gpsData TEXT,
  startTime TEXT,
  endTime TEXT,
  notes TEXT,
  exported INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE session_gps_points (
  id TEXT PRIMARY KEY,
  sessionId TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  altitude REAL,
  speed REAL,
  heading REAL,
  timestamp TEXT NOT NULL,
  videoTimestampMs INTEGER,
  FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
)
''');
  }

  Future<Project> create(Project project) async {
    final db = await instance.database;
    final projectMap = project.toMap();
    if (!projectMap.containsKey('created_at')) {
      projectMap['created_at'] = DateTime.now().toIso8601String();
    }
    await db.insert('projects', projectMap);
    return project;
  }

  Future<Session> createSession(Session session) async {
    final db = await instance.database;
    await db.insert('sessions', session.toMap());
    return session;
  }

  Future<Project> readProject(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'projects',
      columns: ['id', 'title', 'description'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final projectMap = maps.first;
      final sessions = await readAllSessionsForProject(
        projectMap['id'] as String,
      );
      final duration = sessions.fold<Duration>(
        Duration.zero,
        (previousValue, element) => previousValue + element.duration,
      );
      return Project.fromMap(projectMap).copy(
        sessionCount: sessions.length,
        duration: duration,
        sessions: sessions,
      );
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<Session> readSession(String id) async {
    final db = await instance.database;
    final maps = await db.query('sessions', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    } else {
      throw Exception('Session with ID $id not found');
    }
  }

  Future<List<Project>> readAllProjects() async {
    final db = await instance.database;
    const orderBy = 'title ASC';
    final result = await db.query('projects', orderBy: orderBy);

    final projects = <Project>[];
    for (final map in result) {
      final sessions = await readAllSessionsForProject(map['id'] as String);
      final duration = sessions.fold<Duration>(
        Duration.zero,
        (previousValue, element) => previousValue + element.duration,
      );
      projects.add(
        Project.fromMap(map).copy(
          sessionCount: sessions.length,
          duration: duration,
          sessions: sessions,
        ),
      );
    }

    return projects;
  }

  Future<List<Session>> readAllSessionsForProject(String projectId) async {
    final db = await instance.database;
    const orderBy = 'name ASC';
    final result = await db.query(
      'sessions',
      orderBy: orderBy,
      where: 'projectId = ?',
      whereArgs: [projectId],
    );

    return result.map((json) => Session.fromMap(json)).toList();
  }

  Future<int> update(Project project) async {
    final db = await instance.database;
    return db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> updateSession(Session session) async {
    final db = await instance.database;
    return db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSession(String id) async {
    final db = await instance.database;
    return await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
