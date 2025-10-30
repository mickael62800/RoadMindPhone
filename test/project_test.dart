import 'package:flutter_test/flutter_test.dart';
import 'package:roadmindphone/main.dart'; // Assuming Project class is in main.dart

void main() {
  group('Project', () {
    test('Project can be created with required fields', () {
      final project = Project(title: 'Test Project');
      expect(project.title, 'Test Project');
      expect(project.id, isNull);
      expect(project.sessionCount, 0);
      expect(project.duration, Duration.zero);
    });

    test('Project can be created with all fields', () {
      final project = Project(
        id: 1,
        title: 'Test Project 2',
        sessionCount: 5,
        duration: const Duration(hours: 1),
      );
      expect(project.id, 1);
      expect(project.title, 'Test Project 2');
      expect(project.sessionCount, 5);
      expect(project.duration, const Duration(hours: 1));
    });

    test('Project.copy creates a new instance with updated values', () {
      final originalProject = Project(
        id: 1,
        title: 'Original Title',
        sessionCount: 10,
        duration: const Duration(minutes: 30),
      );

      final updatedProject = originalProject.copy(
        title: 'Updated Title',
        sessionCount: 15,
      );

      expect(updatedProject.id, originalProject.id);
      expect(updatedProject.title, 'Updated Title');
      expect(updatedProject.sessionCount, 15);
      expect(updatedProject.duration, originalProject.duration);
      expect(originalProject.title, 'Original Title'); // Ensure original is unchanged
    });

    test('Project.fromMap creates a Project object from a map', () {
      final map = {'id': 1, 'title': 'Mapped Project'};
      final project = Project.fromMap(map);
      expect(project.id, 1);
      expect(project.title, 'Mapped Project');
      expect(project.sessionCount, 0);
      expect(project.duration, Duration.zero);
    });

    test('Project.toMap converts a Project object to a map', () {
      final project = Project(id: 2, title: 'Project to Map');
      final map = project.toMap();
      expect(map['id'], 2);
      expect(map['title'], 'Project to Map');
      expect(map.length, 3); // Only id and title are stored in DB
    });
  });
}
