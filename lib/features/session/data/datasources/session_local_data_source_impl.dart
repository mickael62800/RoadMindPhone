import 'package:roadmindphone/core/error/exceptions.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/features/session/data/datasources/session_local_data_source.dart';
import 'package:roadmindphone/features/session/data/models/session_model.dart';
import 'package:roadmindphone/session.dart';

/// Implementation of SessionLocalDataSource using DatabaseHelper
///
/// Provides concrete implementations for session database operations.
class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  final DatabaseHelper databaseHelper;

  SessionLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<SessionModel> getSession(int id) async {
    try {
      final session = await databaseHelper.readSession(id);
      return _convertToModel(session);
    } catch (e) {
      if (e.toString().contains('not found')) {
        throw NotFoundException('Session with ID $id not found');
      }
      throw DatabaseException('Failed to get session: ${e.toString()}');
    }
  }

  @override
  Future<List<SessionModel>> getSessionsForProject(int projectId) async {
    try {
      final sessions = await databaseHelper.readAllSessionsForProject(
        projectId,
      );
      return sessions.map((session) => _convertToModel(session)).toList();
    } catch (e) {
      throw DatabaseException(
        'Failed to get sessions for project: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SessionModel>> getAllSessions() async {
    try {
      final db = await databaseHelper.database;
      const orderBy = 'name ASC';
      final result = await db.query('sessions', orderBy: orderBy);

      return result.map((json) => SessionModel.fromMap(json)).toList();
    } catch (e) {
      throw DatabaseException('Failed to get all sessions: ${e.toString()}');
    }
  }

  @override
  Future<SessionModel> createSession(SessionModel session) async {
    try {
      // Validate session
      if (!session.hasValidName) {
        throw ValidationException('Session name is required');
      }

      // Convert to legacy Session for database insertion
      final legacySession = _convertToLegacy(session);
      final createdSession = await databaseHelper.createSession(legacySession);

      return _convertToModel(createdSession);
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      throw DatabaseException('Failed to create session: ${e.toString()}');
    }
  }

  @override
  Future<void> updateSession(SessionModel session) async {
    try {
      // Validate session
      if (session.id == null) {
        throw ValidationException('Session ID is required for update');
      }
      if (!session.hasValidName) {
        throw ValidationException('Session name is required');
      }

      // Check if session exists
      final exists = await sessionExists(session.id!);
      if (!exists) {
        throw NotFoundException('Session with ID ${session.id} not found');
      }

      // Convert to legacy Session for database update
      final legacySession = _convertToLegacy(session);
      await databaseHelper.updateSession(legacySession);
    } catch (e) {
      if (e is ValidationException || e is NotFoundException) {
        rethrow;
      }
      throw DatabaseException('Failed to update session: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    try {
      // Check if session exists
      final exists = await sessionExists(id);
      if (!exists) {
        throw NotFoundException('Session with ID $id not found');
      }

      await databaseHelper.deleteSession(id);
    } catch (e) {
      if (e is NotFoundException) {
        rethrow;
      }
      throw DatabaseException('Failed to delete session: ${e.toString()}');
    }
  }

  @override
  Future<int> getSessionCountForProject(int projectId) async {
    try {
      final sessions = await getSessionsForProject(projectId);
      return sessions.length;
    } catch (e) {
      throw DatabaseException('Failed to get session count: ${e.toString()}');
    }
  }

  @override
  Future<bool> sessionExists(int id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.query(
        'sessions',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [id],
      );
      return result.isNotEmpty;
    } catch (e) {
      throw DatabaseException(
        'Failed to check session existence: ${e.toString()}',
      );
    }
  }

  /// Converts legacy Session to SessionModel
  SessionModel _convertToModel(Session session) {
    return SessionModel(
      id: session.id,
      projectId: session.projectId,
      name: session.name,
      duration: session.duration,
      gpsPoints: session.gpsPoints,
      videoPath: session.videoPath,
      gpsData: session.gpsData,
      startTime: session.startTime,
      endTime: session.endTime,
      notes: session.notes,
      createdAt: DateTime.now(), // Legacy Session doesn't have createdAt
      updatedAt: null,
    );
  }

  /// Converts SessionModel to legacy Session for database operations
  Session _convertToLegacy(SessionModel model) {
    return Session(
      id: model.id,
      projectId: model.projectId,
      name: model.name,
      duration: model.duration,
      gpsPoints: model.gpsPoints,
      videoPath: model.videoPath,
      gpsData: model.gpsData,
      startTime: model.startTime,
      endTime: model.endTime,
      notes: model.notes,
    );
  }
}
