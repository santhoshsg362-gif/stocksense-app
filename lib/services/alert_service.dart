import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final
    FlutterLocalNotificationsPlugin
    _plugin =
    FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher');

    const settings =
      InitializationSettings(
        android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> showStockAlert({
    required String symbol,
    required String alertType,
    required double triggerPrice,
    required double currentPrice,
  }) async {
    if (!_initialized) await init();

    final isTarget =
      alertType == 'TARGET';

    final title = isTarget
      ? '🎯 Target Hit — $symbol'
      : '⚠️ Stop Loss Hit — $symbol';

    final body = isTarget
      ? '$symbol reached Rs. '
        '${currentPrice.toStringAsFixed(2)}'
        '. Target: Rs. '
        '${triggerPrice.toStringAsFixed(2)}'
      : '$symbol fell to Rs. '
        '${currentPrice.toStringAsFixed(2)}'
        '. Stop Loss: Rs. '
        '${triggerPrice.toStringAsFixed(2)}';

    const androidDetails =
      AndroidNotificationDetails(
        'stocksense_alerts',
        'Stock Price Alerts',
        channelDescription:
          'Alerts for stop loss '
          'and target price',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
      );

    const details = NotificationDetails(
      android: androidDetails);

    await _plugin.show(
      symbol.hashCode.abs() % 100000,
      title,
      body,
      details,
    );
  }
}