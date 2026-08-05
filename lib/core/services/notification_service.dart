import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications only — not Firebase Cloud Messaging.
/// Fires from within the running app process (e.g. when
/// ArrivalWatcherService detects a stop while the app is backgrounded but
/// still alive) — it cannot wake a fully-killed app, same foreground-only
/// tradeoff the whole arrival feature was built around.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showArrivalNotification({
    required String destinationId,
    required String destinationName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'arrival_channel',
      'Journey Arrivals',
      channelDescription: 'Notifies you when you reach a stop on your journey',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.show(
      destinationId.hashCode,
      "You've arrived!",
      '$destinationName is right here — tap to hear its story.',
      details,
    );
  }

  /// Schedules a one-time "come back and finish" nudge for a journey,
  /// [hoursFromNow] later. Local notifications can't run custom logic at
  /// fire time, so there's no dynamic "check if still incomplete" here —
  /// instead cancelJourneyReminder() gets called the moment a journey
  /// actually becomes fully visited, so a finished journey's reminder
  /// simply never fires. journeyId's hashCode is used as a stable
  /// notification ID, so it can be targeted for cancellation later.
  static Future<void> scheduleJourneyReminder({
    required String journeyId,
    required String firstStopName,
    required int remainingStops,
    int hoursFromNow = 30,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'journey_reminder_channel',
      'Journey Reminders',
      channelDescription: 'Nudges you to finish a journey you started',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

    await _plugin.zonedSchedule(
      journeyId.hashCode,
      'Still exploring?',
      '$firstStopName and $remainingStops more stop${remainingStops == 1 ? '' : 's'} are waiting on your journey.',
      tz.TZDateTime.now(tz.local).add(Duration(hours: hoursFromNow)),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelJourneyReminder(String journeyId) async {
    await _plugin.cancel(journeyId.hashCode);
  }
}