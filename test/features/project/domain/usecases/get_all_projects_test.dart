import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_all_projects.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late GetAllProjects useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = GetAllProjects(repository);
  });

  group('GetAllProjects', () {
    test('should return empty list when no projects exist', () async {
      final result = await useCase(NoParams());

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (projects) => expect(projects, isEmpty),
      );
    });

    test('should return all projects', () async {
      await repository.createProject(title: 'Project 1');
      await repository.createProject(title: 'Project 2');
      await repository.createProject(title: 'Project 3');

      final result = await useCase(NoParams());

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (projects) {
        expect(projects.length, 3);
        expect(projects[0].title, 'Project 3'); // Newest first
        expect(projects[1].title, 'Project 2');
        expect(projects[2].title, 'Project 1');
      });
    });

    test(
      'should return projects ordered by creation date (newest first)',
      () async {
        await repository.createProject(title: 'Old Project');
        await Future.delayed(const Duration(milliseconds: 10));
        await repository.createProject(title: 'Recent Project');

        final result = await useCase(NoParams());

        expect(result.isRight(), true);
        result.fold((failure) => fail('Should not fail'), (projects) {
          expect(projects.length, 2);
          expect(projects[0].title, 'Recent Project');
          expect(projects[1].title, 'Old Project');
        });
      },
    );

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnGetAll = true;

      final result = await useCase(NoParams());

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (projects) => fail('Should fail'),
      );
    });

    test('should work with NoParams', () async {
      await repository.createProject(title: 'Test');

      final result = await useCase(NoParams());

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (projects) => expect(projects, isNotEmpty),
      );
    });
  });
}
