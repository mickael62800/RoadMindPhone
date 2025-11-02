import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';

void main() {
  group('Failure', () {
    const testMessage = 'Test error message';

    test('should have correct message', () {
      // Arrange & Act
      const failure = DatabaseFailure(testMessage);

      // Assert
      expect(failure.message, testMessage);
    });

    test('toString should return the message', () {
      // Arrange & Act
      const failure = DatabaseFailure(testMessage);

      // Assert
      expect(failure.toString(), 'DatabaseFailure: $testMessage');
    });

    test('should be equal when messages are the same', () {
      // Arrange
      const failure1 = DatabaseFailure(testMessage);
      const failure2 = DatabaseFailure(testMessage);

      // Assert
      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('should not be equal when messages are different', () {
      // Arrange
      const failure1 = DatabaseFailure('Message 1');
      const failure2 = DatabaseFailure('Message 2');

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });
  });

  group('DatabaseFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = DatabaseFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = DatabaseFailure('Database connection failed');

      // Assert
      expect(failure.toString(), 'DatabaseFailure: Database connection failed');
    });
  });

  group('NetworkFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = NetworkFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = NetworkFailure('No internet connection');

      // Assert
      expect(failure.toString(), 'NetworkFailure: No internet connection');
    });
  });

  group('ValidationFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = ValidationFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = ValidationFailure('Invalid input');

      // Assert
      expect(failure.toString(), 'ValidationFailure: Invalid input');
    });
  });

  group('NotFoundFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = NotFoundFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = NotFoundFailure('Resource not found');

      // Assert
      expect(failure.toString(), 'NotFoundFailure: Resource not found');
    });
  });

  group('ServerFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = ServerFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = ServerFailure('Internal server error');

      // Assert
      expect(failure.toString(), 'ServerFailure: Internal server error');
    });
  });

  group('PermissionFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = PermissionFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = PermissionFailure('Access denied');

      // Assert
      expect(failure.toString(), 'PermissionFailure: Access denied');
    });
  });

  group('UnexpectedFailure', () {
    test('should be a subclass of Failure', () {
      // Arrange & Act
      const failure = UnexpectedFailure('test');

      // Assert
      expect(failure, isA<Failure>());
    });

    test('toString should include failure type', () {
      // Arrange & Act
      const failure = UnexpectedFailure('Something went wrong');

      // Assert
      expect(failure.toString(), 'UnexpectedFailure: Something went wrong');
    });
  });
}
