import 'package:equatable/equatable.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';

/// Base class for all Session events
abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load a single session by ID
class LoadSessionEvent extends SessionEvent {
  final String id;

  const LoadSessionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to load all sessions for a specific project
class LoadSessionsForProjectEvent extends SessionEvent {
  final String projectId;

  const LoadSessionsForProjectEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Event to load all sessions
class LoadAllSessionsEvent extends SessionEvent {
  const LoadAllSessionsEvent();
}

/// Event to create a new session
class CreateSessionEvent extends SessionEvent {
  final SessionEntity session;

  const CreateSessionEvent(this.session);

  @override
  List<Object?> get props => [session];
}

/// Event to update an existing session
class UpdateSessionEvent extends SessionEvent {
  final SessionEntity session;

  const UpdateSessionEvent(this.session);

  @override
  List<Object?> get props => [session];
}

/// Event to delete a session
class DeleteSessionEvent extends SessionEvent {
  final String id;

  const DeleteSessionEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Event to get session count for a project
class GetSessionCountEvent extends SessionEvent {
  final String projectId;

  const GetSessionCountEvent(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// Event to check if a session exists
class CheckSessionExistsEvent extends SessionEvent {
  final String id;

  const CheckSessionExistsEvent(this.id);

  @override
  List<Object?> get props => [id];
}
