import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/config/app_config.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
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
    if (!useMockAuth && mounted) {
      await ref.read(notificationServiceProvider).refreshToken();
    }
  }

  Future<void> _requestUsageStats() async {
    if (!Platform.isAndroid) return;
    try {
      await _usageChannel.invokeMethod('requestUsagePermission');
    } catch (_) {}
    if (mounted) {
      showAppSnackBar(
        context,
        'enable usage access for lavender in system settings',
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
      appBar: AppBar(title: const LowercaseText('enable monitoring')),
      body: PaperBackground(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LowercaseText(
              'these let lavender quietly look out for you. your friends are only alerted when a goal is at risk.',
              style: TextStyle(color: AppTheme.inkPlumSoft, fontSize: 15),
            ),
            if (!_canContinue) ...[
              const SizedBox(height: 16),
              const ErrorBanner(
                message: 'enable at least one permission for monitoring to work.',
              ),
            ],
            const SizedBox(height: 24),
            _PermissionTile(
              icon: Icons.location_on_outlined,
              title: 'location access',
              subtitle: 'detect when you are near casinos or betting shops',
              granted: _locationGranted,
              permanentlyDenied: _locationPermanentlyDenied,
              onRequest: _requestLocation,
              onOpenSettings: _openSettings,
            ),
            const SizedBox(height: 16),
            _PermissionTile(
              icon: Icons.notifications_outlined,
              title: 'notifications',
              subtitle: 'receive support messages and send alerts to friends',
              granted: _notificationGranted,
              onRequest: _requestNotifications,
              onOpenSettings: _openSettings,
            ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
              const SizedBox(height: 16),
              _PermissionTile(
                icon: Icons.phone_android_outlined,
                title: 'app usage access',
                subtitle: 'detect when gambling apps are opened (android)',
                granted: _usageStatsGranted,
                onRequest: _requestUsageStats,
                onOpenSettings: _openSettings,
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _canContinue
                  ? () async {
                      if (!useMockAuth && _notificationGranted) {
                        await ref
                            .read(notificationServiceProvider)
                            .refreshToken();
                      }
                      if (context.mounted) context.go('/home');
                    }
                  : null,
              child: const LowercaseText('continue'),
            ),
            if (!_canContinue)
              TextButton(
                onPressed: () => context.go('/home'),
                child: const LowercaseText('skip for now'),
              ),
          ],
        ),
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
            Icon(icon, color: AppTheme.lavenderDeep),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LowercaseText(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  LowercaseText(
                    subtitle,
                    style: const TextStyle(color: AppTheme.inkPlumSoft, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (granted)
              const WaxSealCheck(size: 26)
            else if (permanentlyDenied)
              TextButton(
                onPressed: onOpenSettings,
                child: const LowercaseText('settings'),
              )
            else
              TextButton(onPressed: onRequest, child: const LowercaseText('enable')),
          ],
        ),
      ),
    );
  }
}
