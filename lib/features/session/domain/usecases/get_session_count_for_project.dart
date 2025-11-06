import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for getting the count of sessions for a specific project
///
/// Encapsulates the business logic for counting sessions belonging to a project.
class GetSessionCountForProject
    implements UseCase<int, GetSessionCountForProjectParams> {
  final SessionRepository repository;

  GetSessionCountForProject(this.repository);

  @override
  Future<Either<Failure, int>> call(
    GetSessionCountForProjectParams params,
  ) async {
    return await repository.getSessionCountForProject(params.projectId);
  }
}

/// Parameters for the GetSessionCountForProject use case
class GetSessionCountForProjectParams extends Equatable {
  final String projectId;

  const GetSessionCountForProjectParams({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}
