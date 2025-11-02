import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
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
    ProjectEntity project,
  ) async {
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
    String query,
  ) async {
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

void main() {
  group('ProjectRepository Interface', () {
    late MockProjectRepository repository;

    setUp(() {
      repository = MockProjectRepository();
    });

    group('createProject', () {
      test('should create project successfully', () async {
        final result = await repository.createProject(
          title: 'Test Project',
          description: 'Test Description',
        );

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (project) {
          expect(project.id, isNotNull);
          expect(project.title, 'Test Project');
          expect(project.description, 'Test Description');
          expect(project.sessionCount, 0);
          expect(project.createdAt, isNotNull);
        });
      });

      test('should create project without description', () async {
        final result = await repository.createProject(title: 'Simple Project');

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (project) {
          expect(project.title, 'Simple Project');
          expect(project.description, isNull);
        });
      });

      test('should fail with ValidationFailure for empty title', () async {
        final result = await repository.createProject(title: '');

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, 'Title cannot be empty');
        }, (project) => fail('Should fail'));
      });

      test(
        'should fail with ValidationFailure for whitespace-only title',
        () async {
          final result = await repository.createProject(title: '   ');

          expect(result.isLeft(), true);
          result.fold(
            (failure) => expect(failure, isA<ValidationFailure>()),
            (project) => fail('Should fail'),
          );
        },
      );

      test('should fail when shouldFailOnCreate is true', () async {
        repository.shouldFailOnCreate = true;

        final result = await repository.createProject(title: 'Test');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (project) => fail('Should fail'),
        );
      });
    });

    group('getProject', () {
      test('should get project by id successfully', () async {
        // Create a project first
        final createResult = await repository.createProject(
          title: 'Test Project',
          description: 'Description',
        );

        final projectId = createResult.getOrElse(() => throw Exception());

        // Get the project
        final result = await repository.getProject(projectId.id!);

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (project) {
          expect(project.id, projectId.id);
          expect(project.title, 'Test Project');
          expect(project.description, 'Description');
        });
      });

      test('should fail with NotFoundFailure for non-existent id', () async {
        final result = await repository.getProject(999);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<NotFoundFailure>());
          expect(failure.message, contains('999'));
        }, (project) => fail('Should fail'));
      });

      test('should fail when shouldFailOnGet is true', () async {
        repository.shouldFailOnGet = true;

        final result = await repository.getProject(1);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (project) => fail('Should fail'),
        );
      });
    });

    group('getAllProjects', () {
      test('should return empty list when no projects exist', () async {
        final result = await repository.getAllProjects();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (projects) => expect(projects, isEmpty),
        );
      });

      test('should return all projects ordered by creation date', () async {
        // Create multiple projects
        await repository.createProject(title: 'Project 1');
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.createProject(title: 'Project 2');
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.createProject(title: 'Project 3');

        final result = await repository.getAllProjects();

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (projects) {
          expect(projects.length, 3);
          // Should be ordered newest first
          expect(projects[0].title, 'Project 3');
          expect(projects[1].title, 'Project 2');
          expect(projects[2].title, 'Project 1');
        });
      });

      test('should fail when shouldFailOnGetAll is true', () async {
        repository.shouldFailOnGetAll = true;

        final result = await repository.getAllProjects();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (projects) => fail('Should fail'),
        );
      });
    });

    group('updateProject', () {
      test('should update project successfully', () async {
        // Create a project
        final createResult = await repository.createProject(
          title: 'Original Title',
          description: 'Original Description',
        );

        final original = createResult.getOrElse(() => throw Exception());

        // Update the project
        final updated = original.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
        );

        final result = await repository.updateProject(updated);

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (project) {
          expect(project.id, original.id);
          expect(project.title, 'Updated Title');
          expect(project.description, 'Updated Description');
          expect(project.updatedAt, isNotNull);
        });
      });

      test(
        'should fail with NotFoundFailure for non-existent project',
        () async {
          final nonExistent = ProjectEntity(
            id: 999,
            title: 'Test',
            createdAt: DateTime.now(),
          );

          final result = await repository.updateProject(nonExistent);

          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<NotFoundFailure>());
            expect(failure.message, contains('999'));
          }, (project) => fail('Should fail'));
        },
      );

      test('should fail with ValidationFailure for empty title', () async {
        // Create a project
        final createResult = await repository.createProject(title: 'Test');
        final original = createResult.getOrElse(() => throw Exception());

        // Try to update with empty title
        final updated = original.copyWith(title: '');

        final result = await repository.updateProject(updated);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (project) => fail('Should fail'),
        );
      });

      test('should fail when shouldFailOnUpdate is true', () async {
        repository.shouldFailOnUpdate = true;

        final project = ProjectEntity(
          id: 1,
          title: 'Test',
          createdAt: DateTime.now(),
        );

        final result = await repository.updateProject(project);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (project) => fail('Should fail'),
        );
      });
    });

    group('deleteProject', () {
      test('should delete project successfully', () async {
        // Create a project
        final createResult = await repository.createProject(title: 'Test');
        final project = createResult.getOrElse(() => throw Exception());

        // Delete it
        final result = await repository.deleteProject(project.id!);

        expect(result.isRight(), true);

        // Verify it's deleted
        final getResult = await repository.getProject(project.id!);
        expect(getResult.isLeft(), true);
      });

      test('should fail with NotFoundFailure for non-existent id', () async {
        final result = await repository.deleteProject(999);

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<NotFoundFailure>());
          expect(failure.message, contains('999'));
        }, (_) => fail('Should fail'));
      });

      test('should fail when shouldFailOnDelete is true', () async {
        repository.shouldFailOnDelete = true;

        final result = await repository.deleteProject(1);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (_) => fail('Should fail'),
        );
      });
    });

    group('getProjectsCount', () {
      test('should return 0 when no projects exist', () async {
        final result = await repository.getProjectsCount();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (count) => expect(count, 0),
        );
      });

      test('should return correct count', () async {
        await repository.createProject(title: 'Project 1');
        await repository.createProject(title: 'Project 2');
        await repository.createProject(title: 'Project 3');

        final result = await repository.getProjectsCount();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (count) => expect(count, 3),
        );
      });

      test('should update count after deletion', () async {
        final p1 = await repository.createProject(title: 'Project 1');
        await repository.createProject(title: 'Project 2');

        final project1 = p1.getOrElse(() => throw Exception());
        await repository.deleteProject(project1.id!);

        final result = await repository.getProjectsCount();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (count) => expect(count, 1),
        );
      });

      test('should fail when shouldFailOnCount is true', () async {
        repository.shouldFailOnCount = true;

        final result = await repository.getProjectsCount();

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (count) => fail('Should fail'),
        );
      });
    });

    group('searchProjects', () {
      setUp(() async {
        await repository.createProject(
          title: 'Flutter Project',
          description: 'Mobile app development',
        );
        await repository.createProject(
          title: 'React Project',
          description: 'Web application',
        );
        await repository.createProject(
          title: 'Angular App',
          description: 'Another web framework',
        );
      });

      test('should find projects by title', () async {
        final result = await repository.searchProjects('Flutter');

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (projects) {
          expect(projects.length, 1);
          expect(projects[0].title, 'Flutter Project');
        });
      });

      test('should find projects by description', () async {
        final result = await repository.searchProjects('web');

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (projects) {
          expect(projects.length, 2);
        });
      });

      test('should be case-insensitive', () async {
        final result = await repository.searchProjects('FLUTTER');

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (projects) {
          expect(projects.length, 1);
          expect(projects[0].title, 'Flutter Project');
        });
      });

      test('should return empty list for no matches', () async {
        final result = await repository.searchProjects('Python');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (projects) => expect(projects, isEmpty),
        );
      });

      test('should fail when shouldFailOnSearch is true', () async {
        repository.shouldFailOnSearch = true;

        final result = await repository.searchProjects('test');

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (projects) => fail('Should fail'),
        );
      });
    });

    group('projectExists', () {
      test('should return true for existing project', () async {
        final createResult = await repository.createProject(title: 'Test');
        final project = createResult.getOrElse(() => throw Exception());

        final result = await repository.projectExists(project.id!);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (exists) => expect(exists, true),
        );
      });

      test('should return false for non-existent project', () async {
        final result = await repository.projectExists(999);

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should not fail'),
          (exists) => expect(exists, false),
        );
      });

      test('should fail when shouldFailOnExists is true', () async {
        repository.shouldFailOnExists = true;

        final result = await repository.projectExists(1);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<DatabaseFailure>()),
          (exists) => fail('Should fail'),
        );
      });
    });

    group('integration scenarios', () {
      test('should handle complete CRUD cycle', () async {
        // Create
        final createResult = await repository.createProject(
          title: 'Test Project',
          description: 'Test Description',
        );
        expect(createResult.isRight(), true);

        final project = createResult.getOrElse(() => throw Exception());

        // Read
        final getResult = await repository.getProject(project.id!);
        expect(getResult.isRight(), true);

        // Update
        final updated = project.copyWith(title: 'Updated Title');
        final updateResult = await repository.updateProject(updated);
        expect(updateResult.isRight(), true);

        // Delete
        final deleteResult = await repository.deleteProject(project.id!);
        expect(deleteResult.isRight(), true);

        // Verify deletion
        final verifyResult = await repository.getProject(project.id!);
        expect(verifyResult.isLeft(), true);
      });

      test('should handle multiple projects correctly', () async {
        // Create multiple projects
        await repository.createProject(title: 'Project 1');
        await repository.createProject(title: 'Project 2');
        await repository.createProject(title: 'Project 3');

        // Get all
        final allResult = await repository.getAllProjects();
        expect(allResult.isRight(), true);
        allResult.fold(
          (failure) => fail('Should not fail'),
          (projects) => expect(projects.length, 3),
        );

        // Count
        final countResult = await repository.getProjectsCount();
        expect(countResult.isRight(), true);
        countResult.fold(
          (failure) => fail('Should not fail'),
          (count) => expect(count, 3),
        );
      });
    });
  });
}
