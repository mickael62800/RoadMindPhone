import 'package:equatable/equatable.dart';

/// Domain entity representing a Project
///
/// A Project is a container for recording sessions.
/// It's a pure Dart class with no dependencies on Flutter or external packages
/// (except Equatable for value equality).
///
/// Business rules:
/// - A project must have a title (non-empty)
/// - Description is optional
/// - Sessions can be associated with a project
class ProjectEntity extends Equatable {
  /// Unique identifier for the project (null for new projects)
  final int? id;

  /// Title of the project (required, non-empty)
  final String title;

  /// Optional description of the project
  final String? description;

  /// Number of sessions in this project
  final int sessionCount;

  /// Total duration of all sessions in this project
  final Duration duration;

  /// Timestamp when the project was created
  final DateTime createdAt;

  /// Timestamp when the project was last updated
  final DateTime? updatedAt;

  const ProjectEntity({
    this.id,
    required this.title,
    this.description,
    this.sessionCount = 0,
    this.duration = Duration.zero,
    required this.createdAt,
    this.updatedAt,
  });

  /// Creates a copy of this entity with the given fields replaced
  ProjectEntity copyWith({
    int? id,
    String? title,
    String? description,
    int? sessionCount,
    Duration? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sessionCount: sessionCount ?? this.sessionCount,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Business rule validation: Check if the project has a valid title
  bool get hasValidTitle => title.trim().isNotEmpty;

  /// Business rule: Check if the project has any sessions
  bool get hasSessions => sessionCount > 0;

  /// Business rule: Check if the project is new (not yet persisted)
  bool get isNew => id == null;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    sessionCount,
    duration,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'ProjectEntity('
        'id: $id, '
        'title: $title, '
        'description: $description, '
        'sessionCount: $sessionCount, '
        'duration: $duration, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
