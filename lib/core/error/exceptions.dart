/// Custom exceptions that can be thrown by data sources
///
/// Exceptions represent technical errors at the data layer level.
/// They should be caught and converted to Failures in the repository layer.
abstract class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when a database operation fails
class DatabaseException extends AppException {
  const DatabaseException(super.message);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception thrown when a network request fails
class NetworkException extends AppException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when server returns an error
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, {this.statusCode});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Exception thrown when data parsing fails
class ParsingException extends AppException {
  const ParsingException(super.message);

  @override
  String toString() => 'ParsingException: $message';
}

/// Exception thrown when a cache operation fails
class CacheException extends AppException {
  const CacheException(super.message);

  @override
  String toString() => 'CacheException: $message';
}
