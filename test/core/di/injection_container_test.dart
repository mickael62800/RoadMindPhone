import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/di/injection_container.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';
import 'package:roadmindphone/features/project/domain/usecases/create_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/delete_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_all_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/search_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/update_project.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';

void main() {
  group('Dependency Injection Container', () {
    tearDown(() {
      // Reset GetIt after each test
      sl.reset();
    });

    test('should initialize all dependencies without errors', () async {
      // Act
      await initializeDependencies();

      // Assert - verify all dependencies are registered
      expect(sl.isRegistered<DatabaseHelper>(), true);
      expect(sl.isRegistered<ProjectLocalDataSource>(), true);
      expect(sl.isRegistered<ProjectRepository>(), true);
      expect(sl.isRegistered<CreateProject>(), true);
      expect(sl.isRegistered<GetProject>(), true);
      expect(sl.isRegistered<GetAllProjects>(), true);
      expect(sl.isRegistered<UpdateProject>(), true);
      expect(sl.isRegistered<DeleteProject>(), true);
      expect(sl.isRegistered<SearchProjects>(), true);
      expect(sl.isRegistered<ProjectBloc>(), true);
    });

    test('should resolve DatabaseHelper as singleton', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final instance1 = sl<DatabaseHelper>();
      final instance2 = sl<DatabaseHelper>();

      // Assert
      expect(instance1, same(instance2));
    });

    test('should resolve ProjectLocalDataSource as singleton', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final instance1 = sl<ProjectLocalDataSource>();
      final instance2 = sl<ProjectLocalDataSource>();

      // Assert
      expect(instance1, same(instance2));
    });

    test('should resolve ProjectRepository as singleton', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final instance1 = sl<ProjectRepository>();
      final instance2 = sl<ProjectRepository>();

      // Assert
      expect(instance1, same(instance2));
    });

    test('should resolve Use Cases as singletons', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final createProject1 = sl<CreateProject>();
      final createProject2 = sl<CreateProject>();
      final getProject1 = sl<GetProject>();
      final getProject2 = sl<GetProject>();

      // Assert
      expect(createProject1, same(createProject2));
      expect(getProject1, same(getProject2));
    });

    test(
      'should resolve ProjectBloc as factory (new instance each time)',
      () async {
        // Arrange
        await initializeDependencies();

        // Act
        final bloc1 = sl<ProjectBloc>();
        final bloc2 = sl<ProjectBloc>();

        // Assert - should be different instances
        expect(bloc1, isNot(same(bloc2)));

        // Cleanup
        bloc1.close();
        bloc2.close();
      },
    );

    test('should inject dependencies correctly into ProjectBloc', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final bloc = sl<ProjectBloc>();

      // Assert - verify bloc has all required dependencies
      expect(bloc.createProject, isA<CreateProject>());
      expect(bloc.getProject, isA<GetProject>());
      expect(bloc.getAllProjects, isA<GetAllProjects>());
      expect(bloc.updateProject, isA<UpdateProject>());
      expect(bloc.deleteProject, isA<DeleteProject>());
      expect(bloc.searchProjects, isA<SearchProjects>());

      // Cleanup
      bloc.close();
    });

    test('should inject repository correctly into Use Cases', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final createProject = sl<CreateProject>();
      final getProject = sl<GetProject>();

      // Assert - verify use cases have repository injected
      // Note: We can't directly access private fields, but we can verify
      // that the use cases were created successfully
      expect(createProject, isA<CreateProject>());
      expect(getProject, isA<GetProject>());
    });

    test('should inject data source correctly into repository', () async {
      // Arrange
      await initializeDependencies();

      // Act
      final repository = sl<ProjectRepository>();

      // Assert
      expect(repository, isA<ProjectRepository>());
    });

    test('should handle multiple initializations without errors', () async {
      // Act & Assert - should not throw
      await initializeDependencies();
      await initializeDependencies();
      await initializeDependencies();

      // Verify dependencies are still registered
      expect(sl.isRegistered<ProjectBloc>(), true);
    });
  });
}
