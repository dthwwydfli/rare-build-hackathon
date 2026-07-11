import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/demo/demo_breach_alert.dart';
import 'notification_service.dart';

const demoPaddyPowerPayload = 'demo_paddy_power';
const _breachAlertsChannelId = 'breach_alerts';
const _demoPaddyPowerNotificationId = 9001;

class LocalNotificationService {
  LocalNotificationService(this._navigatorKey);

  final GlobalKey<NavigatorState> _navigatorKey;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _breachAlertsChannelId,
              'breach alerts',
              description: 'alerts when you enter a betting venue or break a commitment',
              importance: Importance.high,
            ),
          );
    }

    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _handlePayload(launchDetails!.notificationResponse?.payload);
    }
  }

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      if (granted) return true;
    }

    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> showDemoPaddyPowerNotification() async {
    if (kIsWeb) return false;
    if (!_initialized) await initialize();

    final granted = await ensurePermission();
    if (!granted) return false;

    await _plugin.show(
      _demoPaddyPowerNotificationId,
      'paddy power',
      'your support circle has been notified — you committed to avoid betting venues.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _breachAlertsChannelId,
          'breach alerts',
          channelDescription:
              'alerts when you enter a betting venue or break a commitment',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: demoPaddyPowerPayload,
    );
    return true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  void _handlePayload(String? payload) {
    if (payload != demoPaddyPowerPayload) return;

    final context = _navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeContext = _navigatorKey.currentContext;
      if (activeContext != null) {
        showDemoPaddyPowerAlertDialog(activeContext);
      }
    });
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService(navigatorKey);
});
