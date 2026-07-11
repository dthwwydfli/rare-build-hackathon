import 'dart:async';

import '../../domain/models/breach_event.dart';
import '../../domain/models/support_message.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/breach_repository.dart';

class MockBreachRepository implements BreachRepository {
  final _breachController = StreamController<List<BreachEvent>>.broadcast();
  final _supportController = StreamController<List<SupportMessage>>.broadcast();
  final List<BreachEvent> _breaches = [];
  final List<SupportMessage> _support = [];

  MockBreachRepository() {
    _seedCommunitySupport();
    _breachController.add(List.from(_breaches));
    _supportController.add(List.from(_support));
  }

  void _seedCommunitySupport() {
    final now = DateTime.now();
    _support.addAll([
      SupportMessage(
        id: 'support-demo-1',
        breachEventId: 'demo-check-in',
        fromUserId: 'mock-user-4',
        toUserId: 'mock-user-1',
        message:
            'You did the hard bit by naming it. Want me to stay on chat for 10?',
        type: SupportMessageType.checkIn,
        fromUserName: 'Maya Green',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      SupportMessage(
        id: 'support-demo-2',
        breachEventId: 'demo-payday',
        fromUserId: 'mock-user-2',
        toUserId: 'mock-user-1',
        message: 'Proud of you for setting the payday block. Coffee tomorrow?',
        type: SupportMessageType.encouragement,
        fromUserName: 'Sam Patel',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      SupportMessage(
        id: 'support-demo-3',
        breachEventId: 'demo-matchday',
        fromUserId: 'mock-user-3',
        toUserId: 'mock-user-1',
        message: 'Match is on later - come watch with us, phones away.',
        type: SupportMessageType.callOffer,
        fromUserName: 'Jordan Lee',
        createdAt: now.subtract(const Duration(hours: 7)),
      ),
    ]);
  }

  @override
  Stream<List<BreachEvent>> watchGroupBreaches(String groupId) async* {
    await for (final list in _breachStream()) {
      yield list.where((b) => b.groupId == groupId).toList();
    }
  }

  @override
  Stream<List<BreachEvent>> watchUserBreaches(String userId) async* {
    await for (final list in _breachStream()) {
      yield list.where((b) => b.userId == userId).toList();
    }
  }

  Stream<List<BreachEvent>> _breachStream() async* {
    yield List.from(_breaches);
    yield* _breachController.stream;
  }

  @override
  Future<BreachEvent> createBreach(BreachEvent event) async {
    final created = BreachEvent(
      id: 'breach-${_breaches.length + 1}',
      userId: event.userId,
      commitmentId: event.commitmentId,
      groupId: event.groupId,
      signalType: event.signalType,
      metadata: event.metadata,
      severity: event.severity,
      createdAt: DateTime.now(),
      flagged: event.flagged,
      acknowledged: event.acknowledged,
      userName: event.userName,
    );
    _breaches.insert(0, created);
    _breachController.add(List.from(_breaches));
    return created;
  }

  @override
  Future<void> acknowledgeBreach(String eventId) async {
    _updateBreach(
        eventId, (b) => b.copyWith(acknowledged: true, flagged: false));
  }

  @override
  Future<void> resolveBreach(String eventId) async {
    _updateBreach(eventId, (b) => b.copyWith(flagged: false));
  }

  void _updateBreach(String eventId, BreachEvent Function(BreachEvent) update) {
    final index = _breaches.indexWhere((b) => b.id == eventId);
    if (index < 0) return;
    _breaches[index] = update(_breaches[index]);
    _breachController.add(List.from(_breaches));
  }

  @override
  Future<void> sendSupport(SupportMessage message) async {
    final created = SupportMessage(
      id: 'support-${_support.length + 1}',
      breachEventId: message.breachEventId,
      fromUserId: message.fromUserId,
      toUserId: message.toUserId,
      message: message.message,
      type: message.type,
      createdAt: DateTime.now(),
      fromUserName: message.fromUserName,
    );
    _support.insert(0, created);
    _supportController.add(List.from(_support));
  }

  @override
  Stream<List<SupportMessage>> watchSupportForUser(String userId) async* {
    await for (final list in _supportStream()) {
      yield list.where((m) => m.toUserId == userId).toList();
    }
  }

  @override
  Stream<List<SupportMessage>> watchSupportForBreach(
      String breachEventId) async* {
    await for (final list in _supportStream()) {
      yield list.where((m) => m.breachEventId == breachEventId).toList();
    }
  }

  Stream<List<SupportMessage>> _supportStream() async* {
    yield List.from(_support);
    yield* _supportController.stream;
  }
}
