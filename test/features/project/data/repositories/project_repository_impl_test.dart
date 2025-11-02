import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/core/error/exceptions.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source.dart';
import 'package:roadmindphone/features/project/data/models/project_model.dart';
import 'package:roadmindphone/features/project/data/repositories/project_repository_impl.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

import 'project_repository_impl_test.mocks.dart';

// Generate mock for ProjectLocalDataSource
@GenerateMocks([ProjectLocalDataSource])
void main() {
  late ProjectRepositoryImpl repository;
  late MockProjectLocalDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProjectLocalDataSource();
    repository = ProjectRepositoryImpl(localDataSource: mockDataSource);
  });

  group('createProject', () {
    const tTitle = 'Test Project';
    const tDescription = 'Test Description';
    final tProjectModel = ProjectModel(
      id: 1,
      title: tTitle,
      description: tDescription,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return ProjectEntity when creation is successful', () async {
      // arrange
      when(
        mockDataSource.createProject(any),
      ).thenAnswer((_) async => tProjectModel);

      // act
      final result = await repository.createProject(
        title: tTitle,
        description: tDescription,
      );

      // assert
      expect(result, isA<Right<Failure, ProjectEntity>>());
      result.fold((failure) => fail('Should not return failure'), (entity) {
        expect(entity.id, 1);
        expect(entity.title, tTitle);
        expect(entity.description, tDescription);
      });
      verify(mockDataSource.createProject(any)).called(1);
    });

    test(
      'should return DatabaseFailure when DatabaseException is thrown',
      () async {
        // arrange
        when(
          mockDataSource.createProject(any),
        ).thenThrow(const DatabaseException('Database error'));

        // act
        final result = await repository.createProject(
          title: tTitle,
          description: tDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ProjectEntity>>());
        result.fold((failure) {
          expect(failure, isA<DatabaseFailure>());
          expect(failure.message, 'Database error');
        }, (entity) => fail('Should not return entity'));
      },
    );

    test(
      'should return UnexpectedFailure when unknown Exception is thrown',
      () async {
        // arrange
        when(
          mockDataSource.createProject(any),
        ).thenThrow(Exception('Unknown error'));

        // act
        final result = await repository.createProject(
          title: tTitle,
          description: tDescription,
        );

        // assert
        expect(result, isA<Left<Failure, ProjectEntity>>());
        result.fold((failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, contains('Unknown error'));
        }, (entity) => fail('Should not return entity'));
      },
    );
  });

  group('getProject', () {
    const tId = 1;
    final tProjectModel = ProjectModel(
      id: tId,
      title: 'Test Project',
      description: 'Description',
      createdAt: DateTime(2024, 1, 1),
    );

    test('should return ProjectEntity when project is found', () async {
      // arrange
      when(
        mockDataSource.getProject(tId),
      ).thenAnswer((_) async => tProjectModel);

      // act
      final result = await repository.getProject(tId);

      // assert
      expect(result, isA<Right<Failure, ProjectEntity>>());
      result.fold((failure) => fail('Should not return failure'), (entity) {
        expect(entity.id, tId);
        expect(entity.title, 'Test Project');
      });
      verify(mockDataSource.getProject(tId)).called(1);
    });

    test('should return NotFoundFailure when project is not found', () async {
      // arrange
      when(
        mockDataSource.getProject(tId),
      ).thenThrow(const DatabaseException('Project not found with id: 1'));

      // act
      final result = await repository.getProject(tId);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('not found'));
      }, (entity) => fail('Should not return entity'));
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.getProject(tId),
      ).thenThrow(const DatabaseException('Database query failed'));

      // act
      final result = await repository.getProject(tId);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Database query failed');
      }, (entity) => fail('Should not return entity'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.getProject(tId)).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.getProject(tId);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (entity) => fail('Should not return entity'),
      );
    });
  });

  group('getAllProjects', () {
    final tProjectsList = [
      ProjectModel(id: 1, title: 'Project 1', createdAt: DateTime(2024, 1, 1)),
      ProjectModel(id: 2, title: 'Project 2', createdAt: DateTime(2024, 1, 2)),
    ];

    test('should return list of ProjectEntities when successful', () async {
      // arrange
      when(
        mockDataSource.getAllProjects(),
      ).thenAnswer((_) async => tProjectsList);

      // act
      final result = await repository.getAllProjects();

      // assert
      expect(result, isA<Right<Failure, List<ProjectEntity>>>());
      result.fold((failure) => fail('Should not return failure'), (entities) {
        expect(entities.length, 2);
        expect(entities[0].id, 1);
        expect(entities[1].id, 2);
      });
      verify(mockDataSource.getAllProjects()).called(1);
    });

    test('should return empty list when no projects exist', () async {
      // arrange
      when(mockDataSource.getAllProjects()).thenAnswer((_) async => []);

      // act
      final result = await repository.getAllProjects();

      // assert
      expect(result, isA<Right<Failure, List<ProjectEntity>>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (entities) => expect(entities, isEmpty),
      );
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.getAllProjects(),
      ).thenThrow(const DatabaseException('Query failed'));

      // act
      final result = await repository.getAllProjects();

      // assert
      expect(result, isA<Left<Failure, List<ProjectEntity>>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Query failed');
      }, (entities) => fail('Should not return entities'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.getAllProjects()).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.getAllProjects();

      // assert
      expect(result, isA<Left<Failure, List<ProjectEntity>>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (entities) => fail('Should not return entities'),
      );
    });
  });

  group('updateProject', () {
    final tProjectEntity = ProjectEntity(
      id: 1,
      title: 'Updated Project',
      description: 'Updated Description',
      sessionCount: 5,
      duration: const Duration(hours: 2),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    final tProjectModel = ProjectModel.fromEntity(tProjectEntity);

    test('should return updated ProjectEntity when successful', () async {
      // arrange
      when(
        mockDataSource.updateProject(any),
      ).thenAnswer((_) async => tProjectModel);

      // act
      final result = await repository.updateProject(tProjectEntity);

      // assert
      expect(result, isA<Right<Failure, ProjectEntity>>());
      result.fold((failure) => fail('Should not return failure'), (entity) {
        expect(entity.id, 1);
        expect(entity.title, 'Updated Project');
      });
      verify(mockDataSource.updateProject(any)).called(1);
    });

    test('should return NotFoundFailure when project does not exist', () async {
      // arrange
      when(
        mockDataSource.updateProject(any),
      ).thenThrow(const DatabaseException('Project not found with id: 1'));

      // act
      final result = await repository.updateProject(tProjectEntity);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('not found'));
      }, (entity) => fail('Should not return entity'));
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.updateProject(any),
      ).thenThrow(const DatabaseException('Update failed'));

      // act
      final result = await repository.updateProject(tProjectEntity);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Update failed');
      }, (entity) => fail('Should not return entity'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.updateProject(any)).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.updateProject(tProjectEntity);

      // assert
      expect(result, isA<Left<Failure, ProjectEntity>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (entity) => fail('Should not return entity'),
      );
    });
  });

  group('deleteProject', () {
    const tId = 1;

    test('should return Right(null) when deletion is successful', () async {
      // arrange
      when(mockDataSource.deleteProject(tId)).thenAnswer((_) async => {});

      // act
      final result = await repository.deleteProject(tId);

      // assert
      expect(result, isA<Right<Failure, void>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (_) {}, // void return, nothing to assert
      );
      verify(mockDataSource.deleteProject(tId)).called(1);
    });

    test('should return NotFoundFailure when project does not exist', () async {
      // arrange
      when(
        mockDataSource.deleteProject(tId),
      ).thenThrow(const DatabaseException('Project not found with id: 1'));

      // act
      final result = await repository.deleteProject(tId);

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('not found'));
      }, (value) => fail('Should not return value'));
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.deleteProject(tId),
      ).thenThrow(const DatabaseException('Delete failed'));

      // act
      final result = await repository.deleteProject(tId);

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Delete failed');
      }, (value) => fail('Should not return value'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.deleteProject(tId)).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.deleteProject(tId);

      // assert
      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (value) => fail('Should not return value'),
      );
    });
  });

  group('getProjectsCount', () {
    const tCount = 5;

    test('should return count when successful', () async {
      // arrange
      when(mockDataSource.getProjectsCount()).thenAnswer((_) async => tCount);

      // act
      final result = await repository.getProjectsCount();

      // assert
      expect(result, isA<Right<Failure, int>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (count) => expect(count, tCount),
      );
      verify(mockDataSource.getProjectsCount()).called(1);
    });

    test('should return 0 when no projects exist', () async {
      // arrange
      when(mockDataSource.getProjectsCount()).thenAnswer((_) async => 0);

      // act
      final result = await repository.getProjectsCount();

      // assert
      expect(result, isA<Right<Failure, int>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (count) => expect(count, 0),
      );
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.getProjectsCount(),
      ).thenThrow(const DatabaseException('Count failed'));

      // act
      final result = await repository.getProjectsCount();

      // assert
      expect(result, isA<Left<Failure, int>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Count failed');
      }, (count) => fail('Should not return count'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.getProjectsCount()).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.getProjectsCount();

      // assert
      expect(result, isA<Left<Failure, int>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (count) => fail('Should not return count'),
      );
    });
  });

  group('searchProjects', () {
    const tQuery = 'test';
    final tSearchResults = [
      ProjectModel(
        id: 1,
        title: 'Test Project',
        createdAt: DateTime(2024, 1, 1),
      ),
    ];

    test(
      'should return list of matching ProjectEntities when successful',
      () async {
        // arrange
        when(
          mockDataSource.searchProjects(tQuery),
        ).thenAnswer((_) async => tSearchResults);

        // act
        final result = await repository.searchProjects(tQuery);

        // assert
        expect(result, isA<Right<Failure, List<ProjectEntity>>>());
        result.fold((failure) => fail('Should not return failure'), (entities) {
          expect(entities.length, 1);
          expect(entities[0].title, 'Test Project');
        });
        verify(mockDataSource.searchProjects(tQuery)).called(1);
      },
    );

    test('should return empty list when no matches found', () async {
      // arrange
      when(mockDataSource.searchProjects(tQuery)).thenAnswer((_) async => []);

      // act
      final result = await repository.searchProjects(tQuery);

      // assert
      expect(result, isA<Right<Failure, List<ProjectEntity>>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (entities) => expect(entities, isEmpty),
      );
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.searchProjects(tQuery),
      ).thenThrow(const DatabaseException('Search failed'));

      // act
      final result = await repository.searchProjects(tQuery);

      // assert
      expect(result, isA<Left<Failure, List<ProjectEntity>>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Search failed');
      }, (entities) => fail('Should not return entities'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(
        mockDataSource.searchProjects(tQuery),
      ).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.searchProjects(tQuery);

      // assert
      expect(result, isA<Left<Failure, List<ProjectEntity>>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (entities) => fail('Should not return entities'),
      );
    });
  });

  group('projectExists', () {
    const tId = 1;

    test('should return true when project exists', () async {
      // arrange
      when(mockDataSource.projectExists(tId)).thenAnswer((_) async => true);

      // act
      final result = await repository.projectExists(tId);

      // assert
      expect(result, isA<Right<Failure, bool>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (exists) => expect(exists, true),
      );
      verify(mockDataSource.projectExists(tId)).called(1);
    });

    test('should return false when project does not exist', () async {
      // arrange
      when(mockDataSource.projectExists(tId)).thenAnswer((_) async => false);

      // act
      final result = await repository.projectExists(tId);

      // assert
      expect(result, isA<Right<Failure, bool>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (exists) => expect(exists, false),
      );
    });

    test('should return DatabaseFailure when database error occurs', () async {
      // arrange
      when(
        mockDataSource.projectExists(tId),
      ).thenThrow(const DatabaseException('Check failed'));

      // act
      final result = await repository.projectExists(tId);

      // assert
      expect(result, isA<Left<Failure, bool>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Check failed');
      }, (exists) => fail('Should not return value'));
    });

    test('should return UnexpectedFailure when unknown error occurs', () async {
      // arrange
      when(mockDataSource.projectExists(tId)).thenThrow(Exception('Unknown'));

      // act
      final result = await repository.projectExists(tId);

      // assert
      expect(result, isA<Left<Failure, bool>>());
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (exists) => fail('Should not return value'),
      );
    });
  });
}
