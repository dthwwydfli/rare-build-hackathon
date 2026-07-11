import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/commitment.dart';
import '../../domain/repositories/commitment_repository.dart';

class FirestoreCommitmentRepository implements CommitmentRepository {
  FirestoreCommitmentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _commitments =>
      _firestore.collection('commitments');

  @override
  Stream<List<Commitment>> watchUserCommitments(String userId) {
    return _commitments
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(Commitment.fromFirestore).toList());
  }

  @override
  Future<Commitment> createCommitment(Commitment commitment) async {
    final doc = _commitments.doc();
    final created = Commitment(
      id: doc.id,
      userId: commitment.userId,
      title: commitment.title,
      type: commitment.type,
      rules: commitment.rules,
      active: commitment.active,
      createdAt: DateTime.now(),
    );
    await doc.set(created.toFirestore());
    return created;
  }

  @override
  Future<void> updateCommitment(Commitment commitment) {
    return _commitments.doc(commitment.id).update(commitment.toFirestore());
  }

  @override
  Future<void> deleteCommitment(String commitmentId) {
    return _commitments.doc(commitmentId).delete();
  }
}
