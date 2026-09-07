class ActivitySession {
  final String application;
  final String windowTitle;
  final int processId;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;

  ActivitySession({
    required this.application,
    required this.windowTitle,
    required this.processId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
  });

  int get durationSeconds => duration.inSeconds;

  Map<String, dynamic> toMap() {
    return {
      'application': application,
      'windowTitle': windowTitle,
      'processId': processId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  factory ActivitySession.fromMap(
    Map<String, dynamic> map,
  ) {
    return ActivitySession(
      application:
          map['application'] as String? ?? '',
      windowTitle:
          map['windowTitle'] as String? ?? '',
      processId:
          map['processId'] as int? ?? 0,
      startedAt:
          DateTime.parse(map['startedAt'] as String),
      endedAt:
          DateTime.parse(map['endedAt'] as String),
      duration: Duration(
        seconds:
            map['durationSeconds'] as int? ?? 0,
      ),
    );
  }
}

