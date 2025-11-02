import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for checking if a session exists
///
/// Encapsulates the business logic for verifying session existence by ID.
class SessionExists implements UseCase<bool, SessionExistsParams> {
  final SessionRepository repository;

  SessionExists(this.repository);

  @override
  Future<Either<Failure, bool>> call(SessionExistsParams params) async {
    return await repository.sessionExists(params.id);
  }
}

/// Parameters for the SessionExists use case
class SessionExistsParams extends Equatable {
  final int id;

  const SessionExistsParams({required this.id});

  @override
  List<Object?> get props => [id];
}
