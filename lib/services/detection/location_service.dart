import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

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

  factory GamblingPoi.fromJson(Map<String, dynamic> json) {
    return GamblingPoi(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] as String? ?? 'betting_shop',
    );
  }
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

class LocationService {
  List<GamblingPoi> _pois = [];
  bool _loaded = false;

  Future<void> loadPois() async {
    if (_loaded) return;
    final jsonString =
        await rootBundle.loadString('assets/data/gambling_pois.json');
    final list = json.decode(jsonString) as List<dynamic>;
    _pois = list
        .map((e) => GamblingPoi.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

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

  Future<LocationCheckResult> checkNearbyGamblingLocations({
    int radiusMeters = 200,
  }) async {
    await loadPois();
    final position = await getCurrentPosition();
    if (position == null) {
      return const LocationCheckResult(isNearGamblingLocation: false);
    }

    GamblingPoi? nearest;
    double? nearestDistance;

    for (final poi in _pois) {
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

    return LocationCheckResult(
      isNearGamblingLocation: nearest != null,
      nearestPoi: nearest,
      distanceMeters: nearestDistance,
    );
  }
}
