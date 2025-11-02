import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for retrieving all sessions for a specific project
///
/// Encapsulates the business logic for getting sessions by project ID.
class GetSessionsForProject
    implements UseCase<List<SessionEntity>, GetSessionsForProjectParams> {
  final SessionRepository repository;

  GetSessionsForProject(this.repository);

  @override
  Future<Either<Failure, List<SessionEntity>>> call(
    GetSessionsForProjectParams params,
  ) async {
    return await repository.getSessionsForProject(params.projectId);
  }
}

/// Parameters for GetSessionsForProject use case
class GetSessionsForProjectParams extends Equatable {
  final int projectId;

  const GetSessionsForProjectParams({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}
