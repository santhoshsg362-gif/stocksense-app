import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final
    FlutterLocalNotificationsPlugin
    _notifications =
    FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const settings =
      InitializationSettings(
        android: android);
    await _notifications.initialize(
      settings);
  }

  static Future<void> showAlert({
    required String title,
    required String body,
  }) async {
    const androidDetails =
      AndroidNotificationDetails(
      'stocksense_alerts',
      'Stock Alerts',
      channelDescription:
        'Price alerts for your stocks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails);
    await _notifications.show(
      DateTime.now()
        .millisecondsSinceEpoch
        .remainder(100000),
      title,
      body,
      details,
    );
  }
}