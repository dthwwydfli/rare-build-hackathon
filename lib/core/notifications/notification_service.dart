import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../config/app_config.dart';
import '../providers/repository_providers.dart';
import 'notification_router.dart';

class NotificationService {
  NotificationService(this._authRepository, this._navigatorKey, this._messengerKey);

  final AuthRepository _authRepository;
  final GlobalKey<NavigatorState> _navigatorKey;
  final GlobalKey<ScaffoldMessengerState> _messengerKey;
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _authRepository.updateFcmToken(token);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateFromPayload(initial.data);
      });
    }
  }

  /// Requests FCM permission and saves the device token to Firestore.
  /// Call after the user grants notification permission on the permissions screen.
  Future<void> refreshToken() async {
    if (useMockAuth) return;

    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      await _authRepository.updateFcmToken(token);
    }
  }

  Future<void> onUserSignedIn() => refreshToken();

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? 'New notification';
    final body = notification?.body ?? '';
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateFromPayload(message.data),
        ),
      ),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _navigateFromPayload(message.data);
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Navigation context unavailable for notification: $data');
      return;
    }
    NotificationRouter.handlePayload(context, data);
  }
}

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    ref.watch(authRepositoryProvider),
    navigatorKey,
    scaffoldMessengerKey,
  );
});

/// Re-registers FCM token whenever user signs in.
final notificationAuthListenerProvider = Provider<void>((ref) {
  if (useMockAuth) return;
  ref.listen(currentUserProvider, (previous, next) {
    final user = next.valueOrNull;
    if (user != null && previous?.valueOrNull == null) {
      ref.read(notificationServiceProvider).onUserSignedIn();
    }
  });
});
