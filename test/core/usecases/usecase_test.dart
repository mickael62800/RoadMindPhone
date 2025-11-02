import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/core/error/failures.dart';
import 'package:roadmindphone/core/usecases/usecase.dart';

// Concrete implementation for testing
class TestUseCase extends UseCase<String, TestParams> {
  @override
  Future<Either<Failure, String>> call(TestParams params) async {
    if (params.shouldFail) {
      return const Left(DatabaseFailure('Test failure'));
    }
    return Right('Success: ${params.value}');
  }
}

class TestParams {
  final String value;
  final bool shouldFail;

  TestParams({required this.value, this.shouldFail = false});
}

// VoidUseCase implementation for testing
class TestVoidUseCase extends VoidUseCase<TestParams> {
  @override
  Future<Either<Failure, void>> call(TestParams params) async {
    if (params.shouldFail) {
      return const Left(ValidationFailure('Void test failure'));
    }
    return const Right(null);
  }
}

void main() {
  group('UseCase', () {
    late TestUseCase useCase;

    setUp(() {
      useCase = TestUseCase();
    });

    test('should return Right with result when operation succeeds', () async {
      // Arrange
      final params = TestParams(value: 'test data');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isA<Right<Failure, String>>());
      result.fold(
        (failure) => fail('Should not return failure'),
        (value) => expect(value, 'Success: test data'),
      );
    });

    test('should return Left with Failure when operation fails', () async {
      // Arrange
      final params = TestParams(value: 'test', shouldFail: true);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result, isA<Left<Failure, String>>());
      result.fold((failure) {
        expect(failure, isA<DatabaseFailure>());
        expect(failure.message, 'Test failure');
      }, (value) => fail('Should not return success'));
    });
  });

  group('VoidUseCase', () {
    late TestVoidUseCase voidUseCase;

    setUp(() {
      voidUseCase = TestVoidUseCase();
    });

    test('should return Right with void when operation succeeds', () async {
      // Arrange
      final params = TestParams(value: 'test');

      // Act
      final result = await voidUseCase(params);

      // Assert
      expect(result, isA<Right<Failure, void>>());
      result.fold((failure) => fail('Should not return failure'), (_) {
        // Success - void operation completed
      });
    });

    test('should return Left with Failure when operation fails', () async {
      // Arrange
      final params = TestParams(value: 'test', shouldFail: true);

      // Act
      final result = await voidUseCase(params);

      // Assert
      expect(result, isA<Left<Failure, void>>());
      result.fold((failure) {
        expect(failure, isA<ValidationFailure>());
        expect(failure.message, 'Void test failure');
      }, (value) => fail('Should not return success'));
    });
  });

  group('NoParams', () {
    test('should be equal to another NoParams instance', () {
      // Arrange
      const params1 = NoParams();
      const params2 = NoParams();

      // Assert
      expect(params1, equals(params2));
    });

    test('should have consistent hashCode', () {
      // Arrange
      const params1 = NoParams();
      const params2 = NoParams();

      // Assert
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1.hashCode, equals(0));
    });
  });
}
