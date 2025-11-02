/// Base class for all failures in the application
///
/// Failures represent domain-level errors that can occur during
/// business logic execution. They are part of the expected flow
/// and should be handled gracefully.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

/// Failure that occurs when interacting with the database
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);

  @override
  String toString() => 'DatabaseFailure: $message';
}

/// Failure that occurs during network operations
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  @override
  String toString() => 'NetworkFailure: $message';
}

/// Failure that occurs when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);

  @override
  String toString() => 'ValidationFailure: $message';
}

/// Failure that occurs when a resource is not found
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);

  @override
  String toString() => 'NotFoundFailure: $message';
}

/// Failure that occurs due to server errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);

  @override
  String toString() => 'ServerFailure: $message';
}

/// Failure that occurs when an operation is not permitted
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);

  @override
  String toString() => 'PermissionFailure: $message';
}

/// Failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);

  @override
  String toString() => 'UnexpectedFailure: $message';
}
