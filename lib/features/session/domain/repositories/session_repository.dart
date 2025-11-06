import 'package:dartz/dartz.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';

/// Repository interface for Session data operations
///
/// Defines the contract for session data access without
/// specifying the implementation details.
abstract class SessionRepository {
  /// Retrieves a single session by its ID
  ///
  /// Returns [Right(SessionEntity)] on success
  /// Returns [Left(Failure)] on error (DatabaseFailure, NotFoundFailure)
  Future<Either<Failure, SessionEntity>> getSession(String id);

  /// Retrieves all sessions for a specific project
  ///
  /// Returns [Right(List<SessionEntity>)] on success (empty list if no sessions)
  /// Returns [Left(Failure)] on error (DatabaseFailure)
  Future<Either<Failure, List<SessionEntity>>> getSessionsForProject(
    String projectId,
  );

  /// Retrieves all sessions from the database
  ///
  /// Returns [Right(List<SessionEntity>)] on success (empty list if no sessions)
  /// Returns [Left(Failure)] on error (DatabaseFailure)
  Future<Either<Failure, List<SessionEntity>>> getAllSessions();

  /// Creates a new session
  ///
  /// Returns [Right(SessionEntity)] with the created session (including generated ID)
  /// Returns [Left(Failure)] on error (DatabaseFailure, ValidationFailure)
  Future<Either<Failure, SessionEntity>> createSession(SessionEntity session);

  /// Updates an existing session
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error (DatabaseFailure, NotFoundFailure)
  Future<Either<Failure, void>> updateSession(SessionEntity session);

  /// Deletes a session by its ID
  ///
  /// Returns [Right(void)] on success
  /// Returns [Left(Failure)] on error (DatabaseFailure, NotFoundFailure)
  Future<Either<Failure, void>> deleteSession(String id);

  /// Gets the count of sessions for a specific project
  ///
  /// Returns [Right(int)] with the count on success
  /// Returns [Left(Failure)] on error (DatabaseFailure)
  Future<Either<Failure, int>> getSessionCountForProject(String projectId);

  /// Checks if a session exists by its ID
  ///
  /// Returns [Right(bool)] true if exists, false otherwise
  /// Returns [Left(Failure)] on error (DatabaseFailure)
  Future<Either<Failure, bool>> sessionExists(String id);
}
