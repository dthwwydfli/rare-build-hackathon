import '../models/access_block_settings.dart';

abstract class AccessBlockRepository {
  Stream<AccessBlockSettings> watchSettings(String userId);
  Future<AccessBlockSettings> saveSettings(AccessBlockSettings settings);
}
