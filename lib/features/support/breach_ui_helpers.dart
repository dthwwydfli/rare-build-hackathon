import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/enums.dart';

IconData breachSignalIcon(BreachSignalType type) {
  switch (type) {
    case BreachSignalType.location:
      return Icons.location_on;
    case BreachSignalType.app:
      return Icons.phone_android;
    case BreachSignalType.url:
      return Icons.language;
    case BreachSignalType.payment:
      return Icons.payments;
    case BreachSignalType.manual:
      return Icons.waving_hand;
  }
}

String formatRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return DateFormat.MMMd().format(time);
}
