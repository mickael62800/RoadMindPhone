import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/utils/typedef.dart';

void main() {
  group('typedef', () {
    group('ResultFuture', () {
      test('should be a Future<Either<Failure, T>>', () async {
        // Arrange
        ResultFuture<String> createSuccessResult() async {
          return const Right('Success');
        }

        ResultFuture<String> createFailureResult() async {
          return const Left(DatabaseFailure('Error'));
        }

        // Act
        final successResult = await createSuccessResult();
        final failureResult = await createFailureResult();

        // Assert
        expect(successResult, isA<Either<Failure, String>>());
        expect(failureResult, isA<Either<Failure, String>>());

        successResult.fold(
          (failure) => fail('Should be Right'),
          (value) => expect(value, 'Success'),
        );

        failureResult.fold(
          (failure) => expect(failure.message, 'Error'),
          (value) => fail('Should be Left'),
        );
      });

      test('should work with different types', () async {
        // Arrange
        ResultFuture<int> getNumber() async {
          return const Right(42);
        }

        ResultFuture<List<String>> getList() async {
          return const Right(['a', 'b', 'c']);
        }

        // Act
        final numberResult = await getNumber();
        final listResult = await getList();

        // Assert
        numberResult.fold(
          (failure) => fail('Should be success'),
          (value) => expect(value, 42),
        );

        listResult.fold((failure) => fail('Should be success'), (value) {
          expect(value, isA<List<String>>());
          expect(value.length, 3);
        });
      });
    });

    group('ResultVoid', () {
      test('should be a Future<Either<Failure, void>>', () async {
        // Arrange
        ResultVoid createSuccessResult() async {
          return const Right(null);
        }

        ResultVoid createFailureResult() async {
          return const Left(ValidationFailure('Validation error'));
        }

        // Act
        final successResult = await createSuccessResult();
        final failureResult = await createFailureResult();

        // Assert
        expect(successResult, isA<Either<Failure, void>>());
        expect(failureResult, isA<Either<Failure, void>>());

        successResult.fold((failure) => fail('Should be Right'), (_) {
          // Success - operation completed
        });

        failureResult.fold(
          (failure) => expect(failure.message, 'Validation error'),
          (_) => fail('Should be Left'),
        );
      });
    });

    group('DataMap', () {
      test('should be a Map<String, dynamic>', () {
        // Arrange & Act
        final DataMap data = {
          'id': 1,
          'name': 'Test',
          'isActive': true,
          'score': 99.5,
          'tags': ['a', 'b'],
        };

        // Assert
        expect(data, isA<Map<String, dynamic>>());
        expect(data['id'], 1);
        expect(data['name'], 'Test');
        expect(data['isActive'], true);
        expect(data['score'], 99.5);
        expect(data['tags'], ['a', 'b']);
      });

      test('should accept any dynamic value', () {
        // Arrange & Act
        final DataMap data = {
          'string': 'value',
          'int': 123,
          'double': 45.67,
          'bool': false,
          'null': null,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };

        // Assert
        expect(data['string'], isA<String>());
        expect(data['int'], isA<int>());
        expect(data['double'], isA<double>());
        expect(data['bool'], isA<bool>());
        expect(data['null'], isNull);
        expect(data['list'], isA<List>());
        expect(data['map'], isA<Map>());
      });

      test('should be used for JSON-like data structures', () {
        // Arrange - Simulate JSON data
        final DataMap userJson = {
          'id': 1,
          'username': 'john_doe',
          'email': 'john@example.com',
          'profile': {'firstName': 'John', 'lastName': 'Doe', 'age': 30},
          'roles': ['user', 'admin'],
        };

        // Act & Assert
        expect(userJson['id'], 1);
        expect(userJson['username'], 'john_doe');
        expect(userJson['profile'], isA<Map>());
        expect(userJson['profile']['firstName'], 'John');
        expect(userJson['roles'], isA<List>());
        expect((userJson['roles'] as List).length, 2);
      });
    });
  });
}
