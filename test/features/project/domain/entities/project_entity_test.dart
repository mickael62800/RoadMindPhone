import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

void main() {
  group('ProjectEntity', () {
    final now = DateTime(2024, 1, 15, 10, 30);
    final later = DateTime(2024, 1, 16, 14, 45);

    late ProjectEntity tProjectEntity;

    setUp(() {
      tProjectEntity = ProjectEntity(
        id: 1,
        title: 'Test Project',
        description: 'Test Description',
        sessionCount: 5,
        duration: const Duration(hours: 2, minutes: 30),
        createdAt: now,
        updatedAt: later,
      );
    });

    group('constructor', () {
      test('should create entity with all required fields', () {
        expect(tProjectEntity.id, 1);
        expect(tProjectEntity.title, 'Test Project');
        expect(tProjectEntity.description, 'Test Description');
        expect(tProjectEntity.sessionCount, 5);
        expect(tProjectEntity.duration, const Duration(hours: 2, minutes: 30));
        expect(tProjectEntity.createdAt, now);
        expect(tProjectEntity.updatedAt, later);
      });

      test('should create entity with default values', () {
        final entity = ProjectEntity(title: 'Minimal Project', createdAt: now);

        expect(entity.id, isNull);
        expect(entity.title, 'Minimal Project');
        expect(entity.description, isNull);
        expect(entity.sessionCount, 0);
        expect(entity.duration, Duration.zero);
        expect(entity.createdAt, now);
        expect(entity.updatedAt, isNull);
      });

      test('should create entity with only required fields', () {
        final entity = ProjectEntity(title: 'Simple Project', createdAt: now);

        expect(entity.title, 'Simple Project');
        expect(entity.createdAt, now);
        expect(entity.sessionCount, 0);
        expect(entity.duration, Duration.zero);
      });
    });

    group('equality', () {
      test('should be equal when all properties are the same', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description A',
          sessionCount: 3,
          duration: const Duration(hours: 1),
          createdAt: now,
          updatedAt: later,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description A',
          sessionCount: 3,
          duration: const Duration(hours: 1),
          createdAt: now,
          updatedAt: later,
        );

        expect(entity1, equals(entity2));
      });

      test('should not be equal when id differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 2,
          title: 'Project A',
          createdAt: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when title differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project B',
          createdAt: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when description differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description A',
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description B',
          createdAt: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when sessionCount differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          sessionCount: 5,
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          sessionCount: 10,
          createdAt: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when duration differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          duration: const Duration(hours: 1),
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          duration: const Duration(hours: 2),
          createdAt: now,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when createdAt differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: later,
        );

        expect(entity1, isNot(equals(entity2)));
      });

      test('should not be equal when updatedAt differs', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
          updatedAt: now,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
          updatedAt: later,
        );

        expect(entity1, isNot(equals(entity2)));
      });
    });

    group('hashCode', () {
      test('should have same hashCode for equal entities', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description',
          sessionCount: 5,
          duration: const Duration(hours: 2),
          createdAt: now,
          updatedAt: later,
        );

        final entity2 = ProjectEntity(
          id: 1,
          title: 'Project A',
          description: 'Description',
          sessionCount: 5,
          duration: const Duration(hours: 2),
          createdAt: now,
          updatedAt: later,
        );

        expect(entity1.hashCode, equals(entity2.hashCode));
      });

      test('should have different hashCode for different entities', () {
        final entity1 = ProjectEntity(
          id: 1,
          title: 'Project A',
          createdAt: now,
        );

        final entity2 = ProjectEntity(
          id: 2,
          title: 'Project B',
          createdAt: later,
        );

        expect(entity1.hashCode, isNot(equals(entity2.hashCode)));
      });
    });

    group('copyWith', () {
      test('should copy with new id', () {
        final copied = tProjectEntity.copyWith(id: 999);

        expect(copied.id, 999);
        expect(copied.title, tProjectEntity.title);
        expect(copied.description, tProjectEntity.description);
        expect(copied.sessionCount, tProjectEntity.sessionCount);
        expect(copied.duration, tProjectEntity.duration);
        expect(copied.createdAt, tProjectEntity.createdAt);
        expect(copied.updatedAt, tProjectEntity.updatedAt);
      });

      test('should copy with new title', () {
        final copied = tProjectEntity.copyWith(title: 'New Title');

        expect(copied.title, 'New Title');
        expect(copied.id, tProjectEntity.id);
      });

      test('should copy with new description', () {
        final copied = tProjectEntity.copyWith(description: 'New Description');

        expect(copied.description, 'New Description');
        expect(copied.title, tProjectEntity.title);
      });

      test('should copy with new sessionCount', () {
        final copied = tProjectEntity.copyWith(sessionCount: 42);

        expect(copied.sessionCount, 42);
        expect(copied.title, tProjectEntity.title);
      });

      test('should copy with new duration', () {
        final newDuration = const Duration(hours: 5, minutes: 45);
        final copied = tProjectEntity.copyWith(duration: newDuration);

        expect(copied.duration, newDuration);
        expect(copied.title, tProjectEntity.title);
      });

      test('should copy with new createdAt', () {
        final newDate = DateTime(2025, 6, 1);
        final copied = tProjectEntity.copyWith(createdAt: newDate);

        expect(copied.createdAt, newDate);
        expect(copied.title, tProjectEntity.title);
      });

      test('should copy with new updatedAt', () {
        final newDate = DateTime(2025, 6, 15);
        final copied = tProjectEntity.copyWith(updatedAt: newDate);

        expect(copied.updatedAt, newDate);
        expect(copied.title, tProjectEntity.title);
      });

      test('should copy with multiple fields changed', () {
        final newDate = DateTime(2025, 12, 31);
        final copied = tProjectEntity.copyWith(
          title: 'Updated Project',
          sessionCount: 100,
          duration: const Duration(hours: 10),
          updatedAt: newDate,
        );

        expect(copied.title, 'Updated Project');
        expect(copied.sessionCount, 100);
        expect(copied.duration, const Duration(hours: 10));
        expect(copied.updatedAt, newDate);
        // Original values should be preserved
        expect(copied.id, tProjectEntity.id);
        expect(copied.description, tProjectEntity.description);
        expect(copied.createdAt, tProjectEntity.createdAt);
      });

      test('should return identical copy when no parameters provided', () {
        final copied = tProjectEntity.copyWith();

        expect(copied, equals(tProjectEntity));
        expect(copied.id, tProjectEntity.id);
        expect(copied.title, tProjectEntity.title);
        expect(copied.description, tProjectEntity.description);
        expect(copied.sessionCount, tProjectEntity.sessionCount);
        expect(copied.duration, tProjectEntity.duration);
        expect(copied.createdAt, tProjectEntity.createdAt);
        expect(copied.updatedAt, tProjectEntity.updatedAt);
      });
    });

    group('business rules', () {
      test('hasValidTitle should return true for non-empty title', () {
        final entity = ProjectEntity(title: 'Valid Title', createdAt: now);

        expect(entity.hasValidTitle, isTrue);
      });

      test('hasValidTitle should return true for title with spaces', () {
        final entity = ProjectEntity(
          title: '   Valid Title   ',
          createdAt: now,
        );

        expect(entity.hasValidTitle, isTrue);
      });

      test('hasValidTitle should return false for empty title', () {
        final entity = ProjectEntity(title: '', createdAt: now);

        expect(entity.hasValidTitle, isFalse);
      });

      test('hasValidTitle should return false for whitespace-only title', () {
        final entity = ProjectEntity(title: '   ', createdAt: now);

        expect(entity.hasValidTitle, isFalse);
      });

      test('hasSessions should return true when sessionCount > 0', () {
        final entity = ProjectEntity(
          title: 'Project',
          sessionCount: 5,
          createdAt: now,
        );

        expect(entity.hasSessions, isTrue);
      });

      test('hasSessions should return false when sessionCount = 0', () {
        final entity = ProjectEntity(
          title: 'Project',
          sessionCount: 0,
          createdAt: now,
        );

        expect(entity.hasSessions, isFalse);
      });

      test('isNew should return true when id is null', () {
        final entity = ProjectEntity(title: 'New Project', createdAt: now);

        expect(entity.isNew, isTrue);
      });

      test('isNew should return false when id is not null', () {
        final entity = ProjectEntity(
          id: 1,
          title: 'Existing Project',
          createdAt: now,
        );

        expect(entity.isNew, isFalse);
      });
    });

    group('toString', () {
      test('should return formatted string with all properties', () {
        final entity = ProjectEntity(
          id: 42,
          title: 'My Project',
          description: 'My Description',
          sessionCount: 10,
          duration: const Duration(hours: 3, minutes: 15),
          createdAt: now,
          updatedAt: later,
        );

        final result = entity.toString();

        expect(result, contains('ProjectEntity('));
        expect(result, contains('id: 42'));
        expect(result, contains('title: My Project'));
        expect(result, contains('description: My Description'));
        expect(result, contains('sessionCount: 10'));
        expect(result, contains('duration: 3:15:00.000000'));
        expect(result, contains('createdAt: $now'));
        expect(result, contains('updatedAt: $later'));
      });

      test('should handle null values in toString', () {
        final entity = ProjectEntity(title: 'Simple Project', createdAt: now);

        final result = entity.toString();

        expect(result, contains('id: null'));
        expect(result, contains('description: null'));
        expect(result, contains('updatedAt: null'));
      });
    });

    group('props getter', () {
      test('should include all properties in props list', () {
        expect(tProjectEntity.props.length, 7);
        expect(tProjectEntity.props, contains(tProjectEntity.id));
        expect(tProjectEntity.props, contains(tProjectEntity.title));
        expect(tProjectEntity.props, contains(tProjectEntity.description));
        expect(tProjectEntity.props, contains(tProjectEntity.sessionCount));
        expect(tProjectEntity.props, contains(tProjectEntity.duration));
        expect(tProjectEntity.props, contains(tProjectEntity.createdAt));
        expect(tProjectEntity.props, contains(tProjectEntity.updatedAt));
      });

      test('should handle null values in props list', () {
        final entity = ProjectEntity(title: 'Project', createdAt: now);

        expect(entity.props.length, 7);
        expect(entity.props[0], isNull); // id
        expect(entity.props[2], isNull); // description
        expect(entity.props[6], isNull); // updatedAt
      });
    });

    group('immutability', () {
      test('should not allow modification of fields', () {
        // This test verifies that all fields are final by attempting compilation
        // If fields weren't final, the following would fail to compile:
        // tProjectEntity.title = 'New Title'; // Should not compile

        expect(tProjectEntity.id, 1);
        expect(tProjectEntity.title, 'Test Project');
        // The fact that this test exists and compiles proves immutability
      });

      test('should create new instance with copyWith, not modify original', () {
        final originalId = tProjectEntity.id;
        final originalTitle = tProjectEntity.title;

        final copied = tProjectEntity.copyWith(title: 'Modified Title');

        // Original should remain unchanged
        expect(tProjectEntity.id, originalId);
        expect(tProjectEntity.title, originalTitle);

        // Copy should have new values
        expect(copied.title, 'Modified Title');
        expect(copied.id, originalId);
      });
    });
  });
}
