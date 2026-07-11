import 'dart:convert';

import 'package:flutter/services.dart';

/// Central blocklist loaded from bundled JSON assets.
class GamblingCatalog {
  GamblingCatalog._();

  static final GamblingCatalog instance = GamblingCatalog._();

  List<GamblingAppEntry> _apps = [];
  List<GamblingDomainEntry> _domains = [];
  List<GamblingPoiEntry> _pois = [];
  bool _loaded = false;

  List<GamblingAppEntry> get apps => List.unmodifiable(_apps);
  List<GamblingDomainEntry> get domains => List.unmodifiable(_domains);
  List<GamblingPoiEntry> get pois => List.unmodifiable(_pois);

  List<String> get packageNames =>
      _apps.map((a) => a.packageName).toList(growable: false);

  List<String> get domainStrings =>
      _domains.map((d) => d.domain).toList(growable: false);

  Future<void> load() async {
    if (_loaded) return;

    final appsJson =
        await rootBundle.loadString('assets/data/gambling_apps.json');
    final domainsJson =
        await rootBundle.loadString('assets/data/gambling_domains.json');
    final poisJson =
        await rootBundle.loadString('assets/data/gambling_pois.json');

    _apps = (json.decode(appsJson) as List<dynamic>)
        .map((e) => GamblingAppEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _domains = (json.decode(domainsJson) as List<dynamic>)
        .map((e) => GamblingDomainEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _pois = (json.decode(poisJson) as List<dynamic>)
        .map((e) => GamblingPoiEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  bool matchesApp({
    required String packageName,
    required String appName,
    List<String> customBlocklist = const [],
  }) {
    final targets = customBlocklist.isNotEmpty
        ? customBlocklist
        : [...packageNames, ..._apps.map((a) => a.displayName)];
    final lowerPackage = packageName.toLowerCase();
    final lowerApp = appName.toLowerCase();
    for (final target in targets) {
      final t = target.toLowerCase();
      if (lowerPackage.contains(t) || lowerApp.contains(t)) return true;
    }
    return false;
  }

  bool matchesDomain(String url, {List<String> customBlocklist = const []}) {
    final lower = url.toLowerCase();
    final targets =
        customBlocklist.isNotEmpty ? customBlocklist : domainStrings;
    return targets.any((d) => lower.contains(d.toLowerCase()));
  }

  GamblingDomainEntry? findDomain(String url) {
    final lower = url.toLowerCase();
    for (final entry in _domains) {
      if (lower.contains(entry.domain.toLowerCase())) return entry;
    }
    return null;
  }

  GamblingAppEntry? findApp(String packageName) {
    for (final entry in _apps) {
      if (entry.packageName == packageName) return entry;
    }
    return null;
  }
}

class GamblingAppEntry {
  const GamblingAppEntry({
    required this.packageName,
    required this.displayName,
  });

  final String packageName;
  final String displayName;

  factory GamblingAppEntry.fromJson(Map<String, dynamic> json) {
    return GamblingAppEntry(
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
    );
  }
}

class GamblingDomainEntry {
  const GamblingDomainEntry({
    required this.domain,
    required this.displayName,
  });

  final String domain;
  final String displayName;

  factory GamblingDomainEntry.fromJson(Map<String, dynamic> json) {
    return GamblingDomainEntry(
      domain: json['domain'] as String,
      displayName: json['displayName'] as String,
    );
  }
}

class GamblingPoiEntry {
  const GamblingPoiEntry({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });

  final String name;
  final double lat;
  final double lng;
  final String type;

  factory GamblingPoiEntry.fromJson(Map<String, dynamic> json) {
    return GamblingPoiEntry(
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      type: json['type'] as String? ?? 'betting_shop',
    );
  }
}
