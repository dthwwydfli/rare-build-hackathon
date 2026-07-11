enum BreachSignalType {
  location,
  app,
  url,
  payment,
  manual,
}

extension BreachSignalTypeX on BreachSignalType {
  String get label {
    switch (this) {
      case BreachSignalType.location:
        return 'Location';
      case BreachSignalType.app:
        return 'App usage';
      case BreachSignalType.url:
        return 'Website';
      case BreachSignalType.payment:
        return 'Payment';
      case BreachSignalType.manual:
        return 'Manual';
    }
  }

  static BreachSignalType fromString(String value) {
    return BreachSignalType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BreachSignalType.manual,
    );
  }
}

enum CommitmentType {
  location,
  online,
  spending,
}

extension CommitmentTypeX on CommitmentType {
  String get label {
    switch (this) {
      case CommitmentType.location:
        return 'Location';
      case CommitmentType.online:
        return 'Online';
      case CommitmentType.spending:
        return 'Spending';
    }
  }

  static CommitmentType fromString(String value) {
    return CommitmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CommitmentType.online,
    );
  }
}

enum SupportMessageType {
  encouragement,
  checkIn,
  callOffer,
}

extension SupportMessageTypeX on SupportMessageType {
  String get label {
    switch (this) {
      case SupportMessageType.encouragement:
        return 'Encouragement';
      case SupportMessageType.checkIn:
        return 'Check-in';
      case SupportMessageType.callOffer:
        return 'Call offer';
    }
  }

  static SupportMessageType fromString(String value) {
    final normalized = value == 'check_in'
        ? 'checkIn'
        : value == 'call_offer'
            ? 'callOffer'
            : value;
    return SupportMessageType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => SupportMessageType.encouragement,
    );
  }
}
