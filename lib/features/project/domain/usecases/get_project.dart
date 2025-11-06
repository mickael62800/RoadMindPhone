import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for retrieving a project by its ID
///
/// Returns the project if found, or a NotFoundFailure if not found.
class GetProject implements UseCase<ProjectEntity, GetProjectParams> {
  final ProjectRepository _repository;

  const GetProject(this._repository);

  @override
  ResultFuture<ProjectEntity> call(GetProjectParams params) async {
    return _repository.getProject(params.id);
  }
}

/// Parameters for getting a project

class GetProjectParams extends Equatable {
  final String id;

  const GetProjectParams(this.id);

  @override
  List<Object?> get props => [id];
}
