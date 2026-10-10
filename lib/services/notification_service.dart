import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_strings.dart';

/// Wraps flutter_local_notifications. Alarms are scheduled with Android's
/// AlarmManager, so they fire even when the app is closed or the phone is
/// locked, and are restored after a reboot (ScheduledNotificationBootReceiver).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const motorAlarmId = 1;
  static const meterReminderId = 2;

  /// Tip notifications use ids 100 … 100 + tipDaysAhead − 1.
  static const tipBaseId = 100;
  static const tipDaysAhead = 14;

  static const _motorChannelId = 'motor_alarm_v1';
  static const _reminderChannelId = 'reminders_v1';
  static const _tipChannelId = 'tips_v1';

  /// Android FLAG_INSISTENT: the alarm sound repeats until the user
  /// opens or dismisses the notification.
  static const _flagInsistent = 4;

  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_water'),
      ),
    );
    _initialized = true;
  }

  /// Asks for notification permission (Android 13+) and, if needed, exact
  /// alarm permission (Android 12). Returns true if notifications are allowed.
  /// Denial is fine: the app keeps working, the Motor Guard screen shows a
  /// warning instead.
  Future<bool> requestPermissions() async {
    final android = _android;
    if (android == null) return false;
    final granted = await android.requestNotificationsPermission() ?? false;
    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (!canExact) await android.requestExactAlarmsPermission();
    return granted;
  }

  Future<bool> notificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  Future<AndroidScheduleMode> _scheduleMode() async {
    final canExact = await _android?.canScheduleExactNotifications() ?? false;
    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _motorDetails(AppStrings s) => NotificationDetails(
        android: AndroidNotificationDetails(
          _motorChannelId,
          s.get('channelMotorName'),
          channelDescription: s.get('channelMotorDesc'),
          icon: 'ic_stat_water',
          importance: Importance.max,
          priority: Priority.max,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // The phone's own alarm ringtone.
          sound: const UriAndroidNotificationSound(
              'content://settings/system/alarm_alert'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          additionalFlags: Int32List.fromList([_flagInsistent]),
          ticker: s.get('alarmBody'),
        ),
      );

  NotificationDetails _reminderDetails(AppStrings s) => NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          s.get('channelReminderName'),
          channelDescription: s.get('channelReminderDesc'),
          icon: 'ic_stat_water',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
      );

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    await init();
    await _plugin.cancel(id: id);
    // Scheduling in the past is not allowed, so "now" means show at once.
    if (!when.isAfter(DateTime.now().add(const Duration(seconds: 1)))) {
      await _plugin.show(
          id: id, title: title, body: body, notificationDetails: details);
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      // An absolute instant: UTC avoids needing the device's zone name.
      scheduledDate: tz.TZDateTime.from(when.toUtc(), tz.UTC),
      notificationDetails: details,
      androidScheduleMode: await _scheduleMode(),
      title: title,
      body: body,
    );
  }

  /// "Overhead tank: almost full! Switch off the motor now."
  Future<void> scheduleMotorAlarm(
          DateTime when, AppStrings s, String tankName) =>
      _schedule(
        id: motorAlarmId,
        when: when,
        title: s.get('alarmTitle', {'tank': tankName}),
        body: s.get('alarmBody'),
        details: _motorDetails(s),
      );

  Future<void> cancelMotorAlarm() async {
    await init();
    await _plugin.cancel(id: motorAlarmId);
  }

  /// Morning reminder for the Night Meter Test.
  Future<void> scheduleMeterReminder(DateTime when, AppStrings s) => _schedule(
        id: meterReminderId,
        when: when,
        title: s.get('meterReminderTitle'),
        body: s.get('meterReminderBody'),
        details: _reminderDetails(s),
      );

  Future<void> cancelMeterReminder() async {
    await init();
    await _plugin.cancel(id: meterReminderId);
  }

  NotificationDetails _tipDetails(AppStrings s) => NotificationDetails(
        android: AndroidNotificationDetails(
          _tipChannelId,
          s.get('channelTipName'),
          channelDescription: s.get('channelTipDesc'),
          icon: 'ic_stat_water',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );

  /// Schedules one morning tip per day (each day has its own tip text, so
  /// they are scheduled individually and refreshed every time the app opens).
  Future<void> scheduleTips(
      List<({DateTime when, String body})> tips, AppStrings s) async {
    await cancelTips();
    for (var i = 0; i < tips.length && i < tipDaysAhead; i++) {
      final tip = tips[i];
      if (!tip.when.isAfter(DateTime.now())) continue;
      await _schedule(
        id: tipBaseId + i,
        when: tip.when,
        title: s.get('tipOfTheDay'),
        body: tip.body,
        details: _tipDetails(s),
      );
    }
  }

  Future<void> cancelTips() async {
    await init();
    for (var i = 0; i < tipDaysAhead; i++) {
      await _plugin.cancel(id: tipBaseId + i);
    }
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}
