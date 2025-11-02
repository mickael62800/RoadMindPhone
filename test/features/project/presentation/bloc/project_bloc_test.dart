import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/usecases/create_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/delete_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_all_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/search_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/update_project.dart';
import 'package:roadmindphone/features/project/presentation/bloc/bloc.dart';

import 'project_bloc_test.mocks.dart';

@GenerateMocks([
  CreateProject,
  GetProject,
  GetAllProjects,
  UpdateProject,
  DeleteProject,
  SearchProjects,
])
void main() {
  late ProjectBloc bloc;
  late MockCreateProject mockCreateProject;
  late MockGetProject mockGetProject;
  late MockGetAllProjects mockGetAllProjects;
  late MockUpdateProject mockUpdateProject;
  late MockDeleteProject mockDeleteProject;
  late MockSearchProjects mockSearchProjects;

  // Test data
  final tProject = ProjectEntity(
    id: 1,
    title: 'Test Project',
    description: 'Test Description',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    sessionCount: 0,
    duration: Duration.zero,
  );

  final tProjectList = [
    tProject,
    ProjectEntity(
      id: 2,
      title: 'Test Project 2',
      description: 'Test Description 2',
      createdAt: DateTime(2024, 1, 2),
      updatedAt: DateTime(2024, 1, 2),
      sessionCount: 1,
      duration: const Duration(hours: 1),
    ),
  ];

  setUp(() {
    mockCreateProject = MockCreateProject();
    mockGetProject = MockGetProject();
    mockGetAllProjects = MockGetAllProjects();
    mockUpdateProject = MockUpdateProject();
    mockDeleteProject = MockDeleteProject();
    mockSearchProjects = MockSearchProjects();

    bloc = ProjectBloc(
      createProject: mockCreateProject,
      getProject: mockGetProject,
      getAllProjects: mockGetAllProjects,
      updateProject: mockUpdateProject,
      deleteProject: mockDeleteProject,
      searchProjects: mockSearchProjects,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ProjectBloc', () {
    test('initial state should be ProjectInitial', () {
      expect(bloc.state, equals(const ProjectInitial()));
    });

    group('LoadProjectsEvent', () {
      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsLoaded] when loading projects succeeds',
        build: () {
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProjectsEvent()),
        expect: () => [
          const ProjectsLoading(),
          ProjectsLoaded(projects: tProjectList),
        ],
        verify: (_) {
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsEmpty] when no projects exist',
        build: () {
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProjectsEvent()),
        expect: () => [const ProjectsLoading(), const ProjectsEmpty()],
        verify: (_) {
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when loading projects fails with DatabaseFailure',
        build: () {
          when(mockGetAllProjects(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Database error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProjectsEvent()),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Database error'),
        ],
        verify: (_) {
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when loading projects fails with UnexpectedFailure',
        build: () {
          when(mockGetAllProjects(any)).thenAnswer(
            (_) async => const Left(UnexpectedFailure('Unexpected error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadProjectsEvent()),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Unexpected error'),
        ],
      );
    });

    group('CreateProjectEvent', () {
      const tTitle = 'New Project';
      const tDescription = 'New Description';

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectOperationSuccess, ProjectsLoading, ProjectsLoaded] when creating project succeeds',
        build: () {
          when(mockCreateProject(any)).thenAnswer((_) async => Right(tProject));
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CreateProjectEvent(title: tTitle, description: tDescription),
        ),
        expect: () => [
          const ProjectsLoading(),
          const ProjectOperationSuccess(
            message: 'Project created successfully',
          ),
          const ProjectsLoading(),
          ProjectsLoaded(projects: tProjectList),
        ],
        verify: (_) {
          verify(
            mockCreateProject(
              const CreateProjectParams(
                title: tTitle,
                description: tDescription,
              ),
            ),
          ).called(1);
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when creating project fails with ValidationFailure',
        build: () {
          when(mockCreateProject(any)).thenAnswer(
            (_) async => const Left(ValidationFailure('Title is required')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(
          const CreateProjectEvent(title: tTitle, description: tDescription),
        ),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Title is required'),
        ],
        verify: (_) {
          verify(
            mockCreateProject(
              const CreateProjectParams(
                title: tTitle,
                description: tDescription,
              ),
            ),
          ).called(1);
          verifyNever(mockGetAllProjects(any));
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when creating project fails with DatabaseFailure',
        build: () {
          when(mockCreateProject(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Insert failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const CreateProjectEvent(title: tTitle)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Insert failed'),
        ],
      );
    });

    group('UpdateProjectEvent', () {
      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectOperationSuccess, ProjectsLoading, ProjectsLoaded] when updating project succeeds',
        build: () {
          when(mockUpdateProject(any)).thenAnswer((_) async => Right(tProject));
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateProjectEvent(project: tProject)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectOperationSuccess(
            message: 'Project updated successfully',
          ),
          const ProjectsLoading(),
          ProjectsLoaded(projects: tProjectList),
        ],
        verify: (_) {
          verify(mockUpdateProject(UpdateProjectParams(tProject))).called(1);
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when updating project fails with NotFoundFailure',
        build: () {
          when(mockUpdateProject(any)).thenAnswer(
            (_) async => const Left(NotFoundFailure('Project not found')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateProjectEvent(project: tProject)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Project not found'),
        ],
        verify: (_) {
          verify(mockUpdateProject(UpdateProjectParams(tProject))).called(1);
          verifyNever(mockGetAllProjects(any));
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when updating project fails with ValidationFailure',
        build: () {
          when(mockUpdateProject(any)).thenAnswer(
            (_) async => const Left(ValidationFailure('Invalid project data')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(UpdateProjectEvent(project: tProject)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Invalid project data'),
        ],
      );
    });

    group('DeleteProjectEvent', () {
      const tProjectId = 1;

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectOperationSuccess, ProjectsLoading, ProjectsLoaded] when deleting project succeeds',
        build: () {
          when(
            mockDeleteProject(any),
          ).thenAnswer((_) async => const Right(null));
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectOperationSuccess(
            message: 'Project deleted successfully',
          ),
          const ProjectsLoading(),
          ProjectsLoaded(projects: tProjectList),
        ],
        verify: (_) {
          verify(
            mockDeleteProject(const DeleteProjectParams(tProjectId)),
          ).called(1);
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when deleting project fails with NotFoundFailure',
        build: () {
          when(mockDeleteProject(any)).thenAnswer(
            (_) async => const Left(NotFoundFailure('Project not found')),
          );
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Project not found'),
        ],
        verify: (_) {
          verify(
            mockDeleteProject(const DeleteProjectParams(tProjectId)),
          ).called(1);
          verifyNever(mockGetAllProjects(any));
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when deleting project fails with DatabaseFailure',
        build: () {
          when(mockDeleteProject(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Delete failed')),
          );
          return bloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Delete failed'),
        ],
      );
    });

    group('SearchProjectsEvent', () {
      const tQuery = 'Test';

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsSearchResults] when searching projects succeeds',
        build: () {
          when(
            mockSearchProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchProjectsEvent(query: tQuery)),
        expect: () => [
          const ProjectsLoading(),
          ProjectsSearchResults(results: tProjectList, query: tQuery),
        ],
        verify: (_) {
          verify(
            mockSearchProjects(const SearchProjectsParams(tQuery)),
          ).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsSearchResults] with empty list when no results found',
        build: () {
          when(
            mockSearchProjects(any),
          ).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchProjectsEvent(query: tQuery)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectsSearchResults(results: [], query: tQuery),
        ],
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when searching projects fails',
        build: () {
          when(mockSearchProjects(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Search failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SearchProjectsEvent(query: tQuery)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Search failed'),
        ],
      );
    });

    group('GetProjectEvent', () {
      const tProjectId = 1;

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectLoaded] when getting project succeeds',
        build: () {
          when(mockGetProject(any)).thenAnswer((_) async => Right(tProject));
          return bloc;
        },
        act: (bloc) => bloc.add(const GetProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          ProjectLoaded(project: tProject),
        ],
        verify: (_) {
          verify(mockGetProject(const GetProjectParams(tProjectId))).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when getting project fails with NotFoundFailure',
        build: () {
          when(mockGetProject(any)).thenAnswer(
            (_) async => const Left(NotFoundFailure('Project not found')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const GetProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Project not found'),
        ],
        verify: (_) {
          verify(mockGetProject(const GetProjectParams(tProjectId))).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when getting project fails with DatabaseFailure',
        build: () {
          when(mockGetProject(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Query failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const GetProjectEvent(projectId: tProjectId)),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Query failed'),
        ],
      );
    });

    group('RefreshProjectsEvent', () {
      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsLoaded] when refreshing projects succeeds',
        build: () {
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => Right(tProjectList));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshProjectsEvent()),
        expect: () => [
          const ProjectsLoading(),
          ProjectsLoaded(projects: tProjectList),
        ],
        verify: (_) {
          verify(mockGetAllProjects(NoParams())).called(1);
        },
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectsEmpty] when refreshing returns no projects',
        build: () {
          when(
            mockGetAllProjects(any),
          ).thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshProjectsEvent()),
        expect: () => [const ProjectsLoading(), const ProjectsEmpty()],
      );

      blocTest<ProjectBloc, ProjectState>(
        'emits [ProjectsLoading, ProjectError] when refreshing fails',
        build: () {
          when(mockGetAllProjects(any)).thenAnswer(
            (_) async => const Left(DatabaseFailure('Refresh failed')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const RefreshProjectsEvent()),
        expect: () => [
          const ProjectsLoading(),
          const ProjectError(message: 'Refresh failed'),
        ],
      );
    });
  });
}
