import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/daily_plan.dart';
import '../models/session_plan.dart';

/// Local notifications for daily practice times (no FCM).
class ReminderService {
  ReminderService._();

  static final ReminderService instance = ReminderService._();

  static const String channelId = 'speech_practice_reminders';
  static const String channelName = 'Speech Practice Reminders';

  static const int _slotPrimary = 0;
  static const int _slotFollowUp = 1;

  /// Does not overlap with hashed session notification ids.
  static const int debugNotificationId = 0xdeb00101;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final Map<String, int> _followUpNotificationIdBySessionId =
      <String, int>{};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _configureLocalTimeZone();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: 'Scheduled speech practice reminders.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(channel);

      await android?.requestNotificationsPermission();
    }

    if (!kIsWeb && Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // MVP: no navigation from notification taps.
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || Platform.isLinux) {
      return;
    }
    tz_data.initializeTimeZones();
    if (Platform.isWindows) {
      return;
    }
    final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  }

  NotificationDetails _notificationDetails() {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Scheduled speech practice reminders.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    return const NotificationDetails(android: android, iOS: ios);
  }

  int _stableNotificationId(
    String planDate,
    String sessionId,
    int index,
    int slot,
  ) {
    return Object.hash(planDate, sessionId, index, slot) & 0x7fffffff;
  }

  tz.TZDateTime? _dateTimeOnPlanDay(String planDate, int hour, int minute) {
    final RegExpMatch? m =
        RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(planDate);
    if (m == null) {
      return null;
    }
    final int? y = int.tryParse(m.group(1)!);
    final int? mo = int.tryParse(m.group(2)!);
    final int? d = int.tryParse(m.group(3)!);
    if (y == null || mo == null || d == null) {
      return null;
    }
    return tz.TZDateTime(tz.local, y, mo, d, hour, minute);
  }

  ({int hour, int minute})? _parseHm(String raw) {
    final String s = raw.trim();
    if (s.isEmpty) {
      return null;
    }
    final List<String> parts = s.split(':');
    if (parts.length != 2) {
      return null;
    }
    final int? h = int.tryParse(parts[0]);
    final int? m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return (hour: h, minute: m);
  }

  Future<void> scheduleSessionReminders(DailyPlan plan) async {
    await initialize();

    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final NotificationDetails details = _notificationDetails();

    for (int i = 0; i < plan.sessions.length; i++) {
      final SessionPlan session = plan.sessions[i];

      final ({int hour, int minute})? preferred =
          _parseHm(session.preferredTime);
      if (preferred != null) {
        final tz.TZDateTime? atPreferred = _dateTimeOnPlanDay(
          plan.date,
          preferred.hour,
          preferred.minute,
        );
        if (atPreferred != null && atPreferred.isAfter(now)) {
          final int id = _stableNotificationId(
            plan.date,
            session.sessionId,
            i,
            _slotPrimary,
          );
          await _plugin.zonedSchedule(
            id: id,
            scheduledDate: atPreferred,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: 'Speech practice ready',
            body: 'Your practice session is ready.',
            payload: 'preferred:${session.sessionId}',
          );
        }
      }

      final ({int hour, int minute})? follow =
          _parseHm(session.followUpTime);
      if (follow != null) {
        final tz.TZDateTime? atFollow = _dateTimeOnPlanDay(
          plan.date,
          follow.hour,
          follow.minute,
        );
        if (atFollow != null && atFollow.isAfter(now)) {
          final int id = _stableNotificationId(
            plan.date,
            session.sessionId,
            i,
            _slotFollowUp,
          );
          if (session.sessionId.isNotEmpty) {
            _followUpNotificationIdBySessionId[session.sessionId] = id;
          }
          await _plugin.zonedSchedule(
            id: id,
            scheduledDate: atFollow,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: 'Gentle reminder',
            body: 'Your speech practice is still pending.',
            payload: 'follow:${session.sessionId}',
          );
        }
      }
    }
  }

  Future<void> cancelAllReminders() async {
    await initialize();
    await _plugin.cancelAll();
    _followUpNotificationIdBySessionId.clear();
  }

  Future<void> cancelSessionFollowUp(String sessionId) async {
    await initialize();
    if (sessionId.isEmpty) {
      return;
    }
    final int? id = _followUpNotificationIdBySessionId.remove(sessionId);
    if (id != null) {
      await _plugin.cancel(id: id);
    }
  }

  /// Schedules a one-shot notification for manual testing (sound/vibration).
  Future<void> scheduleDebugReminderInSeconds(int seconds) async {
    await initialize();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final tz.TZDateTime when =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _plugin.cancel(id: debugNotificationId);
    await _plugin.zonedSchedule(
      id: debugNotificationId,
      scheduledDate: when,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: 'Speech practice ready',
      body: 'Your practice session is ready.',
      payload: 'debug',
    );
  }
}
