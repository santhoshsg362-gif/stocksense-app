import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlertService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    // Permission handled via AndroidManifest.xml
    // No runtime request needed for this version
  }

  static Future<void> showStockAlert({
    required String symbol,
    required String alertType,
    required double triggerPrice,
    required double currentPrice,
  }) async {
    if (!_initialized) await init();

    final bool isTarget = alertType == 'TARGET';

    final String title = isTarget
        ? '🎯 Target Hit — $symbol'
        : '⚠️ Stop Loss Hit — $symbol';

    final String body = isTarget
        ? '$symbol reached Rs. ${currentPrice.toStringAsFixed(2)}. Target: Rs. ${triggerPrice.toStringAsFixed(2)}'
        : '$symbol fell to Rs. ${currentPrice.toStringAsFixed(2)}. Stop Loss: Rs. ${triggerPrice.toStringAsFixed(2)}';

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'stocksense_alerts',
      'Stock Price Alerts',
      channelDescription:
          'Stop loss and target price notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      symbol.hashCode.abs() % 100000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );

    print('Notification sent: $title');
  }

  static Future<void> showTest() async {
    if (!_initialized) await init();
    await showStockAlert(
      symbol: 'TEST',
      alertType: 'TARGET',
      triggerPrice: 1000.0,
      currentPrice: 1050.0,
    );
  }
}