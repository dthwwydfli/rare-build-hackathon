import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/access_block_settings.dart';
import '../../domain/repositories/access_block_repository.dart';

class FirestoreAccessBlockRepository implements AccessBlockRepository {
  FirestoreAccessBlockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('block_settings').doc(userId);

  @override
  Stream<AccessBlockSettings> watchSettings(String userId) {
    return _doc(userId).snapshots().map((doc) {
      if (!doc.exists) return AccessBlockSettings.empty(userId);
      return AccessBlockSettings.fromFirestore(doc);
    });
  }

  @override
  Future<AccessBlockSettings> saveSettings(AccessBlockSettings settings) async {
    await _doc(settings.userId).set(settings.toFirestore(), SetOptions(merge: true));
    return settings;
  }
}
