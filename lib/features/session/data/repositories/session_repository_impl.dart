import 'package:dartz/dartz.dart';
import 'package:roadmindphone/core/error/exceptions.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/session/data/datasources/session_local_data_source.dart';
import 'package:roadmindphone/features/session/data/models/session_model.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Implementation of SessionRepository
///
/// Handles session data operations and converts between domain entities
/// and data models. Catches exceptions from data sources and converts
/// them to Failures.
class SessionRepositoryImpl implements SessionRepository {
  final SessionLocalDataSource localDataSource;

  SessionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, SessionEntity>> getSession(int id) async {
    try {
      final model = await localDataSource.getSession(id);
      return Right(model.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getSessionsForProject(
    int projectId,
  ) async {
    try {
      final models = await localDataSource.getSessionsForProject(projectId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SessionEntity>>> getAllSessions() async {
    try {
      final models = await localDataSource.getAllSessions();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SessionEntity>> createSession(
    SessionEntity session,
  ) async {
    try {
      // Convert entity to model
      final model = SessionModel.fromEntity(session);

      // Create in database
      final createdModel = await localDataSource.createSession(model);

      return Right(createdModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSession(SessionEntity session) async {
    try {
      // Convert entity to model
      final model = SessionModel.fromEntity(session);

      // Update in database
      await localDataSource.updateSession(model);

      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(int id) async {
    try {
      await localDataSource.deleteSession(id);
      return const Right(null);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getSessionCountForProject(int projectId) async {
    try {
      final count = await localDataSource.getSessionCountForProject(projectId);
      return Right(count);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> sessionExists(int id) async {
    try {
      final exists = await localDataSource.sessionExists(id);
      return Right(exists);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
