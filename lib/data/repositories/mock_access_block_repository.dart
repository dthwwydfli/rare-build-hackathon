import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/access_block_settings.dart';
import '../../domain/repositories/access_block_repository.dart';

class MockAccessBlockRepository implements AccessBlockRepository {
  final _controller = StreamController<AccessBlockSettings>.broadcast();
  final Map<String, AccessBlockSettings> _cache = {};

  @override
  Stream<AccessBlockSettings> watchSettings(String userId) async* {
    yield await _load(userId);
    yield* _controller.stream.where((s) => s.userId == userId);
  }

  @override
  Future<AccessBlockSettings> saveSettings(AccessBlockSettings settings) async {
    _cache[settings.userId] = settings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gamstop_${settings.userId}', settings.gamstopRegistered);
    await prefs.setBool('bank_${settings.userId}', settings.bankBlockEnabled);
    await prefs.setString('bank_name_${settings.userId}', settings.bankName ?? '');
    await prefs.setBool('app_block_${settings.userId}', settings.appBlockerEnabled);
    await prefs.setBool('web_block_${settings.userId}', settings.websiteBlockerEnabled);
    await prefs.setInt('delay_mins_${settings.userId}', settings.spendingDelayMinutes);
    if (settings.spendingDelayUntil != null) {
      await prefs.setString(
        'delay_until_${settings.userId}',
        settings.spendingDelayUntil!.toIso8601String(),
      );
    } else {
      await prefs.remove('delay_until_${settings.userId}');
    }
    _controller.add(settings);
    return settings;
  }

  Future<AccessBlockSettings> _load(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;
    final prefs = await SharedPreferences.getInstance();
    final untilRaw = prefs.getString('delay_until_$userId');
    final settings = AccessBlockSettings(
      userId: userId,
      gamstopRegistered: prefs.getBool('gamstop_$userId') ?? false,
      bankBlockEnabled: prefs.getBool('bank_$userId') ?? false,
      bankName: prefs.getString('bank_name_$userId')?.isEmpty == true
          ? null
          : prefs.getString('bank_name_$userId'),
      appBlockerEnabled: prefs.getBool('app_block_$userId') ?? false,
      websiteBlockerEnabled: prefs.getBool('web_block_$userId') ?? false,
      spendingDelayMinutes: prefs.getInt('delay_mins_$userId') ?? 0,
      spendingDelayUntil:
          untilRaw != null ? DateTime.tryParse(untilRaw) : null,
    );
    _cache[userId] = settings;
    return settings;
  }
}
