import 'package:flutter/services.dart';

class ActivityService {
  static const MethodChannel _channel =
      MethodChannel('work_activity_monitor/activity');

  Future<Map<String, dynamic>?> getActiveWindow() async {
    try {
      final result = await _channel.invokeMethod(
        'getActiveWindow',
      );

      if (result == null) {
        return null;
      }

      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('Activity service error: ${e.message}');
      return null;
    }
  }
}