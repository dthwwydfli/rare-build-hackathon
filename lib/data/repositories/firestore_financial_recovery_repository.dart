import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/financial_recovery_profile.dart';
import '../../domain/repositories/financial_recovery_repository.dart';

class FirestoreFinancialRecoveryRepository
    implements FinancialRecoveryRepository {
  FirestoreFinancialRecoveryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('financial_recovery').doc(userId);

  @override
  Stream<FinancialRecoveryProfile> watchProfile(String userId) {
    return _doc(userId).snapshots().map((doc) {
      if (!doc.exists) return FinancialRecoveryProfile.empty(userId);
      return FinancialRecoveryProfile.fromFirestore(doc);
    });
  }

  @override
  Future<FinancialRecoveryProfile> saveProfile(
    FinancialRecoveryProfile profile,
  ) async {
    await _doc(profile.userId).set(
      profile.toFirestore(),
      SetOptions(merge: true),
    );
    return profile;
  }
}
