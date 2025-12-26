import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';

class DropdownLoader {
  static const cacheBoxName = 'dropdown_cache';

  final ApiService _api;

  DropdownLoader({ApiService? api}) : _api = api ?? ApiService();

  Future<Map<String, List<String>>> loadIpNamesAndSectors() async {
    final box = Hive.box(cacheBoxName);

    List<String> ipNames =
        List<String>.from(box.get('ip_names', defaultValue: <String>[]));
    List<String> sectors =
        List<String>.from(box.get('sectors', defaultValue: <String>[]));

    bool updated = false;

    // Try to refresh from API (if fails, keep cache)
    try {
      final freshIp = await _api.fetchDistinctIpNames();
      if (freshIp.isNotEmpty) {
        ipNames = freshIp;
        updated = true;
      }

      final freshSectors = await _api.fetchDistinctSectors();
      if (freshSectors.isNotEmpty) {
        sectors = freshSectors;
        updated = true;
      }
    } catch (_) {
      // network or auth error → keep cached values
    }

    if (updated) {
      await box.put('ip_names', ipNames);
      await box.put('sectors', sectors);
    }

    return {
      'ip_names': ipNames,
      'sectors': sectors,
    };
  }
}
