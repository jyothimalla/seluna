import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Wraps flutter_local_notifications for period reminders.
/// All methods are no-ops when running on web (kIsWeb == true).
class NotificationService {
  static const _channelId = 'period_tracker_reminders';
  static const _channelName = 'Period Reminders';
  static const _notifId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialised = false;

  /// Initialise the plugin and request permissions. Call once at startup
  /// after [WidgetsFlutterBinding.ensureInitialized].
  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    _initialised = true;

    // Request permissions (iOS runtime prompt; Android 13+ runtime prompt).
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Schedule (or reschedule) a reminder for 2 days before [nextPredictedDate]
  /// at 9 AM local time. Cancels any existing reminder first.
  /// Silently does nothing when [nextPredictedDate] is null or in the past.
  Future<void> scheduleReminder(DateTime? nextPredictedDate) async {
    if (kIsWeb || !_initialised) return;

    // Always cancel the previous reminder so we don't accumulate stale ones.
    await _plugin.cancel(_notifId);

    if (nextPredictedDate == null) return;

    final reminderDay =
        nextPredictedDate.subtract(const Duration(days: 2));
    final fireAt = DateTime(
      reminderDay.year,
      reminderDay.month,
      reminderDay.day,
      9, // 9:00 AM
    );

    if (fireAt.isBefore(DateTime.now())) return;

    final tzFireAt = tz.TZDateTime.from(fireAt, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminds you 2 days before your next period',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      _notifId,
      'Period Reminder',
      'Your period is expected to start in 2 days.',
      tzFireAt,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the scheduled reminder (e.g. after deleting all data).
  Future<void> cancelReminder() async {
    if (kIsWeb || !_initialised) return;
    await _plugin.cancel(_notifId);
  }
}
