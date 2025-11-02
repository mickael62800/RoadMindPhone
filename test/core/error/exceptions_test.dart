import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/exceptions.dart';

void main() {
  group('AppException', () {
    const testMessage = 'Test exception message';

    test('should have correct message', () {
      // Arrange & Act
      const exception = DatabaseException(testMessage);

      // Assert
      expect(exception.message, testMessage);
    });

    test('toString should return the message with type', () {
      // Arrange & Act
      const exception = DatabaseException(testMessage);

      // Assert
      expect(exception.toString(), 'DatabaseException: $testMessage');
    });
  });

  group('DatabaseException', () {
    test('should be a subclass of AppException', () {
      // Arrange & Act
      const exception = DatabaseException('test');

      // Assert
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('toString should include exception type', () {
      // Arrange & Act
      const exception = DatabaseException('Failed to insert record');

      // Assert
      expect(
        exception.toString(),
        'DatabaseException: Failed to insert record',
      );
    });
  });

  group('NetworkException', () {
    test('should be a subclass of AppException', () {
      // Arrange & Act
      const exception = NetworkException('test');

      // Assert
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('toString should include exception type', () {
      // Arrange & Act
      const exception = NetworkException('Connection timeout');

      // Assert
      expect(exception.toString(), 'NetworkException: Connection timeout');
    });
  });

  group('ServerException', () {
    test('should be a subclass of AppException', () {
      // Arrange & Act
      const exception = ServerException('test');

      // Assert
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('should store status code', () {
      // Arrange & Act
      const exception = ServerException('Server error', statusCode: 500);

      // Assert
      expect(exception.statusCode, 500);
    });

    test('toString should include status code when provided', () {
      // Arrange & Act
      const exception = ServerException('Internal error', statusCode: 500);

      // Assert
      expect(exception.toString(), 'ServerException(500): Internal error');
    });

    test('toString should handle null status code', () {
      // Arrange & Act
      const exception = ServerException('Server error');

      // Assert
      expect(exception.toString(), 'ServerException(null): Server error');
    });
  });

  group('ParsingException', () {
    test('should be a subclass of AppException', () {
      // Arrange & Act
      const exception = ParsingException('test');

      // Assert
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('toString should include exception type', () {
      // Arrange & Act
      const exception = ParsingException('Invalid JSON format');

      // Assert
      expect(exception.toString(), 'ParsingException: Invalid JSON format');
    });
  });

  group('CacheException', () {
    test('should be a subclass of AppException', () {
      // Arrange & Act
      const exception = CacheException('test');

      // Assert
      expect(exception, isA<AppException>());
      expect(exception, isA<Exception>());
    });

    test('toString should include exception type', () {
      // Arrange & Act
      const exception = CacheException('Cache write failed');

      // Assert
      expect(exception.toString(), 'CacheException: Cache write failed');
    });
  });
}
