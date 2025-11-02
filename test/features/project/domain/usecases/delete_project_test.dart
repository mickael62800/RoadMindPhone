import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/usecases/delete_project.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late DeleteProject useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = DeleteProject(repository);
  });

  group('DeleteProject', () {
    test('should delete project successfully', () async {
      // Create a project
      final createResult = await repository.createProject(title: 'Test');
      final project = createResult.getOrElse(() => throw Exception());

      // Delete it
      final params = DeleteProjectParams(project.id!);
      final result = await useCase(params);

      expect(result.isRight(), true);

      // Verify it's deleted
      final getResult = await repository.getProject(project.id!);
      expect(getResult.isLeft(), true);
    });

    test('should fail with NotFoundFailure for non-existent id', () async {
      const params = DeleteProjectParams(999);

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('999'));
      }, (_) => fail('Should fail'));
    });

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnDelete = true;

      const params = DeleteProjectParams(1);
      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('Should fail'),
      );
    });

    test('should delete correct project by id', () async {
      // Create multiple projects
      final r1 = await repository.createProject(title: 'Project 1');
      final r2 = await repository.createProject(title: 'Project 2');
      final r3 = await repository.createProject(title: 'Project 3');

      final p1 = r1.getOrElse(() => throw Exception());
      final p2 = r2.getOrElse(() => throw Exception());
      final p3 = r3.getOrElse(() => throw Exception());

      // Delete project 2
      final params = DeleteProjectParams(p2.id!);
      final result = await useCase(params);

      expect(result.isRight(), true);

      // Verify only project 2 is deleted
      final get1 = await repository.getProject(p1.id!);
      final get2 = await repository.getProject(p2.id!);
      final get3 = await repository.getProject(p3.id!);

      expect(get1.isRight(), true);
      expect(get2.isLeft(), true);
      expect(get3.isRight(), true);
    });

    test('should return void on success', () async {
      final createResult = await repository.createProject(title: 'Test');
      final project = createResult.getOrElse(() => throw Exception());

      final params = DeleteProjectParams(project.id!);
      final result = await useCase(params);

      expect(result.isRight(), true);
      // Void result, nothing to check
    });
  });

  group('DeleteProjectParams', () {
    test('should support value equality', () {
      const params1 = DeleteProjectParams(1);
      const params2 = DeleteProjectParams(1);

      expect(params1, equals(params2));
    });

    test('should not be equal when id differs', () {
      const params1 = DeleteProjectParams(1);
      const params2 = DeleteProjectParams(2);

      expect(params1, isNot(equals(params2)));
    });

    test('should include id in props', () {
      const params = DeleteProjectParams(42);

      expect(params.props.length, 1);
      expect(params.props, contains(42));
    });
  });
}
