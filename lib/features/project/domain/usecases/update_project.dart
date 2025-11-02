import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for updating an existing project
///
/// Updates the project with the provided entity.
/// Returns the updated project or a Failure.
class UpdateProject implements UseCase<ProjectEntity, UpdateProjectParams> {
  final ProjectRepository _repository;

  const UpdateProject(this._repository);

  @override
  ResultFuture<ProjectEntity> call(UpdateProjectParams params) async {
    return _repository.updateProject(params.project);
  }
}

/// Parameters for updating a project
class UpdateProjectParams extends Equatable {
  final ProjectEntity project;

  const UpdateProjectParams(this.project);

  @override
  List<Object?> get props => [project];
}
