import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_project.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late GetProject useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = GetProject(repository);
  });

  group('GetProject', () {
    test('should get project successfully', () async {
      // Create a project first
      await repository.createProject(title: 'Test Project');

      const params = GetProjectParams(1);
      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.id, 1);
        expect(project.title, 'Test Project');
      });
    });

    test('should fail with NotFoundFailure for non-existent id', () async {
      const params = GetProjectParams(999);

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('999'));
      }, (project) => fail('Should fail'));
    });

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnGet = true;

      const params = GetProjectParams(1);
      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (project) => fail('Should fail'),
      );
    });

    test('should pass correct id to repository', () async {
      // Create projects with specific ids
      await repository.createProject(title: 'Project 1');
      await repository.createProject(title: 'Project 2');

      const params = GetProjectParams(2);
      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.id, 2);
        expect(project.title, 'Project 2');
      });
    });
  });

  group('GetProjectParams', () {
    test('should support value equality', () {
      const params1 = GetProjectParams(1);
      const params2 = GetProjectParams(1);

      expect(params1, equals(params2));
    });

    test('should not be equal when id differs', () {
      const params1 = GetProjectParams(1);
      const params2 = GetProjectParams(2);

      expect(params1, isNot(equals(params2)));
    });

    test('should include id in props', () {
      const params = GetProjectParams(42);

      expect(params.props.length, 1);
      expect(params.props, contains(42));
    });
  });
}
