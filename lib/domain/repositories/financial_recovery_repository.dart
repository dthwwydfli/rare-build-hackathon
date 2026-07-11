import '../models/financial_recovery_profile.dart';

abstract class FinancialRecoveryRepository {
  Stream<FinancialRecoveryProfile> watchProfile(String userId);
  Future<FinancialRecoveryProfile> saveProfile(FinancialRecoveryProfile profile);
}
