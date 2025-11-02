import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/features/project/domain/usecases/create_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/delete_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_all_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/search_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/update_project.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';

import 'project_event.dart';
import 'project_state.dart';

/// BLoC for managing project-related state and business logic
///
/// This BLoC handles all project operations by:
/// 1. Receiving events from the UI
/// 2. Calling appropriate use cases
/// 3. Emitting new states based on results
///
/// Dependencies are injected via constructor for testability.
class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  final CreateProject createProject;
  final GetProject getProject;
  final GetAllProjects getAllProjects;
  final UpdateProject updateProject;
  final DeleteProject deleteProject;
  final SearchProjects searchProjects;

  ProjectBloc({
    required this.createProject,
    required this.getProject,
    required this.getAllProjects,
    required this.updateProject,
    required this.deleteProject,
    required this.searchProjects,
  }) : super(const ProjectInitial()) {
    // Register event handlers
    on<LoadProjectsEvent>(_onLoadProjects);
    on<CreateProjectEvent>(_onCreateProject);
    on<UpdateProjectEvent>(_onUpdateProject);
    on<DeleteProjectEvent>(_onDeleteProject);
    on<SearchProjectsEvent>(_onSearchProjects);
    on<GetProjectEvent>(_onGetProject);
    on<RefreshProjectsEvent>(_onRefreshProjects);
  }

  /// Handle loading all projects
  Future<void> _onLoadProjects(
    LoadProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await getAllProjects(NoParams());

    result.fold((failure) => emit(ProjectError(message: failure.message)), (
      projects,
    ) {
      if (projects.isEmpty) {
        emit(const ProjectsEmpty());
      } else {
        emit(ProjectsLoaded(projects: projects));
      }
    });
  }

  /// Handle creating a new project
  Future<void> _onCreateProject(
    CreateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await createProject(
      CreateProjectParams(title: event.title, description: event.description),
    );

    result.fold((failure) => emit(ProjectError(message: failure.message)), (
      project,
    ) {
      emit(
        const ProjectOperationSuccess(message: 'Project created successfully'),
      );
      // Reload projects after creation
      add(const LoadProjectsEvent());
    });
  }

  /// Handle updating an existing project
  Future<void> _onUpdateProject(
    UpdateProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await updateProject(UpdateProjectParams(event.project));

    result.fold((failure) => emit(ProjectError(message: failure.message)), (
      project,
    ) {
      emit(
        const ProjectOperationSuccess(message: 'Project updated successfully'),
      );
      // Reload projects after update
      add(const LoadProjectsEvent());
    });
  }

  /// Handle deleting a project
  Future<void> _onDeleteProject(
    DeleteProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await deleteProject(DeleteProjectParams(event.projectId));

    result.fold((failure) => emit(ProjectError(message: failure.message)), (_) {
      emit(
        const ProjectOperationSuccess(message: 'Project deleted successfully'),
      );
      // Reload projects after deletion
      add(const LoadProjectsEvent());
    });
  }

  /// Handle searching projects
  Future<void> _onSearchProjects(
    SearchProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await searchProjects(SearchProjectsParams(event.query));

    result.fold((failure) => emit(ProjectError(message: failure.message)), (
      results,
    ) {
      emit(ProjectsSearchResults(results: results, query: event.query));
    });
  }

  /// Handle getting a specific project
  Future<void> _onGetProject(
    GetProjectEvent event,
    Emitter<ProjectState> emit,
  ) async {
    emit(const ProjectsLoading());

    final result = await getProject(GetProjectParams(event.projectId));

    result.fold(
      (failure) => emit(ProjectError(message: failure.message)),
      (project) => emit(ProjectLoaded(project: project)),
    );
  }

  /// Handle refreshing the projects list
  Future<void> _onRefreshProjects(
    RefreshProjectsEvent event,
    Emitter<ProjectState> emit,
  ) async {
    // Refresh is the same as loading
    add(const LoadProjectsEvent());
  }
}
