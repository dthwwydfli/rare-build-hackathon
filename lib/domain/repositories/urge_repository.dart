import '../models/urge_log.dart';

abstract class UrgeRepository {
  Stream<List<UrgeLog>> watchUserUrges(String userId);
  Future<UrgeLog> createUrge(UrgeLog urge);
}
