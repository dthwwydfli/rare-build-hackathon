import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.fcmToken,
    this.discoverable = true,
    this.avatarColor,
    this.bio,
    required this.createdAt,
    this.points = 1000,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastCleanDate,
    this.lastBreachDate,
  });

  final String id;
  final String displayName;
  final String email;
  final String? fcmToken;
  final bool discoverable;
  final int? avatarColor;
  final String? bio;
  final DateTime createdAt;
  final int points;
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastCleanDate;
  final DateTime? lastBreachDate;

  String get displayNameLower => displayName.toLowerCase();

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fcmToken: data['fcmToken'] as String?,
      discoverable: data['discoverable'] as bool? ?? true,
      avatarColor: data['avatarColor'] as int?,
      bio: data['bio'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      points: (data['points'] ?? data['eloRating']) as int? ?? 1000,
      currentStreak: data['currentStreak'] as int? ?? 0,
      bestStreak: data['bestStreak'] as int? ?? 0,
      lastCleanDate: (data['lastCleanDate'] as Timestamp?)?.toDate(),
      lastBreachDate: (data['lastBreachDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'email': email,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'discoverable': discoverable,
      if (avatarColor != null) 'avatarColor': avatarColor,
      if (bio != null) 'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'points': points,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      if (lastCleanDate != null)
        'lastCleanDate': Timestamp.fromDate(lastCleanDate!),
      if (lastBreachDate != null)
        'lastBreachDate': Timestamp.fromDate(lastBreachDate!),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? fcmToken,
    bool? discoverable,
    int? avatarColor,
    String? bio,
    int? points,
    int? currentStreak,
    int? bestStreak,
    DateTime? lastCleanDate,
    DateTime? lastBreachDate,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      discoverable: discoverable ?? this.discoverable,
      avatarColor: avatarColor ?? this.avatarColor,
      bio: bio ?? this.bio,
      createdAt: createdAt,
      points: points ?? this.points,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCleanDate: lastCleanDate ?? this.lastCleanDate,
      lastBreachDate: lastBreachDate ?? this.lastBreachDate,
    );
  }
}
