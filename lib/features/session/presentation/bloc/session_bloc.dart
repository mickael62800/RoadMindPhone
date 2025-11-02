import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/usecases/create_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/delete_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_all_sessions.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_session.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_session_count_for_project.dart';
import 'package:roadmindphone/features/session/domain/usecases/get_sessions_for_project.dart';
import 'package:roadmindphone/features/session/domain/usecases/session_exists.dart';
import 'package:roadmindphone/features/session/domain/usecases/update_session.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_event.dart';
import 'package:roadmindphone/features/session/presentation/bloc/session_state.dart';

/// BLoC for managing Session state and business logic
///
/// Handles all session-related events and emits appropriate states.
/// Uses Clean Architecture use cases to perform operations.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final GetSession getSession;
  final GetSessionsForProject getSessionsForProject;
  final GetAllSessions getAllSessions;
  final CreateSession createSession;
  final UpdateSession updateSession;
  final DeleteSession deleteSession;
  final GetSessionCountForProject getSessionCountForProject;
  final SessionExists sessionExists;

  SessionBloc({
    required this.getSession,
    required this.getSessionsForProject,
    required this.getAllSessions,
    required this.createSession,
    required this.updateSession,
    required this.deleteSession,
    required this.getSessionCountForProject,
    required this.sessionExists,
  }) : super(const SessionInitial()) {
    on<LoadSessionEvent>(_onLoadSession);
    on<LoadSessionsForProjectEvent>(_onLoadSessionsForProject);
    on<LoadAllSessionsEvent>(_onLoadAllSessions);
    on<CreateSessionEvent>(_onCreateSession);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<GetSessionCountEvent>(_onGetSessionCount);
    on<CheckSessionExistsEvent>(_onCheckSessionExists);
  }

  /// Handles loading a single session by ID
  Future<void> _onLoadSession(
    LoadSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await getSession(GetSessionParams(id: event.id));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) => emit(SessionLoaded(session)),
    );
  }

  /// Handles loading sessions for a specific project
  Future<void> _onLoadSessionsForProject(
    LoadSessionsForProjectEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await getSessionsForProject(
      GetSessionsForProjectParams(projectId: event.projectId),
    );

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (sessions) => emit(SessionsLoaded(sessions)),
    );
  }

  /// Handles loading all sessions
  Future<void> _onLoadAllSessions(
    LoadAllSessionsEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await getAllSessions(NoParams());

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (sessions) => emit(SessionsLoaded(sessions)),
    );
  }

  /// Handles creating a new session
  Future<void> _onCreateSession(
    CreateSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await createSession(
      CreateSessionParams(session: event.session),
    );

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) => emit(
        SessionOperationSuccess(
          'Session created successfully',
          session: session,
        ),
      ),
    );
  }

  /// Handles updating an existing session
  Future<void> _onUpdateSession(
    UpdateSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await updateSession(
      UpdateSessionParams(session: event.session),
    );

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (_) =>
          emit(const SessionOperationSuccess('Session updated successfully')),
    );
  }

  /// Handles deleting a session
  Future<void> _onDeleteSession(
    DeleteSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await deleteSession(DeleteSessionParams(id: event.id));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (_) =>
          emit(const SessionOperationSuccess('Session deleted successfully')),
    );
  }

  /// Handles getting session count for a project
  Future<void> _onGetSessionCount(
    GetSessionCountEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await getSessionCountForProject(
      GetSessionCountForProjectParams(projectId: event.projectId),
    );

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (count) => emit(SessionCountLoaded(count)),
    );
  }

  /// Handles checking if a session exists
  Future<void> _onCheckSessionExists(
    CheckSessionExistsEvent event,
    Emitter<SessionState> emit,
  ) async {
    emit(const SessionLoading());

    final result = await sessionExists(SessionExistsParams(id: event.id));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (exists) => emit(SessionExistsResult(exists)),
    );
  }
}
