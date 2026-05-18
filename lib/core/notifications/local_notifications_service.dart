import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationsService {
  LocalNotificationsService._();
  static final LocalNotificationsService instance = LocalNotificationsService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Amman'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  Future<void> scheduleMatchReminders({
    required int fixtureId,
    required String homeTeam,
    required String awayTeam,
    required DateTime kickoff,
  }) async {
    if (kIsWeb) return;
    await init();
    const androidDetails = AndroidNotificationDetails(
      'match_alerts',
      'Match Alerts',
      channelDescription: 'Prediction deadline and result reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    final deadline = kickoff.subtract(const Duration(hours: 4));
    final resultTime = kickoff.add(const Duration(hours: 2));
    final now = DateTime.now();

    if (deadline.isAfter(now)) {
      await _plugin.zonedSchedule(
        fixtureId * 10 + 1,
        'Prediction closing soon',
        "$homeTeam vs $awayTeam going to start soon , predict if you didn't !!",
        tz.TZDateTime.from(deadline, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (resultTime.isAfter(now)) {
      await _plugin.zonedSchedule(
        fixtureId * 10 + 2,
        'Match result update',
        '$homeTeam vs $awayTeam may be finished. Check your prediction results.',
        tz.TZDateTime.from(resultTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelMatchReminders(int fixtureId) async {
    if (kIsWeb) return;
    await init();
    await _plugin.cancel(fixtureId * 10 + 1);
    await _plugin.cancel(fixtureId * 10 + 2);
  }
}
