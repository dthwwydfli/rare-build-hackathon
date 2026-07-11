import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/urge_log.dart';
import '../../domain/repositories/urge_repository.dart';

class FirestoreUrgeRepository implements UrgeRepository {
  FirestoreUrgeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _urges =>
      _firestore.collection('urge_logs');

  @override
  Stream<List<UrgeLog>> watchUserUrges(String userId) {
    return _urges
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UrgeLog.fromFirestore).toList());
  }

  @override
  Future<UrgeLog> createUrge(UrgeLog urge) async {
    final doc = _urges.doc();
    final created = UrgeLog(
      id: doc.id,
      userId: urge.userId,
      createdAt: DateTime.now(),
      intensity: urge.intensity,
      mood: urge.mood,
      trigger: urge.trigger,
      location: urge.location,
      moneyOnHand: urge.moneyOnHand,
      resisted: urge.resisted,
      notes: urge.notes,
    );
    await doc.set(created.toFirestore());
    return created;
  }
}
