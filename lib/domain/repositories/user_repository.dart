import '../models/app_user.dart';

abstract class UserRepository {
  Future<List<AppUser>> searchUsers({
    required String query,
    required String excludeUserId,
    int limit = 20,
  });

  Future<AppUser?> getUser(String userId);

  Future<List<AppUser>> suggestedUsers({
    required String excludeUserId,
    int limit = 8,
  });
}
