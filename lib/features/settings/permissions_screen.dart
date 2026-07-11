import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/widgets/app_widgets.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static const _usageChannel = MethodChannel('com.accountability/usage_stats');

  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _usageStatsGranted = false;
  bool _locationPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final location = await Geolocator.checkPermission();
    final notification = await Permission.notification.status;
    setState(() {
      _locationGranted = location == LocationPermission.always ||
          location == LocationPermission.whileInUse;
      _locationPermanentlyDenied = location == LocationPermission.deniedForever;
      _notificationGranted = notification.isGranted;
      _usageStatsGranted = !Platform.isAndroid;
    });
  }

  Future<void> _requestLocation() async {
    var permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    await _checkPermissions();
  }

  Future<void> _requestNotifications() async {
    await Permission.notification.request();
    await _checkPermissions();
  }

  Future<void> _requestUsageStats() async {
    if (!Platform.isAndroid) return;
    try {
      await _usageChannel.invokeMethod('requestUsagePermission');
    } catch (_) {}
    if (mounted) {
      showAppSnackBar(
        context,
        'Enable Usage Access for Accountability in system settings',
      );
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
    await _checkPermissions();
  }

  bool get _canContinue =>
      _locationGranted || _notificationGranted || _usageStatsGranted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enable monitoring')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'To keep you accountable, we need a few permissions. Your friends are only alerted when a commitment is at risk.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
            if (!_canContinue) ...[
              const SizedBox(height: 16),
              const ErrorBanner(
                message: 'Enable at least one permission for monitoring to work.',
              ),
            ],
            const SizedBox(height: 24),
            _PermissionTile(
              icon: Icons.location_on_outlined,
              title: 'Location access',
              subtitle: 'Detect when you are near casinos or betting shops',
              granted: _locationGranted,
              permanentlyDenied: _locationPermanentlyDenied,
              onRequest: _requestLocation,
              onOpenSettings: _openSettings,
            ),
            const SizedBox(height: 16),
            _PermissionTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Receive support messages and send alerts to friends',
              granted: _notificationGranted,
              onRequest: _requestNotifications,
              onOpenSettings: _openSettings,
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 16),
              _PermissionTile(
                icon: Icons.phone_android_outlined,
                title: 'App usage access',
                subtitle: 'Detect when gambling apps are opened (Android)',
                granted: _usageStatsGranted,
                onRequest: _requestUsageStats,
                onOpenSettings: _openSettings,
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _canContinue ? () => context.go('/home') : null,
              child: const Text('Continue'),
            ),
            if (!_canContinue)
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onRequest,
    this.permanentlyDenied = false,
    this.onOpenSettings,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final bool permanentlyDenied;
  final VoidCallback onRequest;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            if (granted)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (permanentlyDenied)
              TextButton(
                onPressed: onOpenSettings,
                child: const Text('Settings'),
              )
            else
              TextButton(onPressed: onRequest, child: const Text('Enable')),
          ],
        ),
      ),
    );
  }
}
