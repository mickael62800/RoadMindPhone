import 'package:equatable/equatable.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Base class for all Project states
///
/// States represent the current state of the UI and are
/// emitted by the ProjectBloc in response to events.
abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is first created
class ProjectInitial extends ProjectState {
  const ProjectInitial();
}

/// State when projects are being loaded
class ProjectsLoading extends ProjectState {
  const ProjectsLoading();
}

/// State when projects have been loaded successfully
class ProjectsLoaded extends ProjectState {
  final List<ProjectEntity> projects;

  const ProjectsLoaded({required this.projects});

  @override
  List<Object?> get props => [projects];
}

/// State when a single project has been loaded
class ProjectLoaded extends ProjectState {
  final ProjectEntity project;

  const ProjectLoaded({required this.project});

  @override
  List<Object?> get props => [project];
}

/// State when a project operation (create/update/delete) is successful
class ProjectOperationSuccess extends ProjectState {
  final String message;

  const ProjectOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when a project count has been retrieved
class ProjectsCountLoaded extends ProjectState {
  final int count;

  const ProjectsCountLoaded({required this.count});

  @override
  List<Object?> get props => [count];
}

/// State when project existence check is completed
class ProjectExistsChecked extends ProjectState {
  final bool exists;

  const ProjectExistsChecked({required this.exists});

  @override
  List<Object?> get props => [exists];
}

/// State when search results are available
class ProjectsSearchResults extends ProjectState {
  final List<ProjectEntity> results;
  final String query;

  const ProjectsSearchResults({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

/// State when an error occurs
class ProjectError extends ProjectState {
  final String message;

  const ProjectError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when the projects list is empty
class ProjectsEmpty extends ProjectState {
  const ProjectsEmpty();
}
