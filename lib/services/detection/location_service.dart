import 'physical_detector.dart';

/// Legacy wrapper — prefer [PhysicalDetector] for new code.
class LocationService {
  LocationService({PhysicalDetector? detector})
      : _detector = detector ?? PhysicalDetector();

  final PhysicalDetector _detector;

  Future<dynamic> getCurrentPosition() => _detector.getCurrentPosition();

  Future<LocationCheckResult> checkNearbyGamblingLocations({
    int radiusMeters = 200,
  }) async {
    final signal = await _detector.checkNearbyVenue(radiusMeters: radiusMeters);
    if (signal == null) {
      return const LocationCheckResult(isNearGamblingLocation: false);
    }
    final meta = signal.metadata;
    return LocationCheckResult(
      isNearGamblingLocation: true,
      nearestPoi: GamblingPoi(
        name: meta['placeName'] as String,
        lat: (meta['lat'] as num).toDouble(),
        lng: (meta['lng'] as num).toDouble(),
        type: meta['poiType'] as String? ?? 'betting_shop',
      ),
      distanceMeters: (meta['distanceM'] as num?)?.toDouble(),
    );
  }
}

class GamblingPoi {
  const GamblingPoi({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });

  final String name;
  final double lat;
  final double lng;
  final String type;
}

class LocationCheckResult {
  const LocationCheckResult({
    required this.isNearGamblingLocation,
    this.nearestPoi,
    this.distanceMeters,
  });

  final bool isNearGamblingLocation;
  final GamblingPoi? nearestPoi;
  final double? distanceMeters;
}
