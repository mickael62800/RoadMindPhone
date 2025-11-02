import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/usecases/create_project.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late CreateProject useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = CreateProject(repository);
  });

  final tParams = const CreateProjectParams(
    title: 'Test Project',
    description: 'Test Description',
  );

  group('CreateProject', () {
    test('should create project successfully', () async {
      final result = await useCase(tParams);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.title, tParams.title);
        expect(project.description, tParams.description);
        expect(project.id, isNotNull);
        expect(project.sessionCount, 0);
      });
    });

    test('should create project without description', () async {
      const params = CreateProjectParams(title: 'Simple Project');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.title, 'Simple Project');
        expect(project.description, isNull);
      });
    });

    test('should fail with ValidationFailure for empty title', () async {
      const params = CreateProjectParams(title: '');

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Title cannot be empty');
      }, (project) => fail('Should fail'));
    });

    test(
      'should fail with ValidationFailure for whitespace-only title',
      () async {
        const params = CreateProjectParams(title: '   ');

        final result = await useCase(params);

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (project) => fail('Should fail'),
        );
      },
    );

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnCreate = true;

      final result = await useCase(tParams);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (project) => fail('Should fail'),
      );
    });

    test('should pass correct parameters to repository', () async {
      const params = CreateProjectParams(
        title: 'My Project',
        description: 'My Description',
      );

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.title, 'My Project');
        expect(project.description, 'My Description');
      });
    });
  });

  group('CreateProjectParams', () {
    test('should support value equality', () {
      const params1 = CreateProjectParams(
        title: 'Project',
        description: 'Description',
      );
      const params2 = CreateProjectParams(
        title: 'Project',
        description: 'Description',
      );

      expect(params1, equals(params2));
    });

    test('should not be equal when title differs', () {
      const params1 = CreateProjectParams(title: 'Project A');
      const params2 = CreateProjectParams(title: 'Project B');

      expect(params1, isNot(equals(params2)));
    });

    test('should not be equal when description differs', () {
      const params1 = CreateProjectParams(
        title: 'Project',
        description: 'Description A',
      );
      const params2 = CreateProjectParams(
        title: 'Project',
        description: 'Description B',
      );

      expect(params1, isNot(equals(params2)));
    });

    test('should include all fields in props', () {
      const params = CreateProjectParams(
        title: 'Project',
        description: 'Description',
      );

      expect(params.props.length, 2);
      expect(params.props, contains('Project'));
      expect(params.props, contains('Description'));
    });
  });
}
