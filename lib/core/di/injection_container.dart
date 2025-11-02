import 'package:get_it/get_it.dart';
import 'package:roadmindphone/database_helper.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source.dart';
import 'package:roadmindphone/features/project/data/datasources/project_local_data_source_impl.dart';
import 'package:roadmindphone/features/project/data/repositories/project_repository_impl.dart';
import 'package:roadmindphone/features/project/domain/repositories/project_repository.dart';
import 'package:roadmindphone/features/project/domain/usecases/create_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/delete_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_all_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/get_project.dart';
import 'package:roadmindphone/features/project/domain/usecases/search_projects.dart';
import 'package:roadmindphone/features/project/domain/usecases/update_project.dart';
import 'package:roadmindphone/features/project/presentation/bloc/project_bloc.dart';

/// Service locator instance
///
/// This is the single instance of GetIt used throughout the app
/// for dependency injection.
final sl = GetIt.instance;

/// Initialize all dependencies
///
/// This function sets up the dependency injection container with all
/// required services, repositories, data sources, and BLoCs.
///
/// Call this function once at app startup, before runApp().
///
/// If dependencies are already registered, this function will skip
/// re-registration to avoid errors.
Future<void> initializeDependencies() async {
  // Skip if already initialized
  if (sl.isRegistered<DatabaseHelper>()) {
    return;
  }

  // ============================================
  // External Dependencies
  // ============================================  // Database Helper (singleton instance)
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);

  // ============================================
  // Features - Project
  // ============================================

  // Data Sources
  sl.registerLazySingleton<ProjectLocalDataSource>(
    () => ProjectLocalDataSourceImpl(databaseHelper: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CreateProject(sl()));
  sl.registerLazySingleton(() => GetProject(sl()));
  sl.registerLazySingleton(() => GetAllProjects(sl()));
  sl.registerLazySingleton(() => UpdateProject(sl()));
  sl.registerLazySingleton(() => DeleteProject(sl()));
  sl.registerLazySingleton(() => SearchProjects(sl()));

  // BLoC - Factory (new instance each time)
  sl.registerFactory(
    () => ProjectBloc(
      createProject: sl(),
      getProject: sl(),
      getAllProjects: sl(),
      updateProject: sl(),
      deleteProject: sl(),
      searchProjects: sl(),
    ),
  );
}
