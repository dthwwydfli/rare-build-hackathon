import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/professional_resource.dart';

class HelpResourcesRepository {
  Future<List<ProfessionalResource>> loadResources() async {
    final raw =
        await rootBundle.loadString('assets/data/help_resources.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ProfessionalResource.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final helpResourcesRepositoryProvider =
    Provider<HelpResourcesRepository>((ref) => HelpResourcesRepository());

final helpResourcesProvider = FutureProvider<List<ProfessionalResource>>((ref) {
  return ref.watch(helpResourcesRepositoryProvider).loadResources();
});
