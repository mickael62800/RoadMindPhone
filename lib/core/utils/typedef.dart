import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Type alias for a Future that returns an Either with a Failure or a result
///
/// This is commonly used in use cases and repositories to represent
/// operations that can fail.
///
/// Example:
/// ```dart
/// ResultFuture<User> getUser(int id);
/// // Returns Either<Failure, User>
/// ```
typedef ResultFuture<T> = Future<Either<Failure, T>>;

/// Type alias for a Future that returns an Either with a Failure or void
///
/// This is used for operations that don't return a value but can fail.
///
/// Example:
/// ```dart
/// ResultVoid deleteUser(int id);
/// // Returns Either<Failure, void>
/// ```
typedef ResultVoid = Future<Either<Failure, void>>;

/// Type alias for a DataMap (commonly used for JSON parsing)
///
/// Example:
/// ```dart
/// DataMap userJson = {'id': 1, 'name': 'John'};
/// ```
typedef DataMap = Map<String, dynamic>;
