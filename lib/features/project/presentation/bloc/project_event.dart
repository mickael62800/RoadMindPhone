import 'package:equatable/equatable.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Base class for all Project events
///
/// Events represent user actions or system events that trigger
/// state changes in the ProjectBloc.
abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all projects from the repository
class LoadProjectsEvent extends ProjectEvent {
  const LoadProjectsEvent();
}

/// Event to create a new project
class CreateProjectEvent extends ProjectEvent {
  final String title;
  final String? description;

  const CreateProjectEvent({required this.title, this.description});

  @override
  List<Object?> get props => [title, description];
}

/// Event to update an existing project
class UpdateProjectEvent extends ProjectEvent {
  final ProjectEntity project;

  const UpdateProjectEvent({required this.project});

  @override
  List<Object?> get props => [project];
}

/// Event to delete a project
class DeleteProjectEvent extends ProjectEvent {
  final String projectId;

  const DeleteProjectEvent({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Event to search projects by title
class SearchProjectsEvent extends ProjectEvent {
  final String query;

  const SearchProjectsEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Event to get a specific project by ID
class GetProjectEvent extends ProjectEvent {
  final String projectId;

  const GetProjectEvent({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Event to get the total count of projects
class GetProjectsCountEvent extends ProjectEvent {
  const GetProjectsCountEvent();
}

/// Event to check if a project exists
class CheckProjectExistsEvent extends ProjectEvent {
  final String projectId;

  const CheckProjectExistsEvent({required this.projectId});

  @override
  List<Object?> get props => [projectId];
}

/// Event to refresh the projects list
class RefreshProjectsEvent extends ProjectEvent {
  const RefreshProjectsEvent();
}
