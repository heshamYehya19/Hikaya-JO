import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local (on-device) notifications only — not Firebase Cloud Messaging.
/// Fires from within the running app process (e.g. when
/// ArrivalWatcherService detects a stop while the app is backgrounded but
/// still alive) — it cannot wake a fully-killed app, same foreground-only
/// tradeoff the whole arrival feature was built around. Tapping the
/// notification just brings the app back to the foreground via normal OS
/// behavior; no custom deep-link handling needed, since MainShell already
/// keeps the arrival overlay's state waiting regardless of foreground
/// status — see main_shell.dart.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);

    // Android 13+ requires this explicit runtime request.
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
}