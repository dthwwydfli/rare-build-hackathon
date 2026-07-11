import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Handles navigation from FCM notification payloads.
class NotificationRouter {
  static void handlePayload(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'breach_alert':
        final eventId = data['eventId'] as String?;
        final groupId = data['groupId'] as String?;
        if (eventId != null && groupId != null) {
          context.push('/breach/$eventId?groupId=$groupId');
        } else {
          context.push('/support');
        }
      case 'support_received':
        context.push('/home');
      default:
        break;
    }
  }
}
