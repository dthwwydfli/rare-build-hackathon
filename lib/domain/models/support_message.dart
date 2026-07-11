import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.breachEventId,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.type,
    required this.createdAt,
    this.fromUserName,
  });

  final String id;
  final String breachEventId;
  final String fromUserId;
  final String toUserId;
  final String message;
  final SupportMessageType type;
  final DateTime createdAt;
  final String? fromUserName;

  factory SupportMessage.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SupportMessage(
      id: doc.id,
      breachEventId: data['breachEventId'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: SupportMessageTypeX.fromString(
        data['type'] as String? ?? 'encouragement',
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fromUserName: data['fromUserName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'breachEventId': breachEventId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'type': type.name == 'checkIn' ? 'check_in' : type.name == 'callOffer' ? 'call_offer' : type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (fromUserName != null) 'fromUserName': fromUserName,
    };
  }
}
