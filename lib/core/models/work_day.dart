class WorkDay {
  final String userId;
  final String date;

  final DateTime? firstStartedAt;
  final DateTime? lastEndedAt;

  final int totalWorkSeconds;
  final int totalTrackedSeconds;

  final int sessionCount;

  final Map<String, ApplicationSummary> applications;

  WorkDay({
    required this.userId,
    required this.date,
    this.firstStartedAt,
    this.lastEndedAt,
    required this.totalWorkSeconds,
    required this.totalTrackedSeconds,
    required this.sessionCount,
    required this.applications,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'firstStartedAt': firstStartedAt?.toIso8601String(),
      'lastEndedAt': lastEndedAt?.toIso8601String(),
      'totalWorkSeconds': totalWorkSeconds,
      'totalTrackedSeconds': totalTrackedSeconds,
      'sessionCount': sessionCount,
      'applications': applications.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }
}

class ApplicationSummary {
  final int durationSeconds;
  final int sessionCount;

  ApplicationSummary({
    required this.durationSeconds,
    required this.sessionCount,
  });

  Map<String, dynamic> toMap() {
    return {'durationSeconds': durationSeconds, 'sessionCount': sessionCount};
  }
}
