import 'package:roadmindphone/features/session/domain/entities/session_entity.dart';
import 'package:roadmindphone/session_gps_point.dart';

/// Data model for Session
///
/// Extends SessionEntity and adds serialization methods for database operations.
/// Handles conversion between entity (domain) and map (database) representations.
class SessionModel extends SessionEntity {
  const SessionModel({
    required super.id,
    required super.projectId,
    required super.name,
    required super.duration,
    required super.gpsPoints,
    super.videoPath,
    super.gpsData,
    super.startTime,
    super.endTime,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.exported = false,
  });

  /// Creates a SessionModel from a SessionEntity
  factory SessionModel.fromEntity(SessionEntity entity) {
    return SessionModel(
      id: entity.id,
      projectId: entity.projectId,
      name: entity.name,
      duration: entity.duration,
      gpsPoints: entity.gpsPoints,
      videoPath: entity.videoPath,
      gpsData: entity.gpsData,
      startTime: entity.startTime,
      endTime: entity.endTime,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      exported: entity.exported,
    );
  }

  /// Creates a SessionModel from a database map
  ///
  /// Note: GPS points are loaded separately from the database
  factory SessionModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return SessionModel(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      name: map['name'] as String,
      duration: Duration(seconds: map['duration'] as int),
      gpsPoints: map['gpsPoints'] as int,
      videoPath: map['videoPath'] as String?,
      gpsData: const [], // GPS data loaded separately
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : now,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      exported: map['exported'] == 1 || map['exported'] == true,
    );
  }

  /// Creates a SessionModel from a database map with GPS data
  ///
  /// Used when GPS points have been loaded from the database
  factory SessionModel.fromMapWithGpsData(
    Map<String, dynamic> map,
    List<SessionGpsPoint> gpsData,
  ) {
    final now = DateTime.now();
    return SessionModel(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      name: map['name'] as String,
      duration: Duration(seconds: map['duration'] as int),
      gpsPoints: map['gpsPoints'] as int,
      videoPath: map['videoPath'] as String?,
      gpsData: gpsData,
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : now,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      exported: map['exported'] == 1 || map['exported'] == true,
    );
  }

  /// Converts this model to a database map
  ///
  /// Note: GPS points are saved separately to the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'duration': duration.inSeconds,
      'gpsPoints': gpsPoints,
      'videoPath': videoPath,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'exported': exported ? 1 : 0,
    };
  }

  /// Converts this model to a SessionEntity
  SessionEntity toEntity() {
    return SessionEntity(
      id: id,
      projectId: projectId,
      name: name,
      duration: duration,
      gpsPoints: gpsPoints,
      videoPath: videoPath,
      gpsData: gpsData,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      exported: exported,
    );
  }

  /// Creates a copy of this model with updated fields
  @override
  SessionModel copyWith({
    int? id,
    int? projectId,
    String? name,
    Duration? duration,
    int? gpsPoints,
    String? videoPath,
    List<SessionGpsPoint>? gpsData,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? exported,
  }) {
    return SessionModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      gpsPoints: gpsPoints ?? this.gpsPoints,
      videoPath: videoPath ?? this.videoPath,
      gpsData: gpsData ?? this.gpsData,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exported: exported ?? this.exported,
    );
  }
}
