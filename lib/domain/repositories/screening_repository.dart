import '../models/screening_result.dart';

abstract class ScreeningRepository {
  Future<ScreeningStatus> getStatus(String userId);
  Stream<ScreeningStatus> watchStatus(String userId);
  Future<ScreeningResult> saveResult(ScreeningResult result);
  Future<ScreeningResult?> getLatestResult(String userId);
}
