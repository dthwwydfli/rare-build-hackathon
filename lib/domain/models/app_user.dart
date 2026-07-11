import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.fcmToken,
    this.discoverable = true,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final String email;
  final String? fcmToken;
  final bool discoverable;
  final DateTime createdAt;

  String get displayNameLower => displayName.toLowerCase();

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      fcmToken: data['fcmToken'] as String?,
      discoverable: data['discoverable'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'displayNameLower': displayNameLower,
      'email': email,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'discoverable': discoverable,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? displayName,
    String? email,
    String? fcmToken,
    bool? discoverable,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      fcmToken: fcmToken ?? this.fcmToken,
      discoverable: discoverable ?? this.discoverable,
      createdAt: createdAt,
    );
  }
}
