import 'package:dartz/dartz.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for retrieving all sessions
///
/// Encapsulates the business logic for getting all sessions from the database.
class GetAllSessions implements UseCase<List<SessionEntity>, NoParams> {
  final SessionRepository repository;

  GetAllSessions(this.repository);

  @override
  Future<Either<Failure, List<SessionEntity>>> call(NoParams params) async {
    return await repository.getAllSessions();
  }
}
