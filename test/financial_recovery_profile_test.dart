import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:accountability_app/data/repositories/mock_financial_recovery_repository.dart';
import 'package:accountability_app/domain/models/financial_recovery_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FinancialRecoveryProfile', () {
    test('debtProgress returns ratio of paid to estimated', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        estimatedDebt: 1000,
        debtPaidOff: 250,
      );
      expect(profile.debtProgress, 0.25);
      expect(profile.debtRemaining, 750);
    });

    test('debtProgress clamps at 1 when overpaid', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        estimatedDebt: 500,
        debtPaidOff: 600,
      );
      expect(profile.debtProgress, 1.0);
      expect(profile.debtRemaining, 0);
    });

    test('debtProgress is null without estimated debt', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        debtPaidOff: 100,
      );
      expect(profile.debtProgress, isNull);
      expect(profile.debtRemaining, isNull);
    });

    test('savingsProgress returns ratio of current to goal', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        savingsGoal: 500,
        savingsCurrent: 120,
      );
      expect(profile.savingsProgress, closeTo(0.24, 0.001));
    });

    test('savingsProgress is null without savings goal', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        savingsCurrent: 50,
      );
      expect(profile.savingsProgress, isNull);
    });

    test('hasAnyGoal is false for empty profile', () {
      expect(FinancialRecoveryProfile.empty('u1').hasAnyGoal, isFalse);
    });

    test('hasAnyGoal is true when any field is set', () {
      const profile = FinancialRecoveryProfile(
        userId: 'u1',
        paydayDayOfMonth: 25,
      );
      expect(profile.hasAnyGoal, isTrue);
    });
  });

  group('MockFinancialRecoveryRepository', () {
    test('save and load round-trip', () async {
      final repo = MockFinancialRecoveryRepository();
      const profile = FinancialRecoveryProfile(
        userId: 'user-1',
        estimatedDebt: 2000,
        debtPaidOff: 400,
        savingsGoal: 500,
        savingsCurrent: 100,
        monthlySpendingLimit: 300,
        paydayDayOfMonth: 28,
      );

      await repo.saveProfile(profile);

      final loaded = await repo.watchProfile('user-1').first;
      expect(loaded.estimatedDebt, 2000);
      expect(loaded.debtPaidOff, 400);
      expect(loaded.savingsGoal, 500);
      expect(loaded.savingsCurrent, 100);
      expect(loaded.monthlySpendingLimit, 300);
      expect(loaded.paydayDayOfMonth, 28);
    });

    test('stream emits after save', () async {
      final repo = MockFinancialRecoveryRepository();
      final values = <FinancialRecoveryProfile>[];
      final sub = repo.watchProfile('user-2').listen(values.add);

      await Future<void>.delayed(Duration.zero);
      expect(values, hasLength(1));
      expect(values.first.hasAnyGoal, isFalse);

      await repo.saveProfile(
        const FinancialRecoveryProfile(
          userId: 'user-2',
          savingsGoal: 1000,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(values.last.savingsGoal, 1000);
      await sub.cancel();
    });
  });
}
