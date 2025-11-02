import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/usecases/update_project.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late UpdateProject useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = UpdateProject(repository);
  });

  group('UpdateProject', () {
    test('should update project successfully', () async {
      // Create a project
      final createResult = await repository.createProject(title: 'Original');
      final original = createResult.getOrElse(() => throw Exception());

      // Update it
      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
      );
      final params = UpdateProjectParams(updated);

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.id, original.id);
        expect(project.title, 'Updated Title');
        expect(project.description, 'Updated Description');
        expect(project.updatedAt, isNotNull);
      });
    });

    test('should fail with NotFoundFailure for non-existent project', () async {
      final nonExistent = ProjectEntity(
        id: 999,
        title: 'Test',
        createdAt: DateTime.now(),
      );
      final params = UpdateProjectParams(nonExistent);

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, contains('999'));
      }, (project) => fail('Should fail'));
    });

    test('should fail with ValidationFailure for empty title', () async {
      final createResult = await repository.createProject(title: 'Test');
      final original = createResult.getOrElse(() => throw Exception());

      final updated = original.copyWith(title: '');
      final params = UpdateProjectParams(updated);

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (project) => fail('Should fail'),
      );
    });

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnUpdate = true;

      final project = ProjectEntity(
        id: 1,
        title: 'Test',
        createdAt: DateTime.now(),
      );
      final params = UpdateProjectParams(project);

      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (project) => fail('Should fail'),
      );
    });

    test('should preserve id when updating', () async {
      final createResult = await repository.createProject(title: 'Original');
      final original = createResult.getOrElse(() => throw Exception());

      final updated = original.copyWith(title: 'Updated');
      final params = UpdateProjectParams(updated);

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (project) => expect(project.id, original.id),
      );
    });

    test('should update multiple fields', () async {
      final createResult = await repository.createProject(
        title: 'Original',
        description: 'Original Description',
      );
      final original = createResult.getOrElse(() => throw Exception());

      final updated = original.copyWith(
        title: 'New Title',
        description: 'New Description',
        sessionCount: 5,
        duration: const Duration(hours: 2),
      );
      final params = UpdateProjectParams(updated);

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (project) {
        expect(project.title, 'New Title');
        expect(project.description, 'New Description');
        expect(project.sessionCount, 5);
        expect(project.duration, const Duration(hours: 2));
      });
    });
  });

  group('UpdateProjectParams', () {
    final tProject = ProjectEntity(
      id: 1,
      title: 'Test',
      createdAt: DateTime.now(),
    );

    test('should support value equality', () {
      final params1 = UpdateProjectParams(tProject);
      final params2 = UpdateProjectParams(tProject);

      expect(params1, equals(params2));
    });

    test('should not be equal when project differs', () {
      final project1 = ProjectEntity(
        id: 1,
        title: 'Project A',
        createdAt: DateTime.now(),
      );
      final project2 = ProjectEntity(
        id: 2,
        title: 'Project B',
        createdAt: DateTime.now(),
      );

      final params1 = UpdateProjectParams(project1);
      final params2 = UpdateProjectParams(project2);

      expect(params1, isNot(equals(params2)));
    });

    test('should include project in props', () {
      final params = UpdateProjectParams(tProject);

      expect(params.props.length, 1);
      expect(params.props, contains(tProject));
    });
  });
}
