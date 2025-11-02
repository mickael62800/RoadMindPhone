import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/features/project/data/models/project_model.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

void main() {
  late ProjectModel tModel;
  late DateTime tCreatedAt;
  late DateTime tUpdatedAt;

  setUp(() {
    tCreatedAt = DateTime(2024, 1, 15, 10, 30);
    tUpdatedAt = DateTime(2024, 1, 16, 14, 45);
    tModel = ProjectModel(
      id: 1,
      title: 'Test Project',
      description: 'Test Description',
      sessionCount: 5,
      duration: const Duration(hours: 2, minutes: 30),
      createdAt: tCreatedAt,
      updatedAt: tUpdatedAt,
    );
  });

  group('ProjectModel', () {
    test('should be a subclass of ProjectEntity', () {
      expect(tModel, isA<ProjectEntity>());
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = ProjectEntity(
          id: 1,
          title: 'Entity Project',
          description: 'Entity Description',
          sessionCount: 3,
          duration: const Duration(hours: 1),
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        final model = ProjectModel.fromEntity(entity);

        expect(model.id, entity.id);
        expect(model.title, entity.title);
        expect(model.description, entity.description);
        expect(model.sessionCount, entity.sessionCount);
        expect(model.duration, entity.duration);
        expect(model.createdAt, entity.createdAt);
        expect(model.updatedAt, entity.updatedAt);
      });
    });

    group('fromMap', () {
      test('should create model from map with all fields', () {
        final map = {
          'id': 1,
          'title': 'Map Project',
          'description': 'Map Description',
          'session_count': 5,
          'duration': 9000000, // 2h 30min in milliseconds
          'created_at': tCreatedAt.toIso8601String(),
          'updated_at': tUpdatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromMap(map);

        expect(model.id, 1);
        expect(model.title, 'Map Project');
        expect(model.description, 'Map Description');
        expect(model.sessionCount, 5);
        expect(model.duration, const Duration(milliseconds: 9000000));
        expect(model.createdAt, tCreatedAt);
        expect(model.updatedAt, tUpdatedAt);
      });

      test('should create model from map without optional fields', () {
        final map = {
          'title': 'Minimal Project',
          'created_at': tCreatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromMap(map);

        expect(model.id, isNull);
        expect(model.title, 'Minimal Project');
        expect(model.description, isNull);
        expect(model.sessionCount, 0);
        expect(model.duration, Duration.zero);
        expect(model.createdAt, tCreatedAt);
        expect(model.updatedAt, isNull);
      });

      test('should handle null sessionCount with default 0', () {
        final map = {
          'title': 'Project',
          'created_at': tCreatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromMap(map);

        expect(model.sessionCount, 0);
      });

      test('should handle null duration with default 0', () {
        final map = {
          'title': 'Project',
          'created_at': tCreatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromMap(map);

        expect(model.duration, Duration.zero);
      });
    });

    group('fromJson', () {
      test('should create model from json with all fields', () {
        final json = {
          'id': 1,
          'title': 'JSON Project',
          'description': 'JSON Description',
          'sessionCount': 5,
          'duration': 9000000,
          'createdAt': tCreatedAt.toIso8601String(),
          'updatedAt': tUpdatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromJson(json);

        expect(model.id, 1);
        expect(model.title, 'JSON Project');
        expect(model.description, 'JSON Description');
        expect(model.sessionCount, 5);
        expect(model.duration, const Duration(milliseconds: 9000000));
        expect(model.createdAt, tCreatedAt);
        expect(model.updatedAt, tUpdatedAt);
      });

      test('should create model from json without optional fields', () {
        final json = {
          'title': 'Minimal JSON',
          'createdAt': tCreatedAt.toIso8601String(),
        };

        final model = ProjectModel.fromJson(json);

        expect(model.id, isNull);
        expect(model.title, 'Minimal JSON');
        expect(model.description, isNull);
        expect(model.sessionCount, 0);
        expect(model.duration, Duration.zero);
        expect(model.createdAt, tCreatedAt);
        expect(model.updatedAt, isNull);
      });
    });

    group('toMap', () {
      test('should convert model to map with all fields', () {
        final map = tModel.toMap();

        expect(map['id'], 1);
        expect(map['title'], 'Test Project');
        expect(map['description'], 'Test Description');
        expect(map['session_count'], 5);
        expect(map['duration'], 9000000); // 2h 30min in milliseconds
        expect(map['created_at'], tCreatedAt.toIso8601String());
        expect(map['updated_at'], tUpdatedAt.toIso8601String());
      });

      test('should convert model to map without null fields', () {
        final model = ProjectModel(title: 'Simple', createdAt: tCreatedAt);

        final map = model.toMap();

        expect(map.containsKey('id'), isFalse);
        expect(map['title'], 'Simple');
        expect(map.containsKey('description'), isFalse);
        expect(map['session_count'], 0);
        expect(map['duration'], 0);
        expect(map['created_at'], tCreatedAt.toIso8601String());
        expect(map.containsKey('updated_at'), isFalse);
      });

      test('should store duration as milliseconds', () {
        final model = ProjectModel(
          title: 'Project',
          duration: const Duration(hours: 3, minutes: 45, seconds: 30),
          createdAt: tCreatedAt,
        );

        final map = model.toMap();

        expect(
          map['duration'],
          const Duration(hours: 3, minutes: 45, seconds: 30).inMilliseconds,
        );
      });
    });

    group('toJson', () {
      test('should convert model to json with all fields', () {
        final json = tModel.toJson();

        expect(json['id'], 1);
        expect(json['title'], 'Test Project');
        expect(json['description'], 'Test Description');
        expect(json['sessionCount'], 5);
        expect(json['duration'], 9000000);
        expect(json['createdAt'], tCreatedAt.toIso8601String());
        expect(json['updatedAt'], tUpdatedAt.toIso8601String());
      });

      test('should convert model to json without null fields', () {
        final model = ProjectModel(title: 'Simple', createdAt: tCreatedAt);

        final json = model.toJson();

        expect(json.containsKey('id'), isFalse);
        expect(json['title'], 'Simple');
        expect(json.containsKey('description'), isFalse);
        expect(json['sessionCount'], 0);
        expect(json['duration'], 0);
        expect(json['createdAt'], tCreatedAt.toIso8601String());
        expect(json.containsKey('updatedAt'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated id', () {
        final copied = tModel.copyWith(id: 999);

        expect(copied, isA<ProjectModel>());
        expect(copied.id, 999);
        expect(copied.title, tModel.title);
        expect(copied.description, tModel.description);
      });

      test('should create copy with updated title', () {
        final copied = tModel.copyWith(title: 'Updated Title');

        expect(copied.title, 'Updated Title');
        expect(copied.id, tModel.id);
      });

      test('should create copy with no changes when no params provided', () {
        final copied = tModel.copyWith();

        expect(copied.id, tModel.id);
        expect(copied.title, tModel.title);
        expect(copied.description, tModel.description);
        expect(copied.sessionCount, tModel.sessionCount);
        expect(copied.duration, tModel.duration);
        expect(copied.createdAt, tModel.createdAt);
        expect(copied.updatedAt, tModel.updatedAt);
      });
    });

    group('serialization round-trip', () {
      test('should maintain data through toMap -> fromMap', () {
        final map = tModel.toMap();
        final reconstructed = ProjectModel.fromMap(map);

        expect(reconstructed.id, tModel.id);
        expect(reconstructed.title, tModel.title);
        expect(reconstructed.description, tModel.description);
        expect(reconstructed.sessionCount, tModel.sessionCount);
        expect(reconstructed.duration, tModel.duration);
        expect(reconstructed.createdAt, tModel.createdAt);
        expect(reconstructed.updatedAt, tModel.updatedAt);
      });

      test('should maintain data through toJson -> fromJson', () {
        final json = tModel.toJson();
        final reconstructed = ProjectModel.fromJson(json);

        expect(reconstructed.id, tModel.id);
        expect(reconstructed.title, tModel.title);
        expect(reconstructed.description, tModel.description);
        expect(reconstructed.sessionCount, tModel.sessionCount);
        expect(reconstructed.duration, tModel.duration);
        expect(reconstructed.createdAt, tModel.createdAt);
        expect(reconstructed.updatedAt, tModel.updatedAt);
      });
    });

    group('equality', () {
      test('should support equality comparison between models', () {
        final model2 = ProjectModel(
          id: 1,
          title: 'Test Project',
          description: 'Test Description',
          sessionCount: 5,
          duration: const Duration(hours: 2, minutes: 30),
          createdAt: tCreatedAt,
          updatedAt: tUpdatedAt,
        );

        expect(tModel, equals(model2));
      });
    });
  });
}
