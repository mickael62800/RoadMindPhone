import 'package:dartz/dartz.dart';
import 'package:roadmindphone/core/error/exceptions.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source.dart';
import 'package:roadmindphone/features/project/data/models/project_model.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';

/// Implementation of [ProjectRepository]
///
/// This class bridges the domain and data layers by:
/// - Converting domain entities to data models
/// - Calling the appropriate data source methods
/// - Converting exceptions to failures (Either left side)
/// - Converting data models back to domain entities (Either right side)
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource localDataSource;

  const ProjectRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ProjectEntity>> createProject({
    required String title,
    String? description,
  }) async {
    try {
      // Create a new ProjectModel (without ID, will be generated)
      final projectModel = ProjectModel(
        title: title,
        description: description,
        createdAt: DateTime.now(),
      );

      // Call data source to create the project
      final result = await localDataSource.createProject(projectModel);

      // Return success with the created entity
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectEntity>> getProject(int id) async {
    try {
      final result = await localDataSource.getProject(id);
      return Right(result);
    } on DatabaseException catch (e) {
      // Check if it's a "not found" error
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure('Project with id $id not found'));
      }
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> getAllProjects() async {
    try {
      final result = await localDataSource.getAllProjects();
      // Convert List<ProjectModel> to List<ProjectEntity>
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProjectEntity>> updateProject(
      ProjectEntity project) async {
    try {
      // Convert entity to model
      final projectModel = ProjectModel.fromEntity(project);

      // Update via data source
      final result = await localDataSource.updateProject(projectModel);

      return Right(result);
    } on DatabaseException catch (e) {
      // Check if it's a "not found" error
      if (e.message.contains('not found')) {
        return Left(
            NotFoundFailure('Project with id ${project.id} not found'));
      }
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(int id) async {
    try {
      await localDataSource.deleteProject(id);
      return const Right(null);
    } on DatabaseException catch (e) {
      // Check if it's a "not found" error
      if (e.message.contains('not found')) {
        return Left(NotFoundFailure('Project with id $id not found'));
      }
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getProjectsCount() async {
    try {
      final result = await localDataSource.getProjectsCount();
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProjectEntity>>> searchProjects(
      String query) async {
    try {
      final result = await localDataSource.searchProjects(query);
      // Convert List<ProjectModel> to List<ProjectEntity>
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> projectExists(int id) async {
    try {
      final result = await localDataSource.projectExists(id);
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
