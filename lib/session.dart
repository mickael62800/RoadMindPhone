import 'dart:convert';
import 'package:roadmindphone/session_gps_point.dart';

class Session {
  final int? id;
  final int projectId;
  final String name;
  final Duration duration;
  final int gpsPoints;
  final String? videoPath;
  final List<SessionGpsPoint> gpsData;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;

  Session({
    this.id,
    required this.projectId,
    required this.name,
    required this.duration,
    required this.gpsPoints,
    this.videoPath,
    this.gpsData = const [],
    this.startTime,
    this.endTime,
    this.notes,
  });

  Session copy({
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
  }) =>
      Session(
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
      );

  static Session fromMap(Map<String, dynamic> map) => Session(
        id: map['id'] as int?,
        projectId: map['projectId'] as int,
        name: map['name'] as String,
        duration: Duration(milliseconds: map['duration'] as int),
        gpsPoints: map['gpsPoints'] as int,
        videoPath: map['videoPath'] as String?,
        gpsData: map['gpsData'] == null
            ? []
            : (json.decode(map['gpsData'] as String) as List)
                .map((e) => SessionGpsPoint.fromMap(e as Map<String, dynamic>))
                .toList(),
        startTime: map['startTime'] != null ? DateTime.parse(map['startTime'] as String) : null,
        endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'duration': duration.inMilliseconds,
        'gpsPoints': gpsPoints,
        'videoPath': videoPath,
        'gpsData': json.encode(gpsData.map((e) => e.toMap()).toList()),
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'notes': notes,
      };
}
