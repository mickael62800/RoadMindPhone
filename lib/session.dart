import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:roadmindphone/session_gps_point.dart';

class Session {
  final String id;
  final String projectId;
  final String name;
  final Duration duration;
  final int gpsPoints;
  final String? videoPath;
  final List<SessionGpsPoint> gpsData;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;
  final bool exported;

  Session({
    String? id,
    required this.projectId,
    required this.name,
    required this.duration,
    required this.gpsPoints,
    this.videoPath,
    this.gpsData = const [],
    this.startTime,
    this.endTime,
    this.notes,
    this.exported = false,
  }) : id = id ?? const Uuid().v4();

  Session copy({
    String? id,
    String? projectId,
    String? name,
    Duration? duration,
    int? gpsPoints,
    String? videoPath,
    List<SessionGpsPoint>? gpsData,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? exported,
  }) => Session(
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
    exported: exported ?? this.exported,
  );

  static Session fromMap(Map<String, dynamic> map) => Session(
    id: map['id'] as String,
    projectId: map['projectId'] as String,
    name: map['name'] as String,
    duration: Duration(milliseconds: map['duration'] as int),
    gpsPoints: map['gpsPoints'] as int,
    videoPath: map['videoPath'] as String?,
    gpsData: map['gpsData'] == null
        ? []
        : (json.decode(map['gpsData'] as String) as List)
              .map((e) => SessionGpsPoint.fromMap(e as Map<String, dynamic>))
              .toList(),
    startTime: map['startTime'] != null
        ? DateTime.parse(map['startTime'] as String)
        : null,
    endTime: map['endTime'] != null
        ? DateTime.parse(map['endTime'] as String)
        : null,
    notes: map['notes'] as String?,
    exported: map['exported'] == 1 || map['exported'] == true,
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
    'exported': exported ? 1 : 0,
  };
}
