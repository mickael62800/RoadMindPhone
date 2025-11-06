import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';
import 'package:roadmindphone/features/session/domain/repositories/session_repository.dart';

/// Use case for deleting a session
///
/// Encapsulates the business logic for deleting a session from the database.
class DeleteSession implements UseCase<void, DeleteSessionParams> {
  final SessionRepository repository;

  DeleteSession(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteSessionParams params) async {
    return await repository.deleteSession(params.id);
  }
}

/// Parameters for the DeleteSession use case
class DeleteSessionParams extends Equatable {
  final String id;

  const DeleteSessionParams({required this.id});

  @override
  List<Object?> get props => [id];
}
