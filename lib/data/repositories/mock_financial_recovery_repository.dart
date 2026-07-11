import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/financial_recovery_profile.dart';
import '../../domain/repositories/financial_recovery_repository.dart';

class MockFinancialRecoveryRepository implements FinancialRecoveryRepository {
  final _controller = StreamController<FinancialRecoveryProfile>.broadcast();
  final Map<String, FinancialRecoveryProfile> _cache = {};

  @override
  Stream<FinancialRecoveryProfile> watchProfile(String userId) async* {
    yield await _load(userId);
    yield* _controller.stream.where((p) => p.userId == userId);
  }

  @override
  Future<FinancialRecoveryProfile> saveProfile(
    FinancialRecoveryProfile profile,
  ) async {
    _cache[profile.userId] = profile;
    final prefs = await SharedPreferences.getInstance();
    final id = profile.userId;
    await _setDouble(prefs, 'fr_debt_$id', profile.estimatedDebt);
    await _setDouble(prefs, 'fr_paid_$id', profile.debtPaidOff);
    await _setDouble(prefs, 'fr_savings_goal_$id', profile.savingsGoal);
    await _setDouble(prefs, 'fr_savings_current_$id', profile.savingsCurrent);
    await _setDouble(
      prefs,
      'fr_spending_limit_$id',
      profile.monthlySpendingLimit,
    );
    if (profile.paydayDayOfMonth != null) {
      await prefs.setInt('fr_payday_$id', profile.paydayDayOfMonth!);
    } else {
      await prefs.remove('fr_payday_$id');
    }
    _controller.add(profile);
    return profile;
  }

  Future<void> _setDouble(
    SharedPreferences prefs,
    String key,
    double? value,
  ) async {
    if (value != null) {
      await prefs.setDouble(key, value);
    } else {
      await prefs.remove(key);
    }
  }

  Future<FinancialRecoveryProfile> _load(String userId) async {
    if (_cache.containsKey(userId)) return _cache[userId]!;
    final prefs = await SharedPreferences.getInstance();
    final profile = FinancialRecoveryProfile(
      userId: userId,
      estimatedDebt: prefs.getDouble('fr_debt_$userId'),
      debtPaidOff: prefs.getDouble('fr_paid_$userId'),
      savingsGoal: prefs.getDouble('fr_savings_goal_$userId'),
      savingsCurrent: prefs.getDouble('fr_savings_current_$userId'),
      monthlySpendingLimit: prefs.getDouble('fr_spending_limit_$userId'),
      paydayDayOfMonth: prefs.getInt('fr_payday_$userId'),
    );
    _cache[userId] = profile;
    return profile;
  }
}
