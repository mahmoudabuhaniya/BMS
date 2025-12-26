import 'package:hive_flutter/hive_flutter.dart';

class DropdownCache {
  static const _boxName = 'dropdowns';

  static Box get _box => Hive.box(_boxName);

  static Future<void> saveIpNames(List<String> ipNames) async {
    await _box.put('ip_names', ipNames);
  }

  static Future<void> saveSectors(List<String> sectors) async {
    await _box.put('sectors', sectors);
  }

  static Future<List<String>> getIpNames() async {
    final list = _box.get('ip_names');
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Future<List<String>> getSectors() async {
    final list = _box.get('sectors');
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }
}
