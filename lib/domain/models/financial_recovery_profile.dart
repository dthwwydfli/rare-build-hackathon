import 'package:cloud_firestore/cloud_firestore.dart';

/// User-defined financial recovery goals for rebuilding after gambling harm.
class FinancialRecoveryProfile {
  const FinancialRecoveryProfile({
    required this.userId,
    this.estimatedDebt,
    this.debtPaidOff,
    this.savingsGoal,
    this.savingsCurrent,
    this.monthlySpendingLimit,
    this.paydayDayOfMonth,
    this.updatedAt,
  });

  final String userId;
  final double? estimatedDebt;
  final double? debtPaidOff;
  final double? savingsGoal;
  final double? savingsCurrent;
  final double? monthlySpendingLimit;
  final int? paydayDayOfMonth;
  final DateTime? updatedAt;

  double? get debtRemaining {
    if (estimatedDebt == null) return null;
    final paid = debtPaidOff ?? 0;
    return (estimatedDebt! - paid).clamp(0, double.infinity);
  }

  double? get debtProgress {
    if (estimatedDebt == null || estimatedDebt! <= 0) return null;
    final paid = debtPaidOff ?? 0;
    return (paid / estimatedDebt!).clamp(0.0, 1.0);
  }

  double? get savingsProgress {
    if (savingsGoal == null || savingsGoal! <= 0) return null;
    final saved = savingsCurrent ?? 0;
    return (saved / savingsGoal!).clamp(0.0, 1.0);
  }

  bool get hasAnyGoal =>
      estimatedDebt != null ||
      savingsGoal != null ||
      monthlySpendingLimit != null ||
      paydayDayOfMonth != null;

  factory FinancialRecoveryProfile.empty(String userId) =>
      FinancialRecoveryProfile(userId: userId);

  factory FinancialRecoveryProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return FinancialRecoveryProfile(
      userId: doc.id,
      estimatedDebt: (data['estimatedDebt'] as num?)?.toDouble(),
      debtPaidOff: (data['debtPaidOff'] as num?)?.toDouble(),
      savingsGoal: (data['savingsGoal'] as num?)?.toDouble(),
      savingsCurrent: (data['savingsCurrent'] as num?)?.toDouble(),
      monthlySpendingLimit:
          (data['monthlySpendingLimit'] as num?)?.toDouble(),
      paydayDayOfMonth: data['paydayDayOfMonth'] as int?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (estimatedDebt != null) 'estimatedDebt': estimatedDebt,
      if (debtPaidOff != null) 'debtPaidOff': debtPaidOff,
      if (savingsGoal != null) 'savingsGoal': savingsGoal,
      if (savingsCurrent != null) 'savingsCurrent': savingsCurrent,
      if (monthlySpendingLimit != null)
        'monthlySpendingLimit': monthlySpendingLimit,
      if (paydayDayOfMonth != null) 'paydayDayOfMonth': paydayDayOfMonth,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  FinancialRecoveryProfile copyWith({
    double? estimatedDebt,
    double? debtPaidOff,
    double? savingsGoal,
    double? savingsCurrent,
    double? monthlySpendingLimit,
    int? paydayDayOfMonth,
    bool clearEstimatedDebt = false,
    bool clearDebtPaidOff = false,
    bool clearSavingsGoal = false,
    bool clearSavingsCurrent = false,
    bool clearMonthlySpendingLimit = false,
    bool clearPaydayDayOfMonth = false,
  }) {
    return FinancialRecoveryProfile(
      userId: userId,
      estimatedDebt:
          clearEstimatedDebt ? null : estimatedDebt ?? this.estimatedDebt,
      debtPaidOff: clearDebtPaidOff ? null : debtPaidOff ?? this.debtPaidOff,
      savingsGoal:
          clearSavingsGoal ? null : savingsGoal ?? this.savingsGoal,
      savingsCurrent:
          clearSavingsCurrent ? null : savingsCurrent ?? this.savingsCurrent,
      monthlySpendingLimit: clearMonthlySpendingLimit
          ? null
          : monthlySpendingLimit ?? this.monthlySpendingLimit,
      paydayDayOfMonth: clearPaydayDayOfMonth
          ? null
          : paydayDayOfMonth ?? this.paydayDayOfMonth,
      updatedAt: DateTime.now(),
    );
  }
}
