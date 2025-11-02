import 'package:roadmindphone/features/session/data/models/session_model.dart';

/// Abstract interface for Session local data source
///
/// Defines methods for accessing session data from the local database.
/// Implementation details (DatabaseHelper usage) are hidden from this interface.
abstract class SessionLocalDataSource {
  /// Retrieves a single session by ID from the database
  ///
  /// Throws [DatabaseException] if operation fails
  /// Throws [NotFoundException] if session doesn't exist
  Future<SessionModel> getSession(int id);

  /// Retrieves all sessions for a specific project from the database
  ///
  /// Returns empty list if no sessions found
  /// Throws [DatabaseException] if operation fails
  Future<List<SessionModel>> getSessionsForProject(int projectId);

  /// Retrieves all sessions from the database
  ///
  /// Returns empty list if no sessions found
  /// Throws [DatabaseException] if operation fails
  Future<List<SessionModel>> getAllSessions();

  /// Creates a new session in the database
  ///
  /// Returns the created session with generated ID
  /// Throws [DatabaseException] if operation fails
  /// Throws [ValidationException] if session data is invalid
  Future<SessionModel> createSession(SessionModel session);

  /// Updates an existing session in the database
  ///
  /// Throws [DatabaseException] if operation fails
  /// Throws [NotFoundException] if session doesn't exist
  Future<void> updateSession(SessionModel session);

  /// Deletes a session by ID from the database
  ///
  /// Throws [DatabaseException] if operation fails
  /// Throws [NotFoundException] if session doesn't exist
  Future<void> deleteSession(int id);

  /// Gets the count of sessions for a specific project
  ///
  /// Throws [DatabaseException] if operation fails
  Future<int> getSessionCountForProject(int projectId);

  /// Checks if a session exists by ID
  ///
  /// Returns true if exists, false otherwise
  /// Throws [DatabaseException] if operation fails
  Future<bool> sessionExists(int id);
}
