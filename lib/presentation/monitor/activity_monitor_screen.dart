import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/work_session.dart';
import '../../core/services/activity_service.dart';
import '../../core/services/activity_session_tracker.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/date_utils.dart';
import '../../data/repositories/work_session_repository.dart';

class ActivityMonitorScreen extends StatefulWidget {
  const ActivityMonitorScreen({super.key});

  @override
  State<ActivityMonitorScreen> createState() => _ActivityMonitorScreenState();
}

class _ActivityMonitorScreenState extends State<ActivityMonitorScreen> {
  final ActivityService _activityService = ActivityService();
  final AuthService _authService = AuthService();
  final WorkSessionRepository _workSessionRepository = WorkSessionRepository();

  final ActivitySessionTracker _sessionTracker = ActivitySessionTracker();

  Timer? _sessionTimer;
  Timer? _activityTimer;

  DateTime? _workSessionStartedAt;

  bool _isMonitoring = false;

  Duration _sessionDuration = Duration.zero;

  String _currentApplication = '--';
  String _currentWindowTitle = '--';

  static const Color _background = Color(0xFF080B18);
  static const Color _cardColor = Color(0xFF11162A);

  static const Color _purple = Color(0xFF8B3DFF);
  static const Color _blue = Color(0xFF4E6CFF);
  static const Color _cyan = Color(0xFF19C9ED);

  static const Color _textPrimary = Color(0xFFF5F7FF);
  static const Color _textSecondary = Color(0xFF9CA8C8);
  static const Color _border = Color(0xFF293456);

  void _startWork() {
    if (_isMonitoring) {
      return;
    }

    final now = DateTime.now();

    _sessionTracker.reset();
    _sessionTracker.startTracking();

    setState(() {
      _isMonitoring = true;
      _sessionDuration = Duration.zero;
      _workSessionStartedAt = now;
      _currentApplication = 'Starting...';
      _currentWindowTitle = '--';
    });

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isMonitoring) {
        return;
      }

