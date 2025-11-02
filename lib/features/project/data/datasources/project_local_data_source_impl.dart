import '../../../../core/error/exceptions.dart';
import '../../../../database_helper.dart';
import '../models/project_model.dart';
import 'project_local_data_source.dart';

/// Implementation of [ProjectLocalDataSource] using SQLite via [DatabaseHelper].
///
/// This class provides concrete implementations for all project-related
/// local storage operations. It uses the existing [DatabaseHelper] to
/// interact with the SQLite database.
///
/// All methods throw [DatabaseException] when an error occurs during
/// database operations.
class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  final DatabaseHelper databaseHelper;

  /// Table name for projects in SQLite
  static const String _tableName = 'projects';

  const ProjectLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    try {
      final db = await databaseHelper.database;
      final map = project.toMap();

      // SQLite auto-generates the id, so we remove it if it's empty
      if (map['id'] == null || map['id'].toString().isEmpty) {
        map.remove('id');
      }

      final id = await db.insert(_tableName, map);

      // Return the project with the generated ID
      return project.copyWith(id: id);
    } catch (e) {
      throw DatabaseException('Failed to create project: ${e.toString()}');
    }
  }

  @override
  Future<ProjectModel> getProject(int id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isEmpty) {
        throw DatabaseException('Project not found with id: $id');
      }

      // Get all sessions for this project
      final sessions = await db.query(
        'sessions',
        where: 'projectId = ?',
        whereArgs: [id],
      );

      // Calculate total duration from sessions
      int totalDurationInSeconds = 0;
      for (final session in sessions) {
        final duration = session['duration'] as int? ?? 0;
        totalDurationInSeconds += duration;
      }

      // Create project model with calculated values
      final projectMap = Map<String, dynamic>.from(result.first);
      projectMap['session_count'] = sessions.length;
      projectMap['duration'] = totalDurationInSeconds;

      return ProjectModel.fromMap(projectMap);
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to get project: ${e.toString()}');
    }
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(_tableName, orderBy: 'created_at DESC');

      // Calculate session_count and duration dynamically for each project
      final projects = <ProjectModel>[];
      for (final map in result) {
        final projectId = map['id'] as int;

        // Get all sessions for this project
        final sessions = await db.query(
          'sessions',
          where: 'projectId = ?',
          whereArgs: [projectId],
        );

        // Calculate total duration from sessions
        int totalDurationInSeconds = 0;
        for (final session in sessions) {
          final duration = session['duration'] as int? ?? 0;
          totalDurationInSeconds += duration;
        }

        // Create project model with calculated values
        final projectMap = Map<String, dynamic>.from(map);
        projectMap['session_count'] = sessions.length;
        projectMap['duration'] = totalDurationInSeconds;

        projects.add(ProjectModel.fromMap(projectMap));
      }

      return projects;
    } catch (e) {
      throw DatabaseException('Failed to get all projects: ${e.toString()}');
    }
  }

  @override
  Future<ProjectModel> updateProject(ProjectModel project) async {
    try {
      final db = await databaseHelper.database;
      final map = project.toMap();

      final rowsAffected = await db.update(
        _tableName,
        map,
        where: 'id = ?',
        whereArgs: [project.id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Project not found with id: ${project.id}');
      }

      return project;
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to update project: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProject(int id) async {
    try {
      final db = await databaseHelper.database;
      final rowsAffected = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsAffected == 0) {
        throw DatabaseException('Project not found with id: $id');
      }
    } catch (e) {
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete project: ${e.toString()}');
    }
  }

  @override
  Future<int> getProjectsCount() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      return result.first['count'] as int;
    } catch (e) {
      throw DatabaseException('Failed to count projects: ${e.toString()}');
    }
  }

  @override
  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        where: 'LOWER(title) LIKE ?',
        whereArgs: ['%${query.toLowerCase()}%'],
        orderBy: 'created_at DESC',
      );

      return result.map((map) => ProjectModel.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseException('Failed to search projects: ${e.toString()}');
    }
  }

  @override
  Future<bool> projectExists(int id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      return result.isNotEmpty;
    } catch (e) {
      throw DatabaseException(
        'Failed to check if project exists: ${e.toString()}',
      );
    }
  }
}
