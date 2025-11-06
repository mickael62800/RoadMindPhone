import 'package:uuid/uuid.dart';
import 'package:roadmindphone/session.dart';

/// Legacy Project class for backward compatibility
///
/// This class is kept to maintain compatibility with:
/// - database_helper.dart
/// - Existing tests (project_test.dart)
/// - Old pages not yet migrated (project_index_page.dart, etc.)
///
/// New code should use ProjectEntity from the Clean Architecture.
class Project {
  final String id;
  final String title;
  final String? description;
  final int sessionCount;
  final Duration duration;
  final List<Session>? sessions;

  Project({
    String? id,
    required this.title,
    this.description,
    this.sessionCount = 0,
    this.duration = Duration.zero,
    this.sessions,
  }) : id = id ?? const Uuid().v4();

  Project copy({
    String? id,
    String? title,
    String? description,
    int? sessionCount,
    Duration? duration,
    List<Session>? sessions,
  }) => Project(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    sessionCount: sessionCount ?? this.sessionCount,
    duration: duration ?? this.duration,
    sessions: sessions ?? this.sessions,
  );

  static Project fromMap(Map<String, dynamic> map) => Project(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
  };
}
