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
import 'package:roadmindphone/features/session/data/datasources/session_local_data_source.dart';
import 'package:roadmindphone/features/session/data/datasources/session_local_data_source_impl.dart';
import 'package:roadmindphone/features/session/data/repositories/session_repository_impl.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';
import 'package:roadmindphone/features/session/domain/usecases/create_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/delete_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_all_sessions.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_session_count_for_project.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_sessions_for_project.dart';
import 'package:roadmindphone/features/session/domain/usecases/session_exists.dart';
import 'package:roadmindphone/features/session/domain/usecases/update_session.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_bloc.dart';

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

  // ============================================
  // Features - Session
  // ============================================

  // Data Sources
  sl.registerLazySingleton<SessionLocalDataSource>(
    () => SessionLocalDataSourceImpl(databaseHelper: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SessionRepository>(
    () => SessionRepositoryImpl(localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSession(sl()));
  sl.registerLazySingleton(() => GetSessionsForProject(sl()));
  sl.registerLazySingleton(() => GetAllSessions(sl()));
  sl.registerLazySingleton(() => CreateSession(sl()));
  sl.registerLazySingleton(() => UpdateSession(sl()));
  sl.registerLazySingleton(() => DeleteSession(sl()));
  sl.registerLazySingleton(() => GetSessionCountForProject(sl()));
  sl.registerLazySingleton(() => SessionExists(sl()));

  // BLoC - Factory (new instance each time)
  sl.registerFactory(
    () => SessionBloc(
      getSession: sl(),
      getSessionsForProject: sl(),
      getAllSessions: sl(),
      createSession: sl(),
      updateSession: sl(),
      deleteSession: sl(),
      getSessionCountForProject: sl(),
      sessionExists: sl(),
    ),
  );
}
