import '../models/commitment.dart';

abstract class CommitmentRepository {
  Stream<List<Commitment>> watchUserCommitments(String userId);
  Future<Commitment> createCommitment(Commitment commitment);
  Future<void> updateCommitment(Commitment commitment);
  Future<void> deleteCommitment(String commitmentId);
}
