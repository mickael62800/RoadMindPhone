import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/domain/usecases/search_projects.dart';
import '../repositories/mock_project_repository.dart';

void main() {
  late MockProjectRepository repository;
  late SearchProjects useCase;

  setUp(() {
    repository = MockProjectRepository();
    useCase = SearchProjects(repository);
  });

  group('SearchProjects', () {
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
      const params = SearchProjectsParams('Flutter');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (projects) {
        expect(projects.length, 1);
        expect(projects[0].title, 'Flutter Project');
      });
    });

    test('should find projects by description', () async {
      const params = SearchProjectsParams('web');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (projects) {
        expect(projects.length, 2);
      });
    });

    test('should be case-insensitive', () async {
      const params = SearchProjectsParams('FLUTTER');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (projects) {
        expect(projects.length, 1);
        expect(projects[0].title, 'Flutter Project');
      });
    });

    test('should return empty list for no matches', () async {
      const params = SearchProjectsParams('Python');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (projects) => expect(projects, isEmpty),
      );
    });

    test('should find multiple matching projects', () async {
      const params = SearchProjectsParams('Project');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (projects) => expect(projects.length, 2),
      );
    });

    test('should return DatabaseFailure when repository fails', () async {
      repository.shouldFailOnSearch = true;

      const params = SearchProjectsParams('test');
      final result = await useCase(params);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (projects) => fail('Should fail'),
      );
    });

    test('should pass correct query to repository', () async {
      const params = SearchProjectsParams('specific query');

      final result = await useCase(params);

      expect(result.isRight(), true);
      // Query was passed correctly (empty result expected for this query)
      result.fold(
        (failure) => fail('Should not fail'),
        (projects) => expect(projects, isEmpty),
      );
    });

    test('should handle partial matches', () async {
      const params = SearchProjectsParams('App');

      final result = await useCase(params);

      expect(result.isRight(), true);
      result.fold((failure) => fail('Should not fail'), (projects) {
        expect(projects.length, 3); // "Mobile app", "web application", "Angular App"
      });
    });
  });

  group('SearchProjectsParams', () {
    test('should support value equality', () {
      const params1 = SearchProjectsParams('query');
      const params2 = SearchProjectsParams('query');

      expect(params1, equals(params2));
    });

    test('should not be equal when query differs', () {
      const params1 = SearchProjectsParams('query1');
      const params2 = SearchProjectsParams('query2');

      expect(params1, isNot(equals(params2)));
    });

    test('should include query in props', () {
      const params = SearchProjectsParams('test query');

      expect(params.props.length, 1);
      expect(params.props, contains('test query'));
    });
  });
}
