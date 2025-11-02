import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base class for all use cases in the application
///
/// Use cases represent a single business operation.
/// They encapsulate business logic and orchestrate the flow of data
/// between the presentation layer and the data layer.
///
/// Type parameters:
/// - [T]: The type of data returned on success
/// - [P]: The type of parameters required to execute the use case
abstract class UseCase<T, P> {
  /// Executes the use case with the given parameters
  ///
  /// Returns an [Either] with a [Failure] on the left side
  /// or the result of type [T] on the right side
  Future<Either<Failure, T>> call(P params);
}

/// A special type of UseCase that returns void on success
abstract class VoidUseCase<Params> {
  Future<Either<Failure, void>> call(Params params);
}

/// Represents a use case that doesn't require any parameters
class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}
