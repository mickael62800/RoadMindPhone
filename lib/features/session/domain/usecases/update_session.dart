import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for updating an existing session
///
/// Encapsulates the business logic for updating a session in the database.
class UpdateSession implements UseCase<void, UpdateSessionParams> {
  final SessionRepository repository;

  UpdateSession(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSessionParams params) async {
    return await repository.updateSession(params.session);
  }
}

/// Parameters for the UpdateSession use case
class UpdateSessionParams extends Equatable {
  final SessionEntity session;

  const UpdateSessionParams({required this.session});

  @override
  List<Object?> get props => [session];
}
