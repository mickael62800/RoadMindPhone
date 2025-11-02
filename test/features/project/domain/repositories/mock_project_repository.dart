import 'package:dartz/dartz.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Mock implementation of ProjectRepository for testing
class MockProjectRepository implements ProjectRepository {
  // Storage for testing
  final Map<int, ProjectEntity> _projects = {};
  int _nextId = 1;

  // Flags to simulate failures
  bool shouldFailOnCreate = false;
  bool shouldFailOnGet = false;
  bool shouldFailOnGetAll = false;
  bool shouldFailOnUpdate = false;
  bool shouldFailOnDelete = false;
  bool shouldFailOnCount = false;
  bool shouldFailOnSearch = false;
  bool shouldFailOnExists = false;

  // Failure types to return
  Failure? failureToReturn;

  @override
  Future<Either<Failure, ProjectEntity>> createProject({
    required String title,
    String? description,
  }) async {
    if (shouldFailOnCreate) {
      return Left(failureToReturn ?? const DatabaseFailure('Create failed'));
    }

    if (title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }

    final project = ProjectEntity(
      id: _nextId++,
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    _projects[project.id!] = project;
    return Right(project);
  }

  @override
  Future<Either<Failure, ProjectEntity>> getProject(int id) async {
    if (shouldFailOnGet) {
      return Left(failureToReturn ?? const DatabaseFailure('Get failed'));
    }

    final project = _projects[id];
    if (project == null) {
      return Left(NotFoundFailure('Project with id $id not found'));
    }

    return Right(project);
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> getAllProjects() async {
    if (shouldFailOnGetAll) {
      return Left(failureToReturn ?? const DatabaseFailure('GetAll failed'));
    }

    final projects = _projects.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(projects);
  }

  @override
  Future<Either<Failure, ProjectEntity>> updateProject(
      ProjectEntity project) async {
    if (shouldFailOnUpdate) {
      return Left(failureToReturn ?? const DatabaseFailure('Update failed'));
    }

    if (project.id == null || !_projects.containsKey(project.id)) {
      return Left(NotFoundFailure('Project with id ${project.id} not found'));
    }

    if (project.title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }

    final updated = project.copyWith(updatedAt: DateTime.now());
    _projects[project.id!] = updated;
    return Right(updated);
  }

  @override
  Future<Either<Failure, void>> deleteProject(int id) async {
    if (shouldFailOnDelete) {
      return Left(failureToReturn ?? const DatabaseFailure('Delete failed'));
    }

    if (!_projects.containsKey(id)) {
      return Left(NotFoundFailure('Project with id $id not found'));
    }

    _projects.remove(id);
    return const Right(null);
  }

  @override
  Future<Either<Failure, int>> getProjectsCount() async {
    if (shouldFailOnCount) {
      return Left(failureToReturn ?? const DatabaseFailure('Count failed'));
    }

    return Right(_projects.length);
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> searchProjects(
      String query) async {
    if (shouldFailOnSearch) {
      return Left(failureToReturn ?? const DatabaseFailure('Search failed'));
    }

    final lowerQuery = query.toLowerCase();
    final results = _projects.values.where((project) {
      final titleMatch = project.title.toLowerCase().contains(lowerQuery);
      final descriptionMatch =
          project.description?.toLowerCase().contains(lowerQuery) ?? false;
      return titleMatch || descriptionMatch;
    }).toList();

    return Right(results);
  }

  @override
  Future<Either<Failure, bool>> projectExists(int id) async {
    if (shouldFailOnExists) {
      return Left(failureToReturn ?? const DatabaseFailure('Exists failed'));
    }

    return Right(_projects.containsKey(id));
  }

  // Helper methods for testing
  void reset() {
    _projects.clear();
    _nextId = 1;
    shouldFailOnCreate = false;
    shouldFailOnGet = false;
    shouldFailOnGetAll = false;
    shouldFailOnUpdate = false;
    shouldFailOnDelete = false;
    shouldFailOnCount = false;
    shouldFailOnSearch = false;
    shouldFailOnExists = false;
    failureToReturn = null;
  }

  void addProject(ProjectEntity project) {
    _projects[project.id!] = project;
    if (project.id! >= _nextId) {
      _nextId = project.id! + 1;
    }
  }
}
