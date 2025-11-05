import 'package:equatable/equatable.dart';
import 'package:roadmindphone/session_gps_point.dart';

/// Domain entity representing a recording Session
///
/// A Session belongs to a Project and contains GPS tracking data,
/// video recording, and timing information.
///
/// Business rules:
/// - A session must have a name (non-empty)
/// - A session must belong to a project (projectId)
/// - Duration is calculated from startTime and endTime
/// - GPS points are optional but tracked for analytics
class SessionEntity extends Equatable {
  /// Indique si la session a été exportée
  final bool exported;

  /// Unique identifier for the session (null for new sessions)
  final int? id;

  /// ID of the project this session belongs to
  final int projectId;

  /// Name/title of the session (required, non-empty)
  final String name;

  /// Total duration of the recording session
  final Duration duration;

  /// Number of GPS points recorded during the session
  final int gpsPoints;

  /// Path to the video file recorded during the session
  final String? videoPath;

  /// List of GPS tracking data points
  final List<SessionGpsPoint> gpsData;

  /// Timestamp when the recording started
  final DateTime? startTime;

  /// Timestamp when the recording ended
  final DateTime? endTime;

  /// Optional notes/comments about the session
  final String? notes;

  /// Timestamp when the session was created
  final DateTime createdAt;

  /// Timestamp when the session was last updated
  final DateTime? updatedAt;

  const SessionEntity({
    this.id,
    required this.projectId,
    required this.name,
    this.duration = Duration.zero,
    this.gpsPoints = 0,
    this.videoPath,
    this.gpsData = const [],
    this.startTime,
    this.endTime,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.exported = false,
  });

  /// Creates a copy of this entity with the given fields replaced
  SessionEntity copyWith({
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
    return SessionEntity(
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

  /// Business rule validation: Check if the session has a valid name
  bool get hasValidName => name.trim().isNotEmpty;

  /// Business rule: Check if the session has GPS data
  bool get hasGpsData => gpsPoints > 0 && gpsData.isNotEmpty;

  /// Business rule: Check if the session has a video recording
  bool get hasVideo => videoPath != null && videoPath!.isNotEmpty;

  /// Business rule: Check if the session is currently recording
  bool get isRecording => startTime != null && endTime == null;

  /// Business rule: Check if the session is completed
  bool get isCompleted => startTime != null && endTime != null;

  /// Business rule: Check if the session is new (not yet persisted)
  bool get isNew => id == null;

  @override
  List<Object?> get props => [
    id,
    projectId,
    name,
    duration,
    gpsPoints,
    videoPath,
    gpsData,
    startTime,
    endTime,
    notes,
    createdAt,
    updatedAt,
    exported,
  ];

  @override
  String toString() {
    return 'SessionEntity('
        'id: $id, '
        'projectId: $projectId, '
        'name: $name, '
        'duration: $duration, '
        'gpsPoints: $gpsPoints, '
        'videoPath: $videoPath, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt, '
        'exported: $exported'
        ')';
  }
}
