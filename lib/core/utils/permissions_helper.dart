import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatus {
  const PermissionStatus({
    required this.locationGranted,
    required this.notificationGranted,
    required this.usageStatsGranted,
  });

  final bool locationGranted;
  final bool notificationGranted;
  final bool usageStatsGranted;

  bool get allGranted =>
      locationGranted &&
      notificationGranted &&
      (usageStatsGranted || kIsWeb || !defaultTargetPlatform.name.contains('android'));

  bool get anyGranted =>
      locationGranted || notificationGranted || usageStatsGranted;
}

Future<PermissionStatus> checkAllPermissions() async {
  final location = await Geolocator.checkPermission();
  final notification = await Permission.notification.status;
  var usageStats = true;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    usageStats = false;
  }
  return PermissionStatus(
    locationGranted: location == LocationPermission.always ||
        location == LocationPermission.whileInUse,
    notificationGranted: notification.isGranted,
    usageStatsGranted: usageStats,
  );
}

Future<bool> needsPermissionsSetup() async {
  final status = await checkAllPermissions();
  return !status.locationGranted || !status.notificationGranted;
}
