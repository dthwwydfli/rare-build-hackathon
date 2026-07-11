import 'package:cloud_firestore/cloud_firestore.dart';

/// User-configured barriers that cut off gambling access in the moment.
class AccessBlockSettings {
  const AccessBlockSettings({
    required this.userId,
    this.gamstopRegistered = false,
    this.bankBlockEnabled = false,
    this.bankName,
    this.appBlockerEnabled = false,
    this.websiteBlockerEnabled = false,
    this.spendingDelayMinutes = 0,
    this.spendingDelayUntil,
    this.updatedAt,
  });

  final String userId;
  final bool gamstopRegistered;
  final bool bankBlockEnabled;
  final String? bankName;
  final bool appBlockerEnabled;
  final bool websiteBlockerEnabled;
  final int spendingDelayMinutes;
  final DateTime? spendingDelayUntil;
  final DateTime? updatedAt;

  bool get spendingDelayActive =>
      spendingDelayUntil != null && spendingDelayUntil!.isAfter(DateTime.now());

  int get activeBlockCount => [
        gamstopRegistered,
        bankBlockEnabled,
        appBlockerEnabled,
        websiteBlockerEnabled,
        spendingDelayMinutes > 0,
      ].where((v) => v).length;

  factory AccessBlockSettings.empty(String userId) =>
      AccessBlockSettings(userId: userId);

  factory AccessBlockSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AccessBlockSettings(
      userId: doc.id,
      gamstopRegistered: data['gamstopRegistered'] as bool? ?? false,
      bankBlockEnabled: data['bankBlockEnabled'] as bool? ?? false,
      bankName: data['bankName'] as String?,
      appBlockerEnabled: data['appBlockerEnabled'] as bool? ?? false,
      websiteBlockerEnabled: data['websiteBlockerEnabled'] as bool? ?? false,
      spendingDelayMinutes: data['spendingDelayMinutes'] as int? ?? 0,
      spendingDelayUntil:
          (data['spendingDelayUntil'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gamstopRegistered': gamstopRegistered,
      'bankBlockEnabled': bankBlockEnabled,
      if (bankName != null) 'bankName': bankName,
      'appBlockerEnabled': appBlockerEnabled,
      'websiteBlockerEnabled': websiteBlockerEnabled,
      'spendingDelayMinutes': spendingDelayMinutes,
      if (spendingDelayUntil != null)
        'spendingDelayUntil': Timestamp.fromDate(spendingDelayUntil!),
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
    };
  }

  AccessBlockSettings copyWith({
    bool? gamstopRegistered,
    bool? bankBlockEnabled,
    String? bankName,
    bool? appBlockerEnabled,
    bool? websiteBlockerEnabled,
    int? spendingDelayMinutes,
    DateTime? spendingDelayUntil,
    bool clearSpendingDelayUntil = false,
  }) {
    return AccessBlockSettings(
      userId: userId,
      gamstopRegistered: gamstopRegistered ?? this.gamstopRegistered,
      bankBlockEnabled: bankBlockEnabled ?? this.bankBlockEnabled,
      bankName: bankName ?? this.bankName,
      appBlockerEnabled: appBlockerEnabled ?? this.appBlockerEnabled,
      websiteBlockerEnabled:
          websiteBlockerEnabled ?? this.websiteBlockerEnabled,
      spendingDelayMinutes: spendingDelayMinutes ?? this.spendingDelayMinutes,
      spendingDelayUntil: clearSpendingDelayUntil
          ? null
          : spendingDelayUntil ?? this.spendingDelayUntil,
      updatedAt: DateTime.now(),
    );
  }
}

class BankBlockOption {
  const BankBlockOption({
    required this.name,
    required this.url,
    required this.instructions,
  });

  final String name;
  final String url;
  final String instructions;
}

const ukBankBlockOptions = [
  BankBlockOption(
    name: 'Barclays',
    url: 'https://www.barclays.co.uk/ways-to-bank/mobile-banking-app/features/control-your-debit-card/',
    instructions: 'Turn on gambling merchant blocks in the Barclays app.',
  ),
  BankBlockOption(
    name: 'HSBC',
    url: 'https://www.hsbc.co.uk/help/gambling/',
    instructions: 'Request a gambling block via HSBC online banking or app.',
  ),
  BankBlockOption(
    name: 'Lloyds',
    url: 'https://www.lloydsbank.com/help-guidance/support-and-wellbeing/gambling.html',
    instructions: 'Enable gambling restrictions in Card Settings.',
  ),
  BankBlockOption(
    name: 'NatWest',
    url: 'https://www.natwest.com/support-centre/gambling.html',
    instructions: 'Block gambling transactions in the mobile app.',
  ),
  BankBlockOption(
    name: 'Monzo',
    url: 'https://monzo.com/gambling-block',
    instructions: 'Toggle gambling block on in Monzo app → Settings.',
  ),
  BankBlockOption(
    name: 'Starling',
    url: 'https://www.starlingbank.com/gambling/',
    instructions: 'Enable gambling block in Starling app controls.',
  ),
];
