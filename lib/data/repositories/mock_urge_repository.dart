import 'dart:async';

import '../../domain/models/urge_log.dart';
import '../../domain/repositories/urge_repository.dart';

class MockUrgeRepository implements UrgeRepository {
  final _controller = StreamController<List<UrgeLog>>.broadcast();
  final List<UrgeLog> _urges = [];

  MockUrgeRepository() {
    _controller.add([]);
  }

  @override
  Stream<List<UrgeLog>> watchUserUrges(String userId) async* {
    await for (final list in _urgeStream()) {
      yield list.where((u) => u.userId == userId).toList();
    }
  }

  Stream<List<UrgeLog>> _urgeStream() async* {
    yield List.from(_urges);
    yield* _controller.stream;
  }

  @override
  Future<UrgeLog> createUrge(UrgeLog urge) async {
    final created = UrgeLog(
      id: 'urge-${_urges.length + 1}',
      userId: urge.userId,
      createdAt: DateTime.now(),
      intensity: urge.intensity,
      mood: urge.mood,
      trigger: urge.trigger,
      location: urge.location,
      moneyOnHand: urge.moneyOnHand,
      resisted: urge.resisted,
      notes: urge.notes,
    );
    _urges.insert(0, created);
    _controller.add(List.from(_urges));
    return created;
  }
}
