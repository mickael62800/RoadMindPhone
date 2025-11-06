import 'package:roadmindphone/features/project/data/models/project_model.dart';

/// Abstract interface for Project local data source
///
/// Defines the contract for local data operations (SQLite).
/// This abstraction allows for easy testing and potential
/// implementation swapping (e.g., Hive, SharedPreferences).
abstract class ProjectLocalDataSource {
  /// Create a new project in local storage
  ///
  /// Returns the created project with its generated ID
  /// Throws [DatabaseException] on error
  Future<ProjectModel> createProject(ProjectModel project);

  /// Get a project by its ID
  ///
  /// Returns the project if found
  /// Throws [DatabaseException] if not found or on error
  Future<ProjectModel> getProject(String id);

  /// Get all projects
  ///
  /// Returns list of all projects, ordered by creation date (newest first)
  /// Returns empty list if no projects exist
  /// Throws [DatabaseException] on error
  Future<List<ProjectModel>> getAllProjects();

  /// Update an existing project
  ///
  /// Returns the updated project
  /// Throws [DatabaseException] if not found or on error
  Future<ProjectModel> updateProject(ProjectModel project);

  /// Delete a project by its ID
  ///
  /// Throws [DatabaseException] if not found or on error
  Future<void> deleteProject(String id);

  /// Get projects count
  ///
  /// Returns the total number of projects
  /// Throws [DatabaseException] on error
  Future<int> getProjectsCount();

  /// Search projects by title or description
  ///
  /// Returns projects matching the query (case-insensitive)
  /// Returns empty list if no matches
  /// Throws [DatabaseException] on error
  Future<List<ProjectModel>> searchProjects(String query);

  /// Check if a project exists by ID
  ///
  /// Returns true if exists, false otherwise
  /// Throws [DatabaseException] on error
  Future<bool> projectExists(String id);
}
