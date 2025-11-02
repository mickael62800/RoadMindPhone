import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for retrieving a single session by ID
///
/// Encapsulates the business logic for getting a session.
class GetSession implements UseCase<SessionEntity, GetSessionParams> {
  final SessionRepository repository;

  GetSession(this.repository);

  @override
  Future<Either<Failure, SessionEntity>> call(GetSessionParams params) async {
    return await repository.getSession(params.id);
  }
}

/// Parameters for GetSession use case
class GetSessionParams extends Equatable {
  final int id;

  const GetSessionParams({required this.id});

  @override
  List<Object?> get props => [id];
}
