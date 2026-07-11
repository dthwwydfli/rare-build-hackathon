import 'dart:async';

import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/commitment_repository.dart';

class MockCommitmentRepository implements CommitmentRepository {
  final _controller = StreamController<List<Commitment>>.broadcast();
  final List<Commitment> _commitments = [];

  MockCommitmentRepository() {
    _controller.add([]);
  }

  @override
  Stream<List<Commitment>> watchUserCommitments(String userId) {
    return _controller.stream.map(
      (list) => list.where((c) => c.userId == userId).toList(),
    );
  }

  @override
  Future<Commitment> createCommitment(Commitment commitment) async {
    final created = Commitment(
      id: 'mock-${_commitments.length + 1}',
      userId: commitment.userId,
      title: commitment.title,
      type: commitment.type,
      rules: commitment.rules,
      active: commitment.active,
      createdAt: DateTime.now(),
    );
    _commitments.add(created);
    _controller.add(List.from(_commitments));
    return created;
  }

  @override
  Future<void> updateCommitment(Commitment commitment) async {
    final index = _commitments.indexWhere((c) => c.id == commitment.id);
    if (index >= 0) {
      _commitments[index] = commitment;
      _controller.add(List.from(_commitments));
    }
  }

  @override
  Future<void> deleteCommitment(String commitmentId) async {
    _commitments.removeWhere((c) => c.id == commitmentId);
    _controller.add(List.from(_commitments));
  }
}
