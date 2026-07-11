import '../models/breach_event.dart';
import '../models/support_message.dart';

abstract class BreachRepository {
  Stream<List<BreachEvent>> watchGroupBreaches(String groupId);
  Stream<List<BreachEvent>> watchUserBreaches(String userId);
  Future<BreachEvent> createBreach(BreachEvent event);
  Future<void> acknowledgeBreach(String eventId);
  Future<void> sendSupport(SupportMessage message);
  Stream<List<SupportMessage>> watchSupportForUser(String userId);
}
