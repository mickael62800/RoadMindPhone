import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Use case for searching projects
///
/// Searches for projects by title or description (case-insensitive).
/// Returns an empty list if no matches found.
class SearchProjects
    implements UseCase<List<ProjectEntity>, SearchProjectsParams> {
  final ProjectRepository _repository;

  const SearchProjects(this._repository);

  @override
  ResultFuture<List<ProjectEntity>> call(SearchProjectsParams params) async {
    return _repository.searchProjects(params.query);
  }
}

/// Parameters for searching projects
class SearchProjectsParams extends Equatable {
  final String query;

  const SearchProjectsParams(this.query);

  @override
  List<Object?> get props => [query];
}
