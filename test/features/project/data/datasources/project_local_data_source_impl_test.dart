import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:roadmindphone/core/error/exceptions.dart' as core_exceptions;
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source_impl.dart';
import 'package:roadmindphone/features/project/data/models/project_model.dart';
import 'package:sqflite/sqflite.dart';

import 'project_local_data_source_impl_test.mocks.dart';

// Generate mocks for DatabaseHelper and Database
@GenerateMocks([DatabaseHelper, Database])
void main() {
  late ProjectLocalDataSourceImpl dataSource;
  late MockDatabaseHelper mockDatabaseHelper;
  late MockDatabase mockDatabase;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    mockDatabase = MockDatabase();
    dataSource = ProjectLocalDataSourceImpl(databaseHelper: mockDatabaseHelper);

    // Default: return mockDatabase when database getter is called
    when(mockDatabaseHelper.database).thenAnswer((_) async => mockDatabase);
  });

  group('createProject', () {
    final tProjectModel = ProjectModel(
      id: null, // New project has no ID
      title: 'Test Project',
      description: 'Test Description',
      sessionCount: 0,
      duration: Duration.zero,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    final tInsertedId = 1;

    test(
      'should insert project into database and return with generated ID',
      () async {
        // arrange
        when(
          mockDatabase.insert(any, any),
        ).thenAnswer((_) async => tInsertedId);

        // act
        final result = await dataSource.createProject(tProjectModel);

        // assert
        verify(mockDatabase.insert('projects', tProjectModel.toMap()));
        expect(result.id, tInsertedId);
        expect(result.title, tProjectModel.title);
      },
    );

    test('should throw DatabaseException when insert fails', () async {
      // arrange
      when(mockDatabase.insert(any, any)).thenThrow(Exception('Insert failed'));

      // act
      final call = dataSource.createProject(tProjectModel);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('getProject', () {
    final tId = 1;
    final tProjectMap = {
      'id': 1,
      'title': 'Test Project',
      'description': 'Test Description',
      'session_count': 0,
      'duration': 0,
      'created_at': '2024-01-01T00:00:00.000',
      'updated_at': '2024-01-01T00:00:00.000',
    };

    test('should return ProjectModel when project is found', () async {
      // arrange
      when(
        mockDatabase.query(
          'projects',
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => [tProjectMap]);

      // Mock sessions query (empty sessions in this test)
      when(
        mockDatabase.query(
          'sessions',
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await dataSource.getProject(tId);

      // assert
      verify(mockDatabase.query('projects', where: 'id = ?', whereArgs: [tId]));
      expect(result, isA<ProjectModel>());
      expect(result.id, tId);
      expect(result.title, 'Test Project');
    });

    test('should throw DatabaseException when project is not found', () async {
      // arrange
      when(
        mockDatabase.query(
          'projects',
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      // act
      final call = dataSource.getProject(tId);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });

    test('should throw DatabaseException when query fails', () async {
      // arrange
      when(
        mockDatabase.query(
          'projects',
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(Exception('Query failed'));

      // act
      final call = dataSource.getProject(tId);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('getAllProjects', () {
    final tProjectsList = [
      {
        'id': 1,
        'title': 'Project 1',
        'description': 'Description 1',
        'session_count': 0,
        'duration': 0,
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      },
      {
        'id': 2,
        'title': 'Project 2',
        'description': 'Description 2',
        'session_count': 0,
        'duration': 0,
        'created_at': '2024-01-02T00:00:00.000',
        'updated_at': '2024-01-02T00:00:00.000',
      },
    ];

    test(
      'should return list of ProjectModels sorted by creation date',
      () async {
        // arrange
        when(
          mockDatabase.query('projects', orderBy: anyNamed('orderBy')),
        ).thenAnswer((_) async => tProjectsList);

        // Mock sessions query for each project (empty sessions in this test)
        when(
          mockDatabase.query(
            'sessions',
            where: anyNamed('where'),
            whereArgs: anyNamed('whereArgs'),
          ),
        ).thenAnswer((_) async => []);

        // act
        final result = await dataSource.getAllProjects();

        // assert
        verify(mockDatabase.query('projects', orderBy: 'created_at DESC'));
        expect(result, isA<List<ProjectModel>>());
        expect(result.length, 2);
        expect(result[0].id, 1);
        expect(result[1].id, 2);
      },
    );

    test('should return empty list when no projects exist', () async {
      // arrange
      when(
        mockDatabase.query('projects', orderBy: anyNamed('orderBy')),
      ).thenAnswer((_) async => []);

      // act
      final result = await dataSource.getAllProjects();

      // assert
      expect(result, isEmpty);
    });

    test('should throw DatabaseException when query fails', () async {
      // arrange
      when(
        mockDatabase.query('projects', orderBy: anyNamed('orderBy')),
      ).thenThrow(Exception('Query failed'));

      // act
      final call = dataSource.getAllProjects();

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('updateProject', () {
    final tProjectModel = ProjectModel(
      id: 1,
      title: 'Updated Project',
      description: 'Updated Description',
      sessionCount: 5,
      duration: const Duration(hours: 2),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should update project and return the updated model', () async {
      // arrange
      when(
        mockDatabase.update(
          any,
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 1); // 1 row affected

      // act
      final result = await dataSource.updateProject(tProjectModel);

      // assert
      verify(
        mockDatabase.update(
          'projects',
          tProjectModel.toMap(),
          where: 'id = ?',
          whereArgs: [tProjectModel.id],
        ),
      );
      expect(result, tProjectModel);
    });

    test('should throw DatabaseException when project not found', () async {
      // arrange
      when(
        mockDatabase.update(
          any,
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 0); // 0 rows affected

      // act
      final call = dataSource.updateProject(tProjectModel);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });

    test('should throw DatabaseException when update fails', () async {
      // arrange
      when(
        mockDatabase.update(
          any,
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(Exception('Update failed'));

      // act
      final call = dataSource.updateProject(tProjectModel);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('deleteProject', () {
    final tId = 1;

    test('should delete project from database', () async {
      // arrange
      when(
        mockDatabase.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 1); // 1 row affected

      // act
      await dataSource.deleteProject(tId);

      // assert
      verify(
        mockDatabase.delete('projects', where: 'id = ?', whereArgs: [tId]),
      );
    });

    test('should throw DatabaseException when project not found', () async {
      // arrange
      when(
        mockDatabase.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => 0); // 0 rows affected

      // act
      final call = dataSource.deleteProject(tId);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });

    test('should throw DatabaseException when delete fails', () async {
      // arrange
      when(
        mockDatabase.delete(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(Exception('Delete failed'));

      // act
      final call = dataSource.deleteProject(tId);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('getProjectsCount', () {
    test('should return correct count of projects', () async {
      // arrange
      when(mockDatabase.rawQuery(any)).thenAnswer(
        (_) async => [
          {'count': 5},
        ],
      );

      // act
      final result = await dataSource.getProjectsCount();

      // assert
      verify(mockDatabase.rawQuery('SELECT COUNT(*) as count FROM projects'));
      expect(result, 5);
    });

    test('should return 0 when no projects exist', () async {
      // arrange
      when(mockDatabase.rawQuery(any)).thenAnswer(
        (_) async => [
          {'count': 0},
        ],
      );

      // act
      final result = await dataSource.getProjectsCount();

      // assert
      expect(result, 0);
    });

    test('should throw DatabaseException when query fails', () async {
      // arrange
      when(mockDatabase.rawQuery(any)).thenThrow(Exception('Query failed'));

      // act
      final call = dataSource.getProjectsCount();

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('searchProjects', () {
    final tQuery = 'test';
    final tSearchResults = [
      {
        'id': 1,
        'title': 'Test Project',
        'description': 'Description',
        'session_count': 0,
        'duration': 0,
        'created_at': '2024-01-01T00:00:00.000',
        'updated_at': '2024-01-01T00:00:00.000',
      },
    ];

    test('should return projects matching search query', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => tSearchResults);

      // act
      final result = await dataSource.searchProjects(tQuery);

      // assert
      verify(
        mockDatabase.query(
          'projects',
          where: 'LOWER(title) LIKE ?',
          whereArgs: ['%${tQuery.toLowerCase()}%'],
          orderBy: 'created_at DESC',
        ),
      );
      expect(result, isA<List<ProjectModel>>());
      expect(result.length, 1);
      expect(result[0].title, 'Test Project');
    });

    test('should return empty list when no matches found', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await dataSource.searchProjects(tQuery);

      // assert
      expect(result, isEmpty);
    });

    test('should handle case-insensitive search correctly', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenAnswer((_) async => tSearchResults);

      // act
      await dataSource.searchProjects('TEST'); // Uppercase query

      // assert
      verify(
        mockDatabase.query(
          'projects',
          where: 'LOWER(title) LIKE ?',
          whereArgs: ['%test%'], // Lowercase in query
          orderBy: 'created_at DESC',
        ),
      );
    });

    test('should throw DatabaseException when search fails', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
          orderBy: anyNamed('orderBy'),
        ),
      ).thenThrow(Exception('Search failed'));

      // act
      final call = dataSource.searchProjects(tQuery);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });

  group('projectExists', () {
    final tId = 1;

    test('should return true when project exists', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer(
        (_) async => [
          {'id': tId},
        ],
      );

      // act
      final result = await dataSource.projectExists(tId);

      // assert
      verify(mockDatabase.query('projects', where: 'id = ?', whereArgs: [tId]));
      expect(result, true);
    });

    test('should return false when project does not exist', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenAnswer((_) async => []);

      // act
      final result = await dataSource.projectExists(tId);

      // assert
      expect(result, false);
    });

    test('should throw DatabaseException when query fails', () async {
      // arrange
      when(
        mockDatabase.query(
          any,
          where: anyNamed('where'),
          whereArgs: anyNamed('whereArgs'),
        ),
      ).thenThrow(Exception('Query failed'));

      // act
      final call = dataSource.projectExists(tId);

      // assert
      expect(() => call, throwsA(isA<core_exceptions.DatabaseException>()));
    });
  });
}
