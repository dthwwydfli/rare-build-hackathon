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
        return 'location';
      case BreachSignalType.app:
        return 'app usage';
      case BreachSignalType.url:
        return 'website';
      case BreachSignalType.payment:
        return 'payment';
      case BreachSignalType.manual:
        return 'manual';
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
        return 'location';
      case CommitmentType.online:
        return 'online';
      case CommitmentType.spending:
        return 'spending';
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
        return 'encouragement';
      case SupportMessageType.checkIn:
        return 'check-in';
      case SupportMessageType.callOffer:
        return 'call offer';
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
