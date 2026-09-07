import 'activity_session.dart';

class WorkSession {
  final String sessionId;
  final String userId;
  final String workDate;

  final DateTime startedAt;
  final DateTime endedAt;

  final Duration totalDuration;

  final List<ActivitySession> activities;

  WorkSession({
    required this.sessionId,
    required this.userId,
    required this.workDate,
    required this.startedAt,
    required this.endedAt,
    required this.totalDuration,
    required this.activities,
  });

  int get totalDurationSeconds => totalDuration.inSeconds;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'workDate': workDate,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'totalDurationSeconds': totalDurationSeconds,
      'activities': activities.map((activity) => activity.toMap()).toList(),
    };
  }
}
