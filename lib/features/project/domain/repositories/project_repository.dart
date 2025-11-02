import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Abstract repository interface for Project operations
///
/// This interface defines the contract for project data operations.
/// It follows the Repository pattern from Clean Architecture:
/// - Domain layer defines the interface (this file)
/// - Data layer implements the interface
/// - Use cases depend on this abstraction, not on concrete implementations
///
/// All methods return `Either<Failure, T>` for functional error handling:
/// - `Left(Failure)`: Operation failed with a domain error
/// - `Right(T)`: Operation succeeded with the result
abstract class ProjectRepository {
  /// Create a new project
  ///
  /// Returns the created project with its generated ID
  ///
  /// Possible failures:
  /// - [ValidationFailure]: Invalid project data (empty title, etc.)
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<ProjectEntity> createProject({
    required String title,
    String? description,
  });

  /// Get a project by its ID
  ///
  /// Returns the project if found, or a Failure if not found
  ///
  /// Possible failures:
  /// - [NotFoundFailure]: Project with given ID doesn't exist
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<ProjectEntity> getProject(int id);

  /// Get all projects
  ///
  /// Returns a list of all projects, ordered by creation date (newest first)
  /// Returns an empty list if no projects exist
  ///
  /// Possible failures:
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<List<ProjectEntity>> getAllProjects();

  /// Update an existing project
  ///
  /// Returns the updated project
  ///
  /// Possible failures:
  /// - [NotFoundFailure]: Project with given ID doesn't exist
  /// - [ValidationFailure]: Invalid project data
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<ProjectEntity> updateProject(ProjectEntity project);

  /// Delete a project by its ID
  ///
  /// Deletes the project and all associated sessions
  /// Returns void on success
  ///
  /// Possible failures:
  /// - [NotFoundFailure]: Project with given ID doesn't exist
  /// - [DatabaseFailure]: Database operation failed
  ResultVoid deleteProject(int id);

  /// Get projects count
  ///
  /// Returns the total number of projects
  ///
  /// Possible failures:
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<int> getProjectsCount();

  /// Search projects by title or description
  ///
  /// Returns projects matching the search query (case-insensitive)
  /// Returns an empty list if no matches found
  ///
  /// Possible failures:
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<List<ProjectEntity>> searchProjects(String query);

  /// Check if a project exists by ID
  ///
  /// Returns true if the project exists, false otherwise
  ///
  /// Possible failures:
  /// - [DatabaseFailure]: Database operation failed
  ResultFuture<bool> projectExists(int id);
}
