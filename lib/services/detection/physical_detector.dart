import 'package:geolocator/geolocator.dart';

import '../../domain/models/enums.dart';
import 'detection_signal.dart';
import 'gambling_catalog.dart';

/// Tracks physical visits to betting shops, casinos, and arcades via GPS.
class PhysicalDetector {
  PhysicalDetector({GamblingCatalog? catalog})
      : _catalog = catalog ?? GamblingCatalog.instance;

  final GamblingCatalog _catalog;

  Future<void> initialize() => _catalog.load();

  Future<Position?> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Returns a signal if the user is within [radiusMeters] of a known POI.
  Future<DetectionSignal?> checkNearbyVenue({int radiusMeters = 200}) async {
    await initialize();
    final position = await getCurrentPosition();
    if (position == null) return null;

    GamblingPoiEntry? nearest;
    double? nearestDistance;

    for (final poi in _catalog.pois) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        poi.lat,
        poi.lng,
      );
      if (distance <= radiusMeters &&
          (nearestDistance == null || distance < nearestDistance)) {
        nearest = poi;
        nearestDistance = distance;
      }
    }

    if (nearest == null) return null;

    return DetectionSignal(
      channel: DetectionChannel.physical,
      signalType: BreachSignalType.location,
      metadata: {
        'placeName': nearest.name,
        'lat': nearest.lat,
        'lng': nearest.lng,
        'distanceM': nearestDistance,
        'poiType': nearest.type,
      },
    );
  }
}
