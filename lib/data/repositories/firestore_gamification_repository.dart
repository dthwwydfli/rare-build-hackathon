import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/gamification_repository.dart';

class FirestoreGamificationRepository implements GamificationRepository {
  FirestoreGamificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser> watchUserStats(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return AppUser(
          id: userId,
          displayName: 'player',
          email: '',
          createdAt: DateTime.now(),
        );
      }
      return AppUser.fromFirestore(doc);
    });
  }

  @override
  Stream<List<LeaderboardEntry>> watchGroupLeaderboard(String groupId) {
    return _firestore.collection('groups').doc(groupId).snapshots().asyncMap(
      (groupDoc) async {
        if (!groupDoc.exists) return <LeaderboardEntry>[];
        final memberIds =
            List<String>.from(groupDoc.data()?['memberIds'] ?? []);
        if (memberIds.isEmpty) return <LeaderboardEntry>[];

        final users = <AppUser>[];
        for (final id in memberIds) {
          final doc = await _users.doc(id).get();
          if (doc.exists) users.add(AppUser.fromFirestore(doc));
        }
        return _ranked(users);
      },
    );
  }

  @override
  Stream<List<LeaderboardEntry>> watchGlobalLeaderboard({int limit = 50}) {
    return _users
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final users =
          snapshot.docs.map((d) => AppUser.fromFirestore(d)).toList();
      return _ranked(users);
    });
  }

  List<LeaderboardEntry> _ranked(List<AppUser> users) {
    final sorted = users.toList()
      ..sort((a, b) {
        final pointsCmp = b.points.compareTo(a.points);
        if (pointsCmp != 0) return pointsCmp;
        return b.currentStreak.compareTo(a.currentStreak);
      });
    return sorted.asMap().entries.map((e) {
      final u = e.value;
      return LeaderboardEntry(
        userId: u.id,
        displayName: u.displayName,
        points: u.points,
        currentStreak: u.currentStreak,
        rank: e.key + 1,
      );
    }).toList();
  }

  @override
  Future<void> applySupportBonus(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return;
    final user = AppUser.fromFirestore(doc);
    await _users.doc(userId).update({'points': user.points + 5});
  }

  @override
  Future<void> applyBreachPenalty(String userId, {int severity = 1}) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return;
    final user = AppUser.fromFirestore(doc);
    final penalty = severity >= 2 ? 60 : 30;
    await _users.doc(userId).update({
      'points': (user.points - penalty).clamp(0, 9999),
      'currentStreak': 0,
      'lastBreachDate': FieldValue.serverTimestamp(),
    });
  }
}
