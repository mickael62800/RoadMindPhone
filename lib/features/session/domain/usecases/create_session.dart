import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for creating a new session
///
/// Encapsulates the business logic for creating a session in the database.
class CreateSession implements UseCase<SessionEntity, CreateSessionParams> {
  final SessionRepository repository;

  CreateSession(this.repository);

  @override
  Future<Either<Failure, SessionEntity>> call(
    CreateSessionParams params,
  ) async {
    return await repository.createSession(params.session);
  }
}

/// Parameters for the CreateSession use case
class CreateSessionParams extends Equatable {
  final SessionEntity session;

  const CreateSessionParams({required this.session});

  @override
  List<Object?> get props => [session];
}
