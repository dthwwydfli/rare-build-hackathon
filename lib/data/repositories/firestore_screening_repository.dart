import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/screening_prefs.dart';
import '../../domain/models/screening_result.dart';
import '../../domain/repositories/screening_repository.dart';

class FirestoreScreeningRepository implements ScreeningRepository {
  FirestoreScreeningRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _screenings(String userId) =>
      _userDoc(userId).collection('screenings');

  ScreeningStatus _statusFromUserData(Map<String, dynamic>? data) {
    if (data == null) {
      return const ScreeningStatus(screeningCompleted: false);
    }
    return ScreeningStatus(
      screeningCompleted: data['screeningCompleted'] as bool? ?? false,
      lastScreeningAt:
          (data['lastScreeningAt'] as Timestamp?)?.toDate(),
      nextScreeningDueAt:
          (data['nextScreeningDueAt'] as Timestamp?)?.toDate(),
      activeReferralFlags:
          (data['activeReferralFlags'] as List<dynamic>? ?? [])
              .cast<String>(),
    );
  }

  @override
  Future<ScreeningStatus> getStatus(String userId) async {
    final doc = await _userDoc(userId).get();
    final status = _statusFromUserData(doc.data());
    await saveLocalScreeningStatus(userId: userId, status: status);
    return status;
  }

  @override
  Stream<ScreeningStatus> watchStatus(String userId) {
    return _userDoc(userId).snapshots().map((doc) {
      final status = _statusFromUserData(doc.data());
      unawaited(saveLocalScreeningStatus(userId: userId, status: status));
      return status;
    });
  }

  @override
  Future<ScreeningResult> saveResult(ScreeningResult result) async {
    final doc = result.id.isEmpty
        ? _screenings(result.userId).doc()
        : _screenings(result.userId).doc(result.id);
    final saved = ScreeningResult(
      id: doc.id,
      userId: result.userId,
      completedAt: result.completedAt,
      pgsiScore: result.pgsiScore,
      phq2Score: result.phq2Score,
      gad2Score: result.gad2Score,
      auditCScore: result.auditCScore,
      suicideItemScore: result.suicideItemScore,
      pgsiBand: result.pgsiBand,
      referrals: result.referrals,
      crisisTriggered: result.crisisTriggered,
      screeningVersion: result.screeningVersion,
      isRescreen: result.isRescreen,
    );

    final nextDue = saved.completedAt.add(ScreeningStatus.rescreenInterval);
    final status = ScreeningStatus(
      screeningCompleted: true,
      lastScreeningAt: saved.completedAt,
      nextScreeningDueAt: nextDue,
      activeReferralFlags: saved.activeReferralFlags,
    );

    await _firestore.runTransaction((tx) async {
      tx.set(doc, saved.toFirestore());
      tx.set(
        _userDoc(result.userId),
        {
          'screeningCompleted': true,
          'lastScreeningAt': Timestamp.fromDate(saved.completedAt),
          'nextScreeningDueAt': Timestamp.fromDate(nextDue),
          'activeReferralFlags': saved.activeReferralFlags,
        },
        SetOptions(merge: true),
      );
    });

    await saveLocalScreeningStatus(userId: result.userId, status: status);
    return saved;
  }

  @override
  Future<ScreeningResult?> getLatestResult(String userId) async {
    final snapshot = await _screenings(userId)
        .orderBy('completedAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ScreeningResult.fromFirestore(snapshot.docs.first);
  }
}
