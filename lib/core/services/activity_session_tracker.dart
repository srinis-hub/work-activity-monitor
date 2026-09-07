import '../models/activity_session.dart';

class ApplicationSummary {
  final String application;
  final Duration totalDuration;
  final int sessionCount;

  ApplicationSummary({
    required this.application,
    required this.totalDuration,
    required this.sessionCount,
  });
}

class ActivitySessionTracker {
  ActivitySession? _currentSession;

  final List<ActivitySession> _completedSessions = [];
  bool _isTracking = false;
  bool get isTracking => _isTracking;
  List<ActivitySession> get completedSessions =>
      List.unmodifiable(_completedSessions);

  void startTracking() {
    if (_isTracking) {
      return;
    }
    _isTracking = true;
    _currentSession = null;
    _completedSessions.clear();
  }

  void updateActivity({
    required String application,
    required String windowTitle,
    required int processId,
  }) {
    if (!_isTracking) {
      return;
    }

    if (application.isEmpty) {
      return;
    }

    if (_isOwnApplication(application)) {
      return;
    }

    final now = DateTime.now();

    if (_currentSession == null) {
      _currentSession = ActivitySession(
        application: application,
        windowTitle: windowTitle,
        processId: processId,
        startedAt: now,
        endedAt: now,
        duration: Duration.zero,
      );

      return;
    }

    final current = _currentSession!;

    if (current.application == application &&
        current.windowTitle == windowTitle) {
      return;
    }

    _closeCurrentSession(now);

    _currentSession = ActivitySession(
      application: application,
      windowTitle: windowTitle,
      processId: processId,
      startedAt: now,
      endedAt: now,
      duration: Duration.zero,
    );
  }

  List<ActivitySession> stopTracking() {
    if (!_isTracking) {
      return List.unmodifiable(_completedSessions);
    }

    _isTracking = false;

    final endedAt = DateTime.now();

    _closeCurrentSession(endedAt);

    _currentSession = null;

    return List.unmodifiable(_completedSessions);
  }

  void _closeCurrentSession(DateTime endedAt) {
    final current = _currentSession;

    if (current == null) {
      return;
    }

    final duration = endedAt.difference(current.startedAt);

    if (duration.inMilliseconds <= 0) {
      _currentSession = null;
      return;
    }

    final completedSession = ActivitySession(
      application: current.application,
      windowTitle: current.windowTitle,
      processId: current.processId,
      startedAt: current.startedAt,
      endedAt: endedAt,
      duration: duration,
    );

    _completedSessions.add(completedSession);
    _currentSession = null;
  }

  List<ApplicationSummary> createSummary(List<ActivitySession> sessions) {
    final Map<String, _ApplicationAccumulator> grouped = {};

    for (final session in sessions) {
      final existing = grouped[session.application];

      if (existing == null) {
        grouped[session.application] = _ApplicationAccumulator(
          duration: session.duration,
          sessionCount: 1,
        );
      } else {
        existing.duration += session.duration;
        existing.sessionCount++;
      }
    }

    final summary = grouped.entries.map((entry) {
      return ApplicationSummary(
        application: entry.key,
        totalDuration: entry.value.duration,
        sessionCount: entry.value.sessionCount,
      );
    }).toList();

    summary.sort((a, b) => b.totalDuration.compareTo(a.totalDuration));

    return summary;
  }

  void reset() {
    _isTracking = false;

    _currentSession = null;

    _completedSessions.clear();
  }

  bool _isOwnApplication(String application) {
    final normalized = application.toLowerCase();

    return normalized == 'work_activity_monitor.exe' ||
        normalized == 'work_activity_monitor';
  }
}

class _ApplicationAccumulator {
  Duration duration;
  int sessionCount;

  _ApplicationAccumulator({required this.duration, required this.sessionCount});
}
