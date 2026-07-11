import '../../domain/models/enums.dart';

/// A single detection hit before it becomes a breach event.
class DetectionSignal {
  const DetectionSignal({
    required this.channel,
    required this.signalType,
    required this.metadata,
    this.severity = 'medium',
  });

  final DetectionChannel channel;
  final BreachSignalType signalType;
  final Map<String, dynamic> metadata;
  final String severity;
}

enum DetectionChannel {
  physical,
  appLogin,
  websiteVisit,
  payment,
}

extension DetectionChannelX on DetectionChannel {
  String get label {
    switch (this) {
      case DetectionChannel.physical:
        return 'Physical location';
      case DetectionChannel.appLogin:
        return 'App login';
      case DetectionChannel.websiteVisit:
        return 'Website visit';
      case DetectionChannel.payment:
        return 'Payment';
    }
  }
}
