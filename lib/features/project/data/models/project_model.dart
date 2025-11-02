import 'package:roadmindphone/core/utils/typedef.dart';
import 'package:roadmindphone/features/project/domain/entities/project_entity.dart';

/// Data model for Project
///
/// This model extends ProjectEntity and adds serialization capabilities.
/// It handles conversion between domain entities and data layer representations
/// (JSON for API, Map for SQLite).
class ProjectModel extends ProjectEntity {
  const ProjectModel({
    super.id,
    required super.title,
    super.description,
    super.sessionCount = 0,
    super.duration = Duration.zero,
    required super.createdAt,
    super.updatedAt,
  });

  /// Creates a ProjectModel from a ProjectEntity
  factory ProjectModel.fromEntity(ProjectEntity entity) {
    return ProjectModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      sessionCount: entity.sessionCount,
      duration: entity.duration,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Creates a ProjectModel from a Map (from database)
  factory ProjectModel.fromMap(DataMap map) {
    return ProjectModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      sessionCount: map['sessionCount'] as int? ?? 0,
      duration: Duration(milliseconds: map['duration'] as int? ?? 0),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Creates a ProjectModel from JSON
  factory ProjectModel.fromJson(DataMap json) {
    return ProjectModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      sessionCount: json['sessionCount'] as int? ?? 0,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this model to a Map (for database)
  DataMap toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'sessionCount': sessionCount,
      'duration': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Converts this model to JSON
  DataMap toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (description != null) 'description': description,
      'sessionCount': sessionCount,
      'duration': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this model with updated fields
  @override
  ProjectModel copyWith({
    int? id,
    String? title,
    String? description,
    int? sessionCount,
    Duration? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sessionCount: sessionCount ?? this.sessionCount,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
