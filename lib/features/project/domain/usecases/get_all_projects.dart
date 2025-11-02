import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for retrieving all projects
///
/// Returns a list of all projects, ordered by creation date (newest first).
/// Returns an empty list if no projects exist.
class GetAllProjects implements UseCase<List<ProjectEntity>, NoParams> {
  final ProjectRepository _repository;

  const GetAllProjects(this._repository);

  @override
  ResultFuture<List<ProjectEntity>> call(NoParams params) async {
    return _repository.getAllProjects();
  }
}