      setState(() {
        _sessionDuration += const Duration(seconds: 1);
      });
    });

    _startActivityMonitoring();
  }

  void _startActivityMonitoring() {
    _activityTimer?.cancel();

    _checkActiveWindow();

    _activityTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkActiveWindow();
    });
  }

  Future<void> _checkActiveWindow() async {
    if (!mounted || !_isMonitoring) {
      return;
    }

    try {
      final result = await _activityService.getActiveWindow();

      if (!mounted || !_isMonitoring || result == null) {
        return;
      }

      final application = result['application']?.toString() ?? '';

      final windowTitle = result['windowTitle']?.toString() ?? '';

      final processId =
          int.tryParse(result['processId']?.toString() ?? '') ?? 0;

      if (application.isEmpty) {
        return;
      }

      if (_isSystemScreen(application)) {
        debugPrint(
          'IGNORED SYSTEM WINDOW: '
          '$application | $windowTitle',
        );

        setState(() {
          _currentApplication = 'System / Idle';
          _currentWindowTitle = windowTitle.isEmpty
              ? 'Windows Lock Screen'
              : windowTitle;
        });

        return;
      }

      setState(() {
        _currentApplication = application;
        _currentWindowTitle = windowTitle.isEmpty ? '--' : windowTitle;
      });

      _sessionTracker.updateActivity(
        application: application,
        windowTitle: windowTitle,
        processId: processId,
      );
    } catch (e) {
      debugPrint('ACTIVE WINDOW ERROR: $e');
    }
  }

  Future<void> _stopWork() async {
    if (!_isMonitoring) {
      return;
    }

    _sessionTimer?.cancel();
    _sessionTimer = null;

    _activityTimer?.cancel();
    _activityTimer = null;

    final endedAt = DateTime.now();

    final activities = _sessionTracker.stopTracking();

    final startedAt = _workSessionStartedAt ?? endedAt;

    final workSession = WorkSession(
      userId: FirebaseAuth.instance.currentUser!.uid,
      workDate: AppDateUtils.workDate(startedAt),
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startedAt: startedAt,
      endedAt: endedAt,
      totalDuration: endedAt.difference(startedAt),
      activities: activities,
    );

    try {
      await _workSessionRepository.saveWorkSession(workSession);

      debugPrint('WORK SESSION SAVED TO FIRESTORE');
    } catch (e) {
      debugPrint('FAILED TO SAVE WORK SESSION: $e');
    }

    final summary = _sessionTracker.createSummary(activities);

    if (summary.isEmpty) {
      debugPrint('No application activities recorded.');
    }

    for (final item in summary) {
      debugPrint(
        '${item.application} '
        '→ ${item.totalDuration.inSeconds}s '
        '(${item.sessionCount} sessions)',
      );
    }

    for (final activity in activities) {
      debugPrint(
        '${activity.application} '
        '| ${activity.duration.inSeconds}s '
        '| ${activity.windowTitle}',
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isMonitoring = false;
      _currentApplication = '--';
      _currentWindowTitle = '--';
      _workSessionStartedAt = null;
    });
  }

  Future<void> _logout() async {
    if (_isMonitoring) {
      await _stopWork();
    }

    await _authService.logout();
  }

  bool _isSystemScreen(String application) {
    final normalized = application.toLowerCase();

    return normalized == 'lockapp.exe';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');

    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          Positioned(
            top: -180,
            left: -180,
            child: _GlowCircle(
              size: 420,
              color: _purple.withValues(alpha: 0.18),
            ),
          ),

          Positioned(
            bottom: -220,
            right: -180,
            child: _GlowCircle(size: 460, color: _blue.withValues(alpha: 0.18)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(user),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: _buildDashboard(),
                      ),
                    ),
                  ),
                ),

                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(User? user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(colors: [_purple, _blue, _cyan]),
            ),
            child: const Icon(
              Icons.monitor_heart_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Work Activity Monitor',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Work session dashboard',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),

          const Spacer(),

          if (user?.email != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 17,
                    color: _textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user!.email!,
                    style: const TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 12),

          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            style: IconButton.styleFrom(
              backgroundColor: _cardColor,
              foregroundColor: _textSecondary,
              side: const BorderSide(color: _border),
            ),
            icon: const Icon(Icons.logout_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        _buildStatusCard(),

        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildCurrentActivityCard()),

            const SizedBox(width: 20),

            Expanded(child: _buildDurationCard()),
          ],
        ),

        const SizedBox(height: 20),

        _buildControlCard(),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isMonitoring ? _cyan.withValues(alpha: 0.45) : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isMonitoring
                  ? _cyan.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.05),
            ),
            child: Icon(
              _isMonitoring
                  ? Icons.radar_rounded
                  : Icons.pause_circle_outline_rounded,
              color: _isMonitoring ? _cyan : _textSecondary,
              size: 30,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMonitoring ? 'Monitoring is active' : 'Ready to start',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isMonitoring
                      ? 'Your active application is being tracked.'
                      : 'Start a work session when you are ready.',
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isMonitoring
            ? _cyan.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isMonitoring ? _cyan.withValues(alpha: 0.35) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isMonitoring ? _cyan : _textSecondary,
              shape: BoxShape.circle,
              boxShadow: _isMonitoring
                  ? [
                      BoxShadow(
                        color: _cyan.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isMonitoring ? 'LIVE' : 'IDLE',
            style: TextStyle(
              color: _isMonitoring ? _cyan : _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentActivityCard() {
    return _DashboardCard(
      icon: Icons.apps_rounded,
      iconColor: _purple,
      title: 'Current Application',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),

          Text(
            _currentApplication,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.window_rounded, color: _textSecondary, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentWindowTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard() {
    return _DashboardCard(
      icon: Icons.timer_outlined,
      iconColor: _cyan,
      title: 'Session Duration',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 15),

          Text(
            _formatDuration(_sessionDuration),
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isMonitoring ? 'Current work session' : 'No active session',
            style: const TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isMonitoring
                      ? 'Work session in progress'
                      : 'Ready for your work session?',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isMonitoring
                      ? 'Activity monitoring is currently running.'
                      : 'Start monitoring to record your work activity.',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          _buildMainActionButton(),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    return SizedBox(
      width: 180,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: _isMonitoring
                ? const [Color(0xFFFF416C), Color(0xFFFF4B2B)]
                : const [_purple, _blue, _cyan],
          ),
          boxShadow: [
            BoxShadow(
              color: (_isMonitoring ? Colors.red : _purple).withValues(
                alpha: 0.22,
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isMonitoring ? _stopWork : _startWork,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
                size: 23,
              ),
              const SizedBox(width: 9),
              Text(
                _isMonitoring ? 'STOP WORK' : 'START WORK',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18, left: 20, right: 20),
      child: Text(
        'Your work matters. Track it.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF626D8D), fontSize: 12),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _activityTimer?.cancel();

    super.dispose();
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF11162A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF293456)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9CA8C8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 30)],
      ),
    );
  }
}
