import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/breach_event.dart';
import '../../domain/models/support_message.dart';
import '../../domain/repositories/breach_repository.dart';

class FirestoreBreachRepository implements BreachRepository {
  FirestoreBreachRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _breaches =>
      _firestore.collection('breach_events');

  CollectionReference<Map<String, dynamic>> get _support =>
      _firestore.collection('support_messages');

  @override
  Stream<List<BreachEvent>> watchGroupBreaches(String groupId) {
    return _breaches
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(BreachEvent.fromFirestore).toList());
  }

  @override
  Stream<List<BreachEvent>> watchUserBreaches(String userId) {
    return _breaches
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(BreachEvent.fromFirestore).toList());
  }

  @override
  Future<BreachEvent> createBreach(BreachEvent event) async {
    final doc = _breaches.doc();
    final created = BreachEvent(
      id: doc.id,
      userId: event.userId,
      commitmentId: event.commitmentId,
      groupId: event.groupId,
      signalType: event.signalType,
      metadata: event.metadata,
      severity: event.severity,
      createdAt: DateTime.now(),
      flagged: event.flagged,
      acknowledged: event.acknowledged,
      userName: event.userName,
    );
    await doc.set(created.toFirestore());
    return created;
  }

  @override
  Future<void> acknowledgeBreach(String eventId) {
    return _breaches.doc(eventId).update({
      'acknowledged': true,
      'flagged': false,
    });
  }

  @override
  Future<void> resolveBreach(String eventId) {
    return _breaches.doc(eventId).update({'flagged': false});
  }

  @override
  Future<void> sendSupport(SupportMessage message) async {
    await _support.add(message.toFirestore());
  }

  @override
  Stream<List<SupportMessage>> watchSupportForUser(String userId) {
    return _support
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(SupportMessage.fromFirestore).toList());
  }

  @override
  Stream<List<SupportMessage>> watchSupportForBreach(String breachEventId) {
    return _support
        .where('breachEventId', isEqualTo: breachEventId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(SupportMessage.fromFirestore).toList());
  }
}
