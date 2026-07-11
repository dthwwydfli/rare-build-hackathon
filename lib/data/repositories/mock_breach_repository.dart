import 'dart:async';

import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/support_message.dart';
import '../../domain/repositories/breach_repository.dart';

class MockBreachRepository implements BreachRepository {
  final _breachController = StreamController<List<BreachEvent>>.broadcast();
  final _supportController = StreamController<List<SupportMessage>>.broadcast();
  final List<BreachEvent> _breaches = [];
  final List<SupportMessage> _support = [];

  MockBreachRepository() {
    _breachController.add([]);
    _supportController.add([]);
  }

  @override
  Stream<List<BreachEvent>> watchGroupBreaches(String groupId) {
    return _breachController.stream.map(
      (list) => list.where((b) => b.groupId == groupId).toList(),
    );
  }

  @override
  Stream<List<BreachEvent>> watchUserBreaches(String userId) {
    return _breachController.stream.map(
      (list) => list.where((b) => b.userId == userId).toList(),
    );
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
      userName: event.userName,
    );
    _breaches.insert(0, created);
    _breachController.add(List.from(_breaches));
    return created;
  }

  @override
  Future<void> acknowledgeBreach(String eventId) async {
    final index = _breaches.indexWhere((b) => b.id == eventId);
    if (index < 0) return;
    final b = _breaches[index];
    _breaches[index] = BreachEvent(
      id: b.id,
      userId: b.userId,
      commitmentId: b.commitmentId,
      groupId: b.groupId,
      signalType: b.signalType,
      metadata: b.metadata,
      severity: b.severity,
      createdAt: b.createdAt,
      acknowledged: true,
      userName: b.userName,
    );
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
  Stream<List<SupportMessage>> watchSupportForUser(String userId) {
    return _supportController.stream.map(
      (list) => list.where((m) => m.toUserId == userId).toList(),
    );
  }
}
