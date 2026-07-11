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

  String get description {
    switch (this) {
      case CommitmentType.location:
        return 'alert when you\'re near betting venues';
      case CommitmentType.online:
        return 'block gambling apps and websites';
      case CommitmentType.spending:
        return 'get warned before you overspend';
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

enum UrgeMood {
  calm,
  bored,
  stressed,
  lonely,
  excited,
  angry,
  sad,
  neutral,
}

extension UrgeMoodX on UrgeMood {
  String get label {
    switch (this) {
      case UrgeMood.calm:
        return 'Calm';
      case UrgeMood.bored:
        return 'Bored';
      case UrgeMood.stressed:
        return 'Stressed';
      case UrgeMood.lonely:
        return 'Lonely';
      case UrgeMood.excited:
        return 'Excited';
      case UrgeMood.angry:
        return 'Angry';
      case UrgeMood.sad:
        return 'Sad';
      case UrgeMood.neutral:
        return 'Neutral';
    }
  }

  static UrgeMood fromString(String value) {
    return UrgeMood.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UrgeMood.neutral,
    );
  }
}

enum UrgeTrigger {
  payday,
  sportsEvent,
  advert,
  nearVenue,
  aloneAtHome,
  afterDrink,
  boredom,
  chasingLosses,
  other,
}

extension UrgeTriggerX on UrgeTrigger {
  String get label {
    switch (this) {
      case UrgeTrigger.payday:
        return 'Payday';
      case UrgeTrigger.sportsEvent:
        return 'Sports on TV';
      case UrgeTrigger.advert:
        return 'Gambling advert';
      case UrgeTrigger.nearVenue:
        return 'Near betting shop';
      case UrgeTrigger.aloneAtHome:
        return 'Alone at home';
      case UrgeTrigger.afterDrink:
        return 'After drinking';
      case UrgeTrigger.boredom:
        return 'Boredom';
      case UrgeTrigger.chasingLosses:
        return 'Chasing losses';
      case UrgeTrigger.other:
        return 'Other';
    }
  }

  static UrgeTrigger fromString(String value) {
    return UrgeTrigger.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UrgeTrigger.other,
    );
  }
}
