import 'package:equatable/equatable.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';

/// Base class for all Session states
abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operations
class SessionInitial extends SessionState {
  const SessionInitial();
}

/// State when a session operation is in progress
class SessionLoading extends SessionState {
  const SessionLoading();
}

/// State when a single session has been loaded successfully
class SessionLoaded extends SessionState {
  final SessionEntity session;

  const SessionLoaded(this.session);

  @override
  List<Object?> get props => [session];
}

/// State when multiple sessions have been loaded successfully
class SessionsLoaded extends SessionState {
  final List<SessionEntity> sessions;

  const SessionsLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// State when a session count has been retrieved
class SessionCountLoaded extends SessionState {
  final int count;

  const SessionCountLoaded(this.count);

  @override
  List<Object?> get props => [count];
}

/// State when session existence check is complete
class SessionExistsResult extends SessionState {
  final bool exists;

  const SessionExistsResult(this.exists);

  @override
  List<Object?> get props => [exists];
}

/// State when a session operation (create/update/delete) succeeds
class SessionOperationSuccess extends SessionState {
  final String message;
  final SessionEntity?
  session; // Optional: contains the created/updated session

  const SessionOperationSuccess(this.message, {this.session});

  @override
  List<Object?> get props => [message, session];
}

/// State when an error occurs
class SessionError extends SessionState {
  final String message;

  const SessionError(this.message);

  @override
  List<Object?> get props => [message];
}
