import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for deleting a project
///
/// Deletes the project with the given ID.
/// Also deletes all associated sessions.
class DeleteProject implements VoidUseCase<DeleteProjectParams> {
  final ProjectRepository _repository;

  const DeleteProject(this._repository);

  @override
  ResultVoid call(DeleteProjectParams params) async {
    return _repository.deleteProject(params.id);
  }
}

/// Parameters for deleting a project

class DeleteProjectParams extends Equatable {
  final String id;

  const DeleteProjectParams(this.id);

  @override
  List<Object?> get props => [id];
}
